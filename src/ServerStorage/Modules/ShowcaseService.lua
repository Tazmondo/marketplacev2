local ShowcaseService = {}

local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local DataService = require(script.Parent.DataService)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)
local UpdateShowcaseEventTypes = require(ReplicatedStorage.Events.Showcase.ClientFired.UpdateShowcaseEvent)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local UpdateShowcaseEvent = UpdateShowcaseEventTypes:Server()
local UpdateVisiblePlayersEvent =
	require(ReplicatedStorage.Events.Showcase.ServerFired.UpdateVisiblePlayersEvent):Server()
local EditShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.EditShowcaseEvent):Server()
local CreateShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.CreateShowcaseEvent):Server()
local LoadShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ServerFired.LoadShowcaseEvent):Server()
local DeleteShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.DeleteShowcaseEvent):Server()

type Showcase = {
	stands: { Types.Stand },
	validPositions: { [Vector3]: true },
	playersPresent: { [Player]: true },
	owner: number, -- UserId since owner doesn't have to be in the server
	mode: Types.ShowcaseMode,

	-- Since updating is an asynchronous operation, we don't want old updates to override new ones
	lastUpdate: number,

	name: string,
	primaryColor: Color3,
	accentColor: Color3,
	GUID: string,
	thumbId: number,
}

local placeTemplate = ReplicatedStorage.Assets.Layouts.ShopTemplate :: Model
assert(placeTemplate, "No place template found")

local placeTable: { Showcase } = {}

local playerShowcases: { [Player]: Showcase } = {}

-- Don't instance it at run-time as it can cause a race condition on client where sometimes it will find and sometimes it wont
local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Expected ReplicatedStorage.AccessoryReplication folder.")

local validPositions: { [Vector3]: true } = {}
for i, descendant in placeTemplate:GetDescendants() do
	if descendant:IsA("BasePart") and descendant:HasTag(Config.StandTag) then
		local roundedPosition = Util.RoundedVector(placeTemplate:GetPivot():PointToObjectSpace(descendant.Position))
		validPositions[roundedPosition] = true
	end
end

function ReplicateAsset(assetId: number)
	return Future.new(function()
		if not accessoryReplication:FindFirstChild(tostring(assetId)) then
			local asset = InsertService:LoadAsset(assetId)
			asset.Name = tostring(assetId)

			-- Since fetching is async, this could get called twice, but we don't want unnecessary duplicates.
			if not accessoryReplication:FindFirstChild(tostring(assetId)) then
				asset.Parent = accessoryReplication
				return true
			end
		end
		return false
	end)
end

function ToNetworkShowcase(showcase: Showcase): Types.NetworkShowcase
	return {
		stands = showcase.stands,
		mode = showcase.mode,
		owner = showcase.owner,
		name = showcase.name,
		GUID = showcase.GUID,
		primaryColor = showcase.primaryColor,
		accentColor = showcase.accentColor,
		thumbId = showcase.thumbId,
	}
end

function ShowcaseService:ExitPlayerShowcase(player: Player, showcase: Showcase)
	showcase.playersPresent[player] = nil

	if next(showcase.playersPresent) == nil then
		-- Empty
		ShowcaseService:UnloadPlace(showcase)
		return
	end

	local visiblePlayers = {}
	for player, _ in showcase.playersPresent do
		table.insert(visiblePlayers, player)
	end
	UpdateVisiblePlayersEvent:FireList(visiblePlayers, visiblePlayers)
end

function ShowcaseService:EnterPlayerShowcase(player: Player, showcase: Showcase)
	local oldPlace = playerShowcases[player]
	if oldPlace then
		ShowcaseService:ExitPlayerShowcase(player, oldPlace)
	end

	showcase.playersPresent[player] = true
	playerShowcases[player] = showcase

	LoadShowcaseEvent:Fire(player, ToNetworkShowcase(showcase))

	local visiblePlayers = {}
	for player, _ in showcase.playersPresent do
		table.insert(visiblePlayers, player)
	end
	UpdateVisiblePlayersEvent:FireList(visiblePlayers, visiblePlayers)
end

function SaveShowcase(showcase: Showcase)
	local owner = Players:GetPlayerByUserId(showcase.owner)
	if not owner then
		warn("Tried to save showcase for player not in-game")
		return
	end

	if showcase.mode ~= "Edit" then
		warn("Tried to save showcase when not in edit mode.")
		return
	end

	local data = DataService:ReadData(owner):Await()
	if not data then
		return
	end

	local showcaseIndex
	for i, v in data.showcases do
		if v.GUID == showcase.GUID then
			showcaseIndex = i
		end
	end

	if not showcaseIndex then
		warn("Could not find owned showcase")
		return
	end

	local stands: { Data.Stand } = {}

	for part, stand in showcase.stands do
		if stand.assetId then
			table.insert(stands, {
				assetId = stand.assetId,
				roundedPosition = Data.VectorToTable(stand.roundedPosition),
			})
		end
	end

	local newShowcase: Data.Showcase = {
		stands = stands,
		GUID = showcase.GUID,
		name = showcase.name,
		primaryColor = showcase.primaryColor:ToHex(),
		accentColor = showcase.accentColor:ToHex(),
		thumbId = showcase.thumbId,
	}

	DataService:WriteData(owner, function(data)
		data.showcases[showcaseIndex] = newShowcase
	end)
end

function ShowcaseService:GetShowcase(showcase: Types.Showcase, mode: Types.ShowcaseMode)
	return Future.new(function()
		-- Check for already existing showcase with the same GUID
		for i, place in placeTable do
			if place.GUID == showcase.GUID and place.mode == "View" then
				return place
			end
		end

		local standMap: { [Vector3]: Types.Stand } = {}
		for i, stand in showcase.stands do
			standMap[stand.roundedPosition] = stand
		end

		-- Every physical part should have a registered stand
		-- This is necessary so the showcase can accept stand updates for stands that don't yet have an item.
		local stands: { Types.Stand } = {}
		for position, _ in validPositions do
			local stand = standMap[position]
			if stand then
				table.insert(stands, stand)
				if stand.assetId then
					ReplicateAsset(stand.assetId)
				end
			else
				table.insert(stands, {
					assetId = nil,
					roundedPosition = position,
				})
			end
		end

		local place: Showcase = {
			stands = stands,
			validPositions = validPositions,
			owner = showcase.owner,
			playersPresent = {},
			mode = mode,
			GUID = showcase.GUID,
			name = showcase.name,
			primaryColor = showcase.primaryColor,
			accentColor = showcase.accentColor,
			lastUpdate = os.clock(),
			thumbId = showcase.thumbId,
		}

		table.insert(placeTable, place)

		return place
	end)
end

function ShowcaseService:UnloadPlace(place: Showcase)
	if next(place.playersPresent) ~= nil then
		warn("Unloaded a place while players were still inside it!")
	end

	local index = table.find(placeTable, place)
	if index then
		table.remove(placeTable, index)
	else
		warn(debug.traceback("Tried to unload a place with the wrong index! Should never occur."))
	end
end

function HandleCreatePlace(player: Player)
	local data = DataService:ReadData(player):Await()
	if not data then
		return
	end

	if #data.showcases >= Config.MaxPlaces then
		return
	end

	local newShowcase: Types.Showcase = {
		name = `{player.Name}'s Shop`,
		stands = {},
		GUID = HttpService:GenerateGUID(false),
		owner = player.UserId,
		primaryColor = Config.DefaultPrimaryColor,
		accentColor = Config.DefaultAccentColor,
		thumbId = Config.DefaultShopThumbnail,
	}

	DataService:WriteData(player, function(data)
		table.insert(data.showcases, Data.ToDataShowcase(newShowcase))
	end)
end

function HandleEditShowcase(player: Player, GUID: string)
	local data = DataService:ReadData(player):Await()
	if not data then
		return
	end

	local chosenShowcase
	for i, showcase in data.showcases do
		if showcase.GUID == GUID then
			chosenShowcase = Data.FromDataShowcase(showcase, player.UserId)
			break
		end
	end

	if not chosenShowcase then
		return
	end

	local place = ShowcaseService:GetShowcase(chosenShowcase, "Edit"):Await()
	ShowcaseService:EnterPlayerShowcase(player, place)
end

function HandleUpdateShowcase(player: Player, update: UpdateShowcaseEventTypes.Update)
	local showcase = playerShowcases[player]
	if not showcase then
		warn(player, "Tried to update a showcase without being present in it.")
		return
	end

	local updateTime = os.clock()
	showcase.lastUpdate = updateTime

	if showcase.mode ~= "Edit" then
		warn(player, "Tried to update a showcase that was not in edit mode.")
		return
	end

	if update.type == "UpdateStand" then
		if not validPositions[update.roundedPosition] then
			warn("Updated with an invalid position:", update.roundedPosition)
			return
		end

		local stand = TableUtil.Find(showcase.stands, function(stand)
			return stand.roundedPosition == update.roundedPosition
		end)

		if not stand then
			warn("Could not find stand when updating:", update.roundedPosition)
			return
		end

		if stand.assetId == update.assetId then
			-- Asset did not change
			return
		end

		stand.assetId = update.assetId
		if update.assetId then
			ReplicateAsset(update.assetId)
		end
	elseif update.type == "UpdateSettings" then
		local primaryColorExists = Config.PrimaryColors[update.primaryColor:ToHex()]
		if not primaryColorExists then
			warn("Invalid primary color sent:", update.primaryColor)
			return
		end

		local accentColorExists = Config.AccentColors[update.accentColor:ToHex()]
		if not accentColorExists then
			warn("Invalid accent color sent:", update.accentColor)
			return
		end

		if showcase.name ~= update.name then
			-- Yields
			local success, result = pcall(function()
				return TextService:FilterStringAsync(
					update.name,
					player.UserId,
					Enum.TextFilterContext.PublicChat
				) :: TextFilterResult
			end)

			if not success then
				-- Unable to filter, assume it's bad
				-- This should really never happen
				warn("TextService filter was unsuccessful!")
				return
			end

			-- Yields
			local filteredName = result:GetNonChatStringForBroadcastAsync()

			-- Eliminates race conditions caused by updating name quickly
			if showcase.lastUpdate ~= updateTime then
				return
			end

			showcase.name = Util.LimitString(filteredName, Config.MaxPlaceNameLength)
		end

		showcase.primaryColor = update.primaryColor
		showcase.accentColor = update.accentColor
		showcase.thumbId = update.thumbId
	end

	LoadShowcaseEvent:Fire(player, ToNetworkShowcase(showcase))
	SaveShowcase(showcase)
end

function HandleDeleteShowcase(player: Player, guid: string)
	DataService:WriteData(player, function(data)
		for i, showcase in data.showcases do
			if showcase.GUID == guid then
				table.remove(data.showcases, i)
				return
			end
		end

		warn("Tried to delete a non-existent showcase")
	end)
end

function PlayerRemoving(player: Player)
	local currentPlace = playerShowcases[player]
	if currentPlace then
		playerShowcases[player] = nil
		ShowcaseService:ExitPlayerShowcase(player, currentPlace)
	end
end

function ShowcaseService:Initialize()
	CreateShowcaseEvent:On(HandleCreatePlace)
	EditShowcaseEvent:On(HandleEditShowcase)
	UpdateShowcaseEvent:On(HandleUpdateShowcase)
	DeleteShowcaseEvent:On(HandleDeleteShowcase)

	Players.PlayerRemoving:Connect(PlayerRemoving)
end

ShowcaseService:Initialize()

return ShowcaseService

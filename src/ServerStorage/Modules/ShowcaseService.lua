local ShowcaseService = {}

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local DataService = require(script.Parent.DataService)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)
local UpdateShowcaseEventTypes = require(ReplicatedStorage.Events.Showcase.ClientFired.UpdateShowcaseEvent)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local Material = require(ReplicatedStorage.Modules.Shared.Material)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local UpdateShowcaseEvent = UpdateShowcaseEventTypes:Server()
local UpdateVisiblePlayersEvent =
	require(ReplicatedStorage.Events.Showcase.ServerFired.UpdateVisiblePlayersEvent):Server()
local EditShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.EditShowcaseEvent):Server()
local CreateShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.CreateShowcaseEvent):Server()
local LoadShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ServerFired.LoadShowcaseEvent):Server()
local DeleteShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.DeleteShowcaseEvent):Server()
local PurchaseAssetEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.PurchaseAssetEvent):Server()

type ActiveShowcase = {
	stands: { Types.Stand },
	playersPresent: { [Player]: true },
	owner: number, -- UserId since owner doesn't have to be in the server
	mode: Types.ShowcaseMode,

	-- Since updating is an asynchronous operation, we don't want old updates to override new ones
	lastUpdate: number,

	name: string,
	layout: Layouts.Layout,
	primaryColor: Color3,
	accentColor: Color3,
	texture: string,
	logoId: number?,
	GUID: string,
	thumbId: number,
}

local placeTable: { ActiveShowcase } = {}

local playerShowcases: { [Player]: ActiveShowcase? } = {}

-- Don't instance it at run-time as it can cause a race condition on client where sometimes it will find and sometimes it wont
local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Expected ReplicatedStorage.AccessoryReplication folder.")

-- Specialmeshes do not support a way to get their size.
-- MeshParts do.
-- When using Players:CreateHumanoidModelFromDescription with R15 rigs, it generates accessories using MeshParts
-- So we can use this to generate a MeshPart and normalize its size.
function ReplicateAsset(assetId: number)
	return Future.new(function()
		if not accessoryReplication:FindFirstChild(tostring(assetId)) then
			local description = Instance.new("HumanoidDescription")
			description.FaceAccessory = tostring(assetId)

			local playerModel = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)

			if accessoryReplication:FindFirstChild(tostring(assetId)) then
				-- Already found while this was yielding
				return
			end

			local accessory = playerModel:FindFirstChildOfClass("Accessory")
			if not accessory then
				warn(`Failed to fetch accessory for {assetId}`)
				return
			end
			local meshPart = accessory:FindFirstChildOfClass("MeshPart")
			if not meshPart then
				warn(`Accessory generated without meshpart {assetId}`)
				return
			end

			-- Rotation offset of the model from the player
			-- This allows us to set the pivot so the orientation when CFraming is the same as if it was attached to a player
			-- I.e. the front of the model faces forwards.
			-- Need to parent to workspace too otherwise it doesn't return the correct value
			-- Parenting to the camera means they won't get replicated to the client unnecessarily too.
			playerModel.Parent = workspace.CurrentCamera
			local pivot = playerModel:GetPivot():ToObjectSpace(meshPart.CFrame).Rotation:Inverse()
			meshPart.PivotOffset = pivot

			local model = Instance.new("Model")
			meshPart.Parent = model
			model.PrimaryPart = meshPart
			model.Name = tostring(assetId)

			playerModel:Destroy()

			local vectorSize = meshPart.Size
			local maxSize = math.max(vectorSize.X, vectorSize.Y, vectorSize.Z)

			-- Scale meshpart so it fits within a 1x1x1 cube
			local scale = 1 / maxSize

			local wrapLayer = meshPart:FindFirstChildOfClass("WrapLayer")
			if wrapLayer then
				wrapLayer:Destroy()
			end

			model:ScaleTo(scale)
			model.Parent = accessoryReplication
			return true

			-- This is the old code for fetching models through InsertService
			-- It wasn't suitable because there was no way to get consistent sizing for the items.

			-- local asset = InsertService:LoadAsset(assetId)
			-- asset.Name = tostring(assetId)

			-- -- Since fetching is async, this could get called twice, but we don't want unnecessary duplicates.
			-- if not accessoryReplication:FindFirstChild(tostring(assetId)) then
			-- 	asset.Parent = accessoryReplication
			-- 	return true
			-- end
		end
		return false
	end)
end

function ToNetworkShowcase(showcase: ActiveShowcase): Types.NetworkShowcase
	return {
		stands = showcase.stands,
		layoutId = showcase.layout.id,
		mode = showcase.mode,
		owner = showcase.owner,
		name = showcase.name,
		GUID = showcase.GUID,
		primaryColor = showcase.primaryColor,
		accentColor = showcase.accentColor,
		texture = showcase.texture,
		thumbId = showcase.thumbId,
		logoId = showcase.logoId,
	}
end

function ShowcaseService:ExitPlayerShowcase(player: Player, showcase: ActiveShowcase)
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

function ShowcaseService:EnterPlayerShowcase(player: Player, showcase: ActiveShowcase)
	local oldPlace = playerShowcases[player]

	-- Need to check GUIDs are different otherwise it will try and delete the old place.
	if oldPlace and oldPlace.GUID ~= showcase.GUID then
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

function ShowcaseService:GetShowcaseOfPlayer(player: Player): ActiveShowcase?
	local showcase = playerShowcases[player]
	return showcase
end

function SaveShowcase(showcase: ActiveShowcase)
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

	-- Filter out stands that are invalid or lack an asset id
	-- Invalid stands can be caused when switching layouts - the old stands may not have valid positions anymore.
	local filteredStands: { Data.Stand } = {}
	local validPositions = showcase.layout.getValidStandPositions()

	for part, stand in showcase.stands do
		if stand.assetId and validPositions[stand.roundedPosition] then
			table.insert(filteredStands, {
				assetId = stand.assetId,
				roundedPosition = Data.VectorToTable(stand.roundedPosition),
			})
		end
	end

	local newShowcase: Data.Showcase = {
		stands = filteredStands,
		layoutId = showcase.layout.id,
		GUID = showcase.GUID,
		name = showcase.name,
		primaryColor = showcase.primaryColor:ToHex(),
		accentColor = showcase.accentColor:ToHex(),
		texture = showcase.texture,
		thumbId = showcase.thumbId,
		logoId = showcase.logoId,
	}

	DataService:WriteData(owner, function(data)
		data.showcases[showcaseIndex] = newShowcase
	end)
end

function PopulateLayoutStands(savedStands: { Types.Stand }, standPositions: { [Vector3]: boolean }): { Types.Stand }
	local savedStandMap: { [Vector3]: Types.Stand } = {}
	for i, stand in savedStands do
		savedStandMap[stand.roundedPosition] = stand
	end

	local outputStands = {}

	for position, _ in standPositions do
		local stand = savedStandMap[position]
		if stand then
			table.insert(outputStands, stand)
			if stand.assetId then
				ReplicateAsset(stand.assetId)
			end
		else
			table.insert(outputStands, {
				assetId = nil,
				roundedPosition = position,
			})
		end
	end

	return outputStands
end

function ShowcaseService:GetShowcase(showcase: Types.Showcase, mode: Types.ShowcaseMode)
	-- Check for already existing showcase with the same GUID, but only for viewing. Showcases in edit mode should
	-- Be kept entirely separate because the mode is stored within the showcase data itself, and not on a per-player basis.
	for i, place in placeTable do
		if place.GUID == showcase.GUID and mode == "View" and place.mode == "View" then
			return place
		end
	end

	local layout = Layouts:GetLayout(showcase.layoutId)

	-- Every physical part should have a registered stand
	-- This is necessary so the showcase can accept stand updates for stands that don't yet have an item.
	local stands = PopulateLayoutStands(showcase.stands, layout.getValidStandPositions())

	local place: ActiveShowcase = {
		stands = stands,
		layout = layout,
		owner = showcase.owner,
		playersPresent = {},
		mode = mode,
		GUID = showcase.GUID,
		name = showcase.name,
		primaryColor = showcase.primaryColor,
		accentColor = showcase.accentColor,
		texture = showcase.texture,
		lastUpdate = os.clock(),
		thumbId = showcase.thumbId,
		logoId = showcase.logoId,
	}

	table.insert(placeTable, place)

	return place
end

function ShowcaseService:UnloadPlace(place: ActiveShowcase)
	if next(place.playersPresent) ~= nil then
		warn("Unloaded a place while players were still inside it!")
	end

	local index = table.find(placeTable, place)
	if index then
		table.remove(placeTable, index)
	else
		warn(debug.traceback("Tried to unload a place without it existing in the place table! Should never occur."))
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
		layoutId = Layouts:GetDefaultLayoutId(),
		stands = {},
		GUID = HttpService:GenerateGUID(false),
		owner = player.UserId,
		primaryColor = Config.DefaultPrimaryColor,
		accentColor = Config.DefaultAccentColor,
		texture = Material:GetDefault(),
		thumbId = Config.DefaultShopThumbnail,
		logoId = nil,
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

	local place = ShowcaseService:GetShowcase(chosenShowcase, "Edit")
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
		if not showcase.layout.getValidStandPositions()[update.roundedPosition] then
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

		local textureExists = Material:TextureExists(update.texture)
		if not textureExists then
			warn("Invalid texture sent:", update.texture)
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
		showcase.logoId = update.logoId
		showcase.texture = update.texture
	elseif update.type == "UpdateLayout" then
		local newLayout = Layouts:GetLayout(update.layoutId)
		showcase.layout = newLayout
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

function HandlePurchaseAsset(player: Player, assetId: number)
	-- When we get exclusive deals we will need to secure this so users can't buy the exclusive assets.
	MarketplaceService:PromptPurchase(player, assetId)
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
	PurchaseAssetEvent:On(HandlePurchaseAsset)

	Players.PlayerRemoving:Connect(PlayerRemoving)
end

ShowcaseService:Initialize()

return ShowcaseService

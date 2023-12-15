local ShowcaseService = {}

local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local DataService = require(script.Parent.DataService)
local ItemDetails = require(script.Parent.ItemDetails)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)

local UpdateShowcaseEventTypes = require(ReplicatedStorage.Events.Showcase.ClientFired.UpdateShowcaseEvent)
local UpdateShowcaseEvent = UpdateShowcaseEventTypes:Server()
local EditShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.EditShowcaseEvent):Server()
local CreateShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.CreateShowcaseEvent):Server()
local EnterShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ServerFired.EnterShowcaseEvent):Server()

type ShowcaseStand = {
	assetId: number?,
	roundedPosition: Vector3,
	part: BasePart,
}

type Showcase = {
	CFrame: CFrame,
	model: Model,
	entranceCFrame: CFrame,
	stands: { [BasePart]: ShowcaseStand },
	playersPresent: { [Player]: true },
	owner: number, -- UserId since owner doesn't have to be in the server
	tableIndex: number,
	mode: Types.ShowcaseMode,
	GUID: string,
	name: string,
}

local template = ServerStorage:FindFirstChild("PlaceTemplate") :: Model?
assert(template, "Template did not exist")
assert(template:IsA("Model"), "Template was not a model")

local maxX = 600
local maxY = 250
local maxZ = maxX

local extentsCFrame, extents = template:GetBoundingBox()
local templateExtents = extentsCFrame:VectorToWorldSpace(extents)

local absoluteExtents =
	Vector3.new(math.abs(templateExtents.X), math.abs(templateExtents.Y), math.abs(templateExtents.Z))

assert(absoluteExtents.X <= maxX, "Template X was too large")
assert(absoluteExtents.Y <= maxY, "Template Y was too large")
assert(absoluteExtents.Z <= maxZ, "Template Z was too large")

local placeSlots = Vector3.new(10, 1, 10)
local maxPlaces = placeSlots.X * placeSlots.Y * placeSlots.Z
local basePosition = Vector3.new((-placeSlots.X * maxX) / 2, 500, (-placeSlots.Z * maxZ) / 2)

local placeTable: { [number]: Showcase } = {}

local playerShowcases: { [Player]: Showcase } = {}

if not RunService:IsStudio() then
	assert(maxPlaces >= Players.MaxPlayers, "Not enough places for every player")
end

-- Don't instance it at run-time as it can cause a race condition on client where sometimes it will find and sometimes it wont
local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Expected ReplicatedStorage.AccessoryReplication folder.")

function RoundedVector(vector: Vector3)
	return Vector3.new(math.round(vector.X), math.round(vector.Y), math.round(vector.Z))
end

function GetNextFreeIndex()
	local index = 1
	while index <= maxPlaces do
		if placeTable[index] == nil then
			return index
		end
		index += 1
	end
	error("There was no free place available!")
end

function GetPositionFromIndex(index: number): Vector3
	local offsetX = index % placeSlots.X
	local offsetZ = math.floor(index / placeSlots.X) % placeSlots.Z
	local offsetY = math.floor(index / (placeSlots.X * placeSlots.Z)) % placeSlots.Y

	return Vector3.new(offsetX, offsetY, offsetZ)
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
	local stands: { Types.NetworkStand } = {}
	for i, stand in showcase.stands do
		table.insert(stands, {
			part = stand.part,
			assetId = stand.assetId,
		})
	end

	return {
		GUID = showcase.GUID,
		stands = stands,
		mode = showcase.mode,
		owner = showcase.owner,
		name = showcase.name,
	}
end

function ShowcaseService:ExitPlayerShowcase(player: Player, showcase: Showcase)
	showcase.playersPresent[player] = nil
	if next(showcase.playersPresent) == nil then
		-- Empty
		ShowcaseService:UnloadPlace(showcase)
	end
end

function ShowcaseService:EnterPlayerShowcase(player: Player, showcase: Showcase)
	local oldPlace = playerShowcases[player]
	if oldPlace then
		ShowcaseService:ExitPlayerShowcase(player, oldPlace)
	end

	local character = player.Character
	if not character then
		return
	end

	character:PivotTo(showcase.entranceCFrame)
	showcase.playersPresent[player] = true
	playerShowcases[player] = showcase
	EnterShowcaseEvent:Fire(player, ToNetworkShowcase(showcase))
end

function SavePlace(place: Showcase)
	-- TODO
end

function ShowcaseService:GetShowcase(showcase: Types.Showcase, mode: Types.ShowcaseMode)
	return Future.new(function()
		-- Check for already existing showcase with the same GUID
		for i, place in placeTable do
			if place.GUID == showcase.GUID and place.mode == "View" then
				return place
			end
		end

		local positionStandMap: { [Vector3]: Types.Stand } = {}
		for i, stand in showcase.stands do
			positionStandMap[stand.roundedPosition] = stand
		end

		local placeIndex = GetNextFreeIndex()
		local offset = GetPositionFromIndex(placeIndex)
		local cframe = CFrame.new(basePosition + offset)

		local placeModel = template:Clone()
		placeModel:PivotTo(cframe)
		placeModel.Parent = workspace

		local stands: { [BasePart]: ShowcaseStand } = {}

		-- This loop happens synchronously - may cause a delay if there are a lot of items to fetch
		for i, descendant in placeModel:GetDescendants() do
			if descendant:HasTag(Config.StandTag) and descendant:IsA("BasePart") then
				local roundedPosition = RoundedVector(descendant.Position)
				local savedStand = positionStandMap[roundedPosition]
				local itemDetails: Types.Item?

				if savedStand and savedStand.assetId then
					local success
					success, itemDetails = ItemDetails.GetItemDetails(savedStand.assetId):Await()
					if not success then
						warn("Failed to fetch", itemDetails)
						itemDetails = nil
					end
				end

				stands[descendant] = {
					roundedPosition = roundedPosition,
					item = itemDetails,
					part = descendant,
				}
			end
		end

		local place: Showcase = {
			CFrame = cframe,
			entranceCFrame = cframe,
			stands = stands,
			owner = showcase.owner,
			model = placeModel,
			playersPresent = {},
			tableIndex = placeIndex,
			mode = mode,
			GUID = showcase.GUID,
			name = showcase.name,
		}

		placeTable[placeIndex] = place

		return place
	end)
end

function ShowcaseService:UnloadPlace(place: Showcase)
	for player, _ in place.playersPresent do
		-- Players can leave
		if player.Parent ~= nil then
			player:LoadCharacter()
		end
	end

	place.model:Destroy()

	if placeTable[place.tableIndex] == place then
		placeTable[place.tableIndex] = nil
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
		name = "N/A",
		stands = {},
		GUID = HttpService:GenerateGUID(false),
		owner = player.UserId,
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

	if showcase.mode ~= "Edit" then
		warn(player, "Tried to update a showcase that was not in edit mode.")
		return
	end

	if update.type == "UpdateStand" then
		showcase.stands[update.part].assetId = update.assetId
		if update.assetId then
			ReplicateAsset(update.assetId)
		end

		EnterShowcaseEvent:Fire(player, ToNetworkShowcase(showcase))
	end
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

	Players.PlayerRemoving:Connect(PlayerRemoving)
end

ShowcaseService:Initialize()

return ShowcaseService

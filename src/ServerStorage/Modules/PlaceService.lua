local PlaceService = {}

local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(ReplicatedStorage.Modules.Config)
local Types = require(ReplicatedStorage.Modules.Types)
local Future = require(ReplicatedStorage.Packages.Future)

local UpdateStandsEvent = require(ReplicatedStorage.Events.Place.UpdateStandsEvent):Server()

type Stand = {
	item: Types.Item?,
	roundedPosition: Vector3,
	part: BasePart,
}

type Place = {
	CFrame: CFrame,
	model: Model,
	entranceCFrame: CFrame,
	stands: { [BasePart]: Stand },
	playersPresent: { [Player]: true },
	owner: number, -- UserId since owner doesn't have to be in the server
	tableIndex: number,
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

local placeTable: { [number]: Place } = {}

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

function UpdateStands(place: Place, specificPlayer: Player?)
	local standsToSend: { Types.NetworkStand } = {}
	for part, stand in place.stands do
		if stand.item then
			ReplicateAsset(stand.item.assetId)
		end
		table.insert(standsToSend, {
			part = part,
			item = stand.item,
		})
	end

	if specificPlayer then
		UpdateStandsEvent:Fire(specificPlayer, standsToSend)
	else
		UpdateStandsEvent:FireAll(standsToSend)
	end
end

function EnterPlayerPlace(player: Player, place: Place)
	local character = player.Character
	if not character then
		return
	end

	character:PivotTo(place.entranceCFrame)
	place.playersPresent[player] = true
end

function SavePlace(place: Place)
	-- TODO
end

function PlaceService:GeneratePlace(ownerId: number)
	-- TODO

	local placeIndex = GetNextFreeIndex()
	local offset = GetPositionFromIndex(placeIndex)
	local cframe = CFrame.new(basePosition + offset)

	local placeModel = template:Clone()
	placeModel:PivotTo(cframe)
	placeModel.Parent = workspace

	local stands: { [BasePart]: Stand } = {}
	for i, descendant in placeModel:GetDescendants() do
		if descendant:HasTag(Config.StandTag) and descendant:IsA("BasePart") then
			stands[descendant] = {
				roundedPosition = RoundedVector(descendant.Position),
				item = nil,
				part = descendant,
			}
		end
	end

	local place: Place = {
		CFrame = cframe,
		entranceCFrame = cframe,
		stands = stands,
		owner = ownerId,
		model = placeModel,
		playersPresent = {},
		tableIndex = placeIndex,
	}

	placeTable[placeIndex] = place

	return place
end

function PlaceService:UnloadPlace(place: Place)
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

return PlaceService

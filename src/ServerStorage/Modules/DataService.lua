local DataService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Future = require(ReplicatedStorage.Packages.Future)
local Spawn = require(ReplicatedStorage.Packages.Spawn)
local ProfileService = require(ServerStorage.ServerPackages.ProfileService)

export type VectorTable = {
	x: number,
	y: number,
	z: number,
}

export type Stand = {
	asset: number,
	position: VectorTable,
}

export type Showcase = {
	stands: { Stand },
	name: string,
}

export type Data = {
	showcases: { Showcase },
	version: number,
}

local dataTemplate: Data = {
	showcases = {},
	version = 2,
}

local STOREPREFIX = "PlayerData3"
local PLAYERPREFIX = "Player_"

local ProfileStore =
	assert(ProfileService.GetProfileStore(STOREPREFIX, dataTemplate), "Failed to load profile store") :: ProfileService.ProfileStore

local Profiles: { [Player]: ProfileService.Profile<Data> } = {}

function Reconcile(data: Data) end

function DataService:VectorToTable(vector: Vector3): VectorTable
	return {
		x = vector.X,
		y = vector.Y,
		z = vector.Z,
	}
end

function DataService:TableToVector(vector: VectorTable): Vector3
	return Vector3.new(vector.x, vector.y, vector.z)
end

function PlayerAdded(player: Player)
	local profileKey = PLAYERPREFIX .. player.UserId
	local profile = ProfileStore:LoadProfileAsync(profileKey)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		Reconcile(profile.Data)
		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick()
		end)
		if player.Parent == Players then
			Profiles[player] = profile
		else
			profile:Release()
		end
	else
		player:Kick()
	end
end

function PlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:Release()
	end
end

function DataService:ReadData(player: Player)
	return Future.new(function()
		while player.Parent ~= nil and not Profiles[player] do
			task.wait()
		end

		local profile = Profiles[player]
		if profile then
			return profile.Data :: Data?
		else
			return nil
		end
	end)
end

function DataService:Initialize()
	Players.PlayerAdded:Connect(PlayerAdded)
	for i, player in Players:GetPlayers() do
		Spawn(PlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(PlayerRemoving)
end

DataService:Initialize()

return DataService

local DataService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Future = require(ReplicatedStorage.Packages.Future)
local Spawn = require(ReplicatedStorage.Packages.Spawn)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local ProfileService = require(ServerStorage.ServerPackages.ProfileService)

local ReplicateDataEvent = require(ReplicatedStorage.Events.Data.ReplicateDataEvent):Server()

local STOREPREFIX = "PlayerData8"
local PLAYERPREFIX = "Player_"
local CACHETIMEOUT = 60 * 5

local ProfileStore = assert(
	ProfileService.GetProfileStore(STOREPREFIX, Data.dataTemplate),
	"Failed to load profile store"
) :: ProfileService.ProfileStore

type CachedProfile = {
	cachedTime: number,
	data: Future.Future<Data.Data?>,
}

local profiles: { [Player]: ProfileService.Profile<Data.Data> } = {}
local cachedShowcases: { [number]: CachedProfile? } = {}

function GetKey(userId: number)
	return PLAYERPREFIX .. userId
end

function PlayerAdded(player: Player)
	local profile = ProfileStore:LoadProfileAsync(GetKey(player.UserId))
	if profile ~= nil then
		profile:AddUserId(player.UserId)

		Data.Migrate(profile.Data)

		ReplicateDataEvent:Fire(player, profile.Data)

		profile:ListenToRelease(function()
			profiles[player] = nil
			player:Kick()
		end)
		if player.Parent == Players then
			profiles[player] = profile
		else
			profile:Release()
		end
	else
		player:Kick()
	end
end

function PlayerRemoving(player: Player)
	local profile = profiles[player]
	profile.Data.firstTime = false

	if profile ~= nil then
		-- Might not need to deep copy here, but doing it just to be safe.
		cachedShowcases[player.UserId] = {
			cachedTime = tick(),
			data = TableUtil.Copy(profile.Data, true),
		}
		profile:Release()
	end
end

function FetchOfflineData(userId: number)
	print("Fetching offline data for", userId)

	local dataFuture = Future.new(function(userId): Data.Data?
		local profile = ProfileStore:ViewProfileAsync(GetKey(userId))
		if profile then
			Data.Migrate(profile.Data)
			print("Fetched offline data for", userId)
			return profile.Data
		end

		return nil
	end, userId)

	cachedShowcases[userId] = {
		cachedTime = tick(),
		data = dataFuture,
	}

	return dataFuture
end

function DataService:ReadOfflineData(userId: number, bypassCache: boolean?)
	return Future.new(function()
		local player = Players:GetPlayerByUserId(userId)

		-- Since they may not have loaded yet
		if player and profiles[player] then
			return profiles[player].Data :: Data.Data?
		end

		local cache = cachedShowcases[userId]
		if cache and tick() - cache.cachedTime <= CACHETIMEOUT and not bypassCache then
			return cache.data:Await()
		end

		local data = FetchOfflineData(userId):Await()
		return data
	end)
end

function DataService:ReadData(player: Player)
	return Future.new(function()
		while player.Parent ~= nil and not profiles[player] do
			task.wait()
		end

		local profile = profiles[player]
		if profile then
			return profile.Data :: Data.Data?
		else
			return nil
		end
	end)
end

function DataService:WriteData(player: Player, transform: (Data.Data) -> ())
	return Future.new(function()
		local data = DataService:ReadData(player):Await()
		if not data then
			return
		end

		-- We need to detect yielding because it could result in data not being replicated to the client
		-- As it would be updated after the event is sent

		local yielded = true
		Spawn(function()
			transform(data)
			yielded = false
		end)

		if yielded then
			warn(debug.traceback("Data transform function yielded!"))
		end

		print("Updated!", data)
		ReplicateDataEvent:Fire(player, data)
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

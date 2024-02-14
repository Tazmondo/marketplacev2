local LeaderboardService = {}

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataService = require(script.Parent.DataService)
local LoadedService = require(ServerStorage.Modules.LoadedService)
local LeaderboardEvents = require(ReplicatedStorage.Events.LeaderboardEvents)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)

type LeaderboardUpdateData = LeaderboardEvents.LeaderboardUpdateData
type LeaderboardName = LeaderboardEvents.LeaderboardName

export type LeaderboardData = {
	getData: () -> Future.Future<{ LeaderboardUpdateData }>,
	updated: Signal.Signal<{ LeaderboardUpdateData }>,
	[string]: never,
}

local leaderboards: { [LeaderboardName]: LeaderboardData } = {}

-- We don't need to worry too much about staggering updates out
-- Servers start with a 2500 request budget, that increases at a consistent rate depending on number of players
-- Therefore doing requests in bursts is not really an issue, as long as on average it does not exceed the rate limit
local FETCHCOOLDOWN = 60 -- how often server fetches leaderboards
local UPDATECOOLDOWN = 60 -- how often server updates leaderboards with player information

local function SetupDataFetchFunction(store: OrderedDataStore): (() -> Future.Future<{ LeaderboardUpdateData }>, Signal.Signal<
	{ LeaderboardUpdateData }
>)
	local updated = Signal()

	local data
	task.spawn(function()
		while true do
			local success = false

			while not success do
				local err
				success, err = pcall(function()
					local storeData =
						store:GetSortedAsync(false, 100):GetCurrentPage() :: { { key: string, value: number } }

					local newData: { LeaderboardUpdateData } = table.create(#storeData)
					for _, entry in storeData do
						table.insert(newData, {
							id = assert(tonumber(entry.key)),
							data = entry.value,
						})
					end
					data = newData
				end)
				if not success then
					warn(err)
					task.wait(2)
				end
			end
			updated:Fire(data)

			task.wait(FETCHCOOLDOWN)
		end
	end)

	return function()
		return Future.new(function()
			while not data do
				updated:Wait()
			end
			return data
		end)
	end,
		updated
end

local function RegisterPlayer(player: Player, store: OrderedDataStore, extractData: (Data.Data) -> number)
	task.spawn(function()
		while player.Parent == Players do
			local data = DataService:ReadData(player):Await()
			if not data then
				-- player probably left
				break
			end
			local success
			while not success do
				local err
				success, err = pcall(function()
					store:SetAsync(tostring(player.UserId), extractData(data))
				end)
				if not success then
					warn(err)
					task.wait(2)
				end
			end

			task.wait(UPDATECOOLDOWN)
		end
	end)
end

local function InitializeLeaderboard(
	leaderboardName: LeaderboardName,
	extractData: (Data.Data) -> number,
	onUpdate: ({ LeaderboardUpdateData }) -> ()
)
	local leaderboardStore = DataStoreService:GetOrderedDataStore(leaderboardName)

	local getData, updated = SetupDataFetchFunction(leaderboardStore)

	updated:Connect(onUpdate)

	local leaderboard = {
		getData = getData,
		updated = updated,
	}

	Players.PlayerAdded:Connect(function(player)
		RegisterPlayer(player, leaderboardStore, extractData)
	end)
	for _, player in Players:GetPlayers() do
		RegisterPlayer(player, leaderboardStore, extractData)
	end

	leaderboards[leaderboardName] = leaderboard

	return leaderboard
end

local function Initialize()
	InitializeLeaderboard("Raised", function(data)
		return data.donationRobux
	end, function(data)
		LeaderboardEvents.Update:FireAllClients("Raised", data)
	end)

	InitializeLeaderboard("Purchases", function(data)
		return data.purchases
	end, function(data)
		LeaderboardEvents.Update:FireAllClients("Purchases", data)
	end)

	Players.PlayerAdded:Connect(function(player)
		LoadedService:GetLoadedFuture(player):Await()
		for name, board in leaderboards do
			local data = board.getData()

			-- if not complete, then the event will get sent when it finishes
			-- if it is complete, then just send immediately
			if data:IsComplete() then
				LeaderboardEvents.Update:FireClient(player, name, data:Unwrap())
			end
		end
	end)
end

Initialize()

return LeaderboardService

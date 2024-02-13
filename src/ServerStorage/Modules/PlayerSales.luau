-- Fetches a player's gamepasses for tip displaying purposes

local PlayerSales = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)

local PROXYURL = "roproxy.com"

type GameJSON = {
	data: {
		{
			id: number,
		}
	},
}

type Pass = Types.Pass

type PassJSON = {
	data: { Pass },
}

-- indexed by pass id
type SaleTable = {
	[string]: {
		player: Player,
		points: number,
		price: number,
		passId: number,
	},
}

local function GetGames(id: number)
	return Future.new(function(): GameJSON?
		local success, data
		local count = 0

		while not success and count < 4 do
			print("Attempting to fetch games")
			count += 1
			success, data = pcall(function()
				local data = HttpService:GetAsync(
					`https://games.{PROXYURL}/v2/users/{id}/games?accessFilter=2&limit=50&sortOrder=Asc'`
				)

				return HttpService:JSONDecode(data)
			end)

			if not success then
				warn("Failed to fetch passes", data)
				task.wait(2 ^ count)
			end
		end

		return data
	end)
end

function GetPasses(universeId: number)
	return Future.new(function(): PassJSON?
		local success, data
		local count = 0

		while not success and count < 4 do
			print("Attempting to fetch passes")
			count += 1
			success, data = pcall(function()
				local data = HttpService:GetAsync(
					`https://games.{PROXYURL}/v1/games/{universeId}/game-passes?limit=50&sortOrder=1'`
				)
				return HttpService:JSONDecode(data)
			end)

			if not success then
				warn("Failed to fetch passes", data)
				task.wait(2 ^ count)
			end
		end

		return data
	end)
end

local function GetPlayerPasses(id: number)
	return Future.new(function(): { Pass }
		print("Fetching passes")

		local games = GetGames(id):Await()
		if not games then
			return {}
		end

		local passes = {}

		for _, game in games.data do
			local gamePasses = GetPasses(game.id):Await()
			if gamePasses then
				for _, pass in gamePasses.data do
					table.insert(passes, pass)
				end
			end
		end

		return passes
	end)
end

local cache = Util.FutureCache(GetPlayerPasses)

function PlayerSales.GetPasses(id: number)
	return cache.Get(id)
end

Players.PlayerAdded:Connect(function(plr)
	print(GetPlayerPasses(plr.UserId):Await())
end)

return PlayerSales

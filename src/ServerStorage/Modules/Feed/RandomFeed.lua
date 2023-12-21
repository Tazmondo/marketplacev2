local RandomFeed = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local DataService = require(ServerStorage.Modules.DataService)
local RandomPlayerService = require(ServerStorage.Modules.RandomPlayerService)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)

local FEEDSEGMENTLENGTH = 10

local usedShowcases: { [string]: true? } = {}
local cachedRandomFeed: { Types.Showcase }? = nil
local random = Random.new()

function GenerateFeedSegment()
	return Future.new(function()
		local feed = {}
		local ignoreSet = {}

		while #feed < FEEDSEGMENTLENGTH do
			local nextPlayer = RandomPlayerService:GetPlayer(ignoreSet):Await()
			if not nextPlayer then
				-- No random players to fill up feed with
				break
			end

			local data = DataService:ReadOfflineData(nextPlayer):Await()
			if not data then
				ignoreSet[nextPlayer] = true
				continue
			end

			local filteredShowcases = {}
			for i, showcase in data.showcases do
				if not usedShowcases[showcase.GUID] then
					table.insert(filteredShowcases, showcase)
				end
			end

			if #filteredShowcases == 0 then
				ignoreSet[nextPlayer] = true
				continue
			end

			local index = random:NextInteger(1, #filteredShowcases)
			local showcase = filteredShowcases[index]
			usedShowcases[showcase.GUID] = true

			table.insert(feed, Data.FromDataShowcase(showcase, nextPlayer))
		end

		return feed
	end)
end

function RandomFeed.GetFeed()
	return Future.new(function()
		if cachedRandomFeed then
			return cachedRandomFeed
		end

		local newFeed = GenerateFeedSegment():Await()
		cachedRandomFeed = newFeed

		return newFeed
	end)
end

task.spawn(function()
	print(RandomFeed.GetFeed():Await())
end)

return RandomFeed

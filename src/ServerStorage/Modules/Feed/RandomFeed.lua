local RandomFeed = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local DataService = require(ServerStorage.Modules.DataService)
local RandomPlayerService = require(ServerStorage.Modules.RandomPlayerService)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)

local FEEDSEGMENTLENGTH = 10
local FEEDRATELIMIT = 5

local usedShowcases: { [string]: true? } = {}
local cachedFeed: { Types.Showcase } = {}
local random = Random.new()

local feedFuture: Future.Future<{ Types.Showcase }>? = nil
local rateLimit = Util.CreateRateDelay(FEEDRATELIMIT)

function IsShowcaseValid(showcase: Data.Showcase): boolean
	-- We don't want empty showcases clogging up the feed
	return #showcase.stands >= 8
end

function GenerateFeedSegment()
	return Future.new(function()
		-- If this is being called too much then wait
		rateLimit()

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
				if not usedShowcases[showcase.GUID] and IsShowcaseValid(showcase) then
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

--- Attempts to get a random feed of up to the desired length.
--- May return less than the desired length if there aren't enough valid feeds.
--- Also ensures there is only one feed fetch operation ongoing at a time

function RandomFeed.GetFeed(desiredLength: number?)
	local future = Future.new(function()
		if not desiredLength or desiredLength <= #cachedFeed then
			return cachedFeed
		end

		if feedFuture then
			local lastFeed = feedFuture:Await()
			if #lastFeed >= desiredLength then
				return lastFeed
			end
		end

		while #cachedFeed <= desiredLength do
			local newFeed = GenerateFeedSegment():Await()
			if #newFeed == 0 then
				-- No more showcases can be fetched.
				return cachedFeed
			end

			for i, showcase in newFeed do
				table.insert(cachedFeed, showcase)
			end
		end

		return cachedFeed
	end)

	feedFuture = future

	return future
end

task.spawn(function()
	print(RandomFeed.GetFeed():Await())
end)

return RandomFeed

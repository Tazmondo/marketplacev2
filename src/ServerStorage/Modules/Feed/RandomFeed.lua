local RandomFeed = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RandomValid = require(script.Parent.RandomValid)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local DataService = require(ServerStorage.Modules.Data.DataService)
local RandomPlayerService = require(ServerStorage.Modules.RandomPlayerService)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Doesn't seem to be necessary? Will increase if datastore read rate limits are being hit.
local FEEDRATELIMIT = 0

local usedShowcases: { [string]: true? } = {}

-- Players that cannot contribute any more showcases to the feed
local exhaustedPlayers: { [number]: true? } = {}
local cachedFeed: { Types.Showcase } = {}

local random = Random.new()
local rateLimit = Util.CreateRateYield(FEEDRATELIMIT)

RandomFeed.Extended = Signal()

local function _GetNextShowcase(): Types.Showcase?
	rateLimit()

	local nextPlayer = RandomPlayerService:GetPlayer(exhaustedPlayers):Await()
	if not nextPlayer then
		-- No random players to fill up feed with
		return nil
	end

	local data = DataService:ReadOfflineData(nextPlayer):Await()
	if not data then
		exhaustedPlayers[nextPlayer] = true
		return _GetNextShowcase()
	end

	-- Remove invalid players so they don't clutter up the random feed
	if not RandomValid.AnyValid(data.showcases) then
		exhaustedPlayers[nextPlayer] = true
		RandomPlayerService:RemovePlayer(nextPlayer)
		return _GetNextShowcase()
	end

	local filteredShowcases = {}
	for i, showcase in data.showcases do
		if not usedShowcases[showcase.GUID] and RandomValid.IsValid(showcase) then
			table.insert(filteredShowcases, showcase)
		end
	end

	if #filteredShowcases <= 1 then
		exhaustedPlayers[nextPlayer] = true
		if #filteredShowcases == 0 then
			return _GetNextShowcase()
		end
	end

	local index = random:NextInteger(1, #filteredShowcases)
	local showcase = filteredShowcases[index]
	usedShowcases[showcase.GUID] = true

	local processedShowcase = Data.FromDataShowcase(showcase, nextPlayer)

	table.insert(cachedFeed, processedShowcase)
	RandomFeed.Extended:Fire(cachedFeed)

	return processedShowcase
end

local DebounceGetNextShowcase = Util.ToFuture(Util.CreateYieldDebounce(_GetNextShowcase))

--- Attempts to get a random feed of up to the desired length.
--- May return less than the desired length if there aren't enough valid feeds.
--- Also ensures there is only one feed fetch operation ongoing at a time

function RandomFeed.GetFeed(desiredLength: number?)
	return Future.new(function(): { Types.Showcase }?
		if not desiredLength or desiredLength <= #cachedFeed then
			return cachedFeed
		end

		while #cachedFeed <= desiredLength do
			local nextShowcase = DebounceGetNextShowcase():Await()
			if not nextShowcase then
				-- No more showcases to generate
				if #cachedFeed > 0 then
					return cachedFeed
				else
					return nil
				end
			end
		end

		return cachedFeed
	end)
end

-- Pre-load some random showcases
task.spawn(function()
	print("Pre-loaded random showcases: ", RandomFeed.GetFeed(3):Await())
end)

return RandomFeed

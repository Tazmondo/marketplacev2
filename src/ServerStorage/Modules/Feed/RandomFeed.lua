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

local usedShops: { [string]: true? } = {}

-- Players that cannot contribute any more shops to the feed
local exhaustedPlayers: { [number]: true? } = {}
local cachedFeed: { Types.Shop } = {}

local random = Random.new()
local rateLimit = Util.CreateRateYield(FEEDRATELIMIT)

RandomFeed.Extended = Signal()

local function _GetNextShop(): Types.Shop?
	rateLimit()

	local nextPlayer = RandomPlayerService:GetPlayer(exhaustedPlayers):Await()
	if not nextPlayer then
		-- No random players to fill up feed with
		return nil
	end

	local data = DataService:ReadOfflineData(nextPlayer):Await()
	if not data then
		exhaustedPlayers[nextPlayer] = true
		return _GetNextShop()
	end

	-- Remove invalid players so they don't clutter up the random feed
	if not RandomValid.AnyValid(data.shops) then
		exhaustedPlayers[nextPlayer] = true
		RandomPlayerService:RemovePlayer(nextPlayer)
		return _GetNextShop()
	end

	local filteredShops = {}
	for i, shop in data.shops do
		if not usedShops[shop.GUID] and RandomValid.IsValid(shop) then
			table.insert(filteredShops, shop)
		end
	end

	if #filteredShops <= 1 then
		exhaustedPlayers[nextPlayer] = true
		if #filteredShops == 0 then
			return _GetNextShop()
		end
	end

	local index = random:NextInteger(1, #filteredShops)
	local shop = filteredShops[index]
	usedShops[shop.GUID] = true

	local processedShop = Data.FromDataShop(shop, nextPlayer)

	table.insert(cachedFeed, processedShop)
	RandomFeed.Extended:Fire(cachedFeed)

	return processedShop
end

local DebounceGetNextShop = Util.ToFuture(Util.CreateYieldDebounce(_GetNextShop))

--- Attempts to get a random feed of up to the desired length.
--- May return less than the desired length if there aren't enough valid feeds.
--- Also ensures there is only one feed fetch operation ongoing at a time

function RandomFeed.GetFeed(desiredLength: number?)
	return Future.new(function(): { Types.Shop }?
		if not desiredLength or desiredLength <= #cachedFeed then
			return cachedFeed
		end

		while #cachedFeed <= desiredLength do
			local nextShop = DebounceGetNextShop():Await()
			if not nextShop then
				-- No more shops to generate
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

-- Pre-load some random shops
-- task.spawn(function()
-- 	print("Pre-loaded random shops: ", RandomFeed.GetFeed(3):Await())
-- end)

return RandomFeed

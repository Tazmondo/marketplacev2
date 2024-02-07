local RandomFeed = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RandomValid = require(script.Parent.RandomValid)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local DataService = require(ServerStorage.Modules.Data.DataService)
local RandomPlayerService = require(ServerStorage.Modules.RandomPlayerService)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

-- Players that cannot contribute any more shops to the feed
local exhaustedPlayers: { [number]: true? } = {}

local random = Random.new()

local function _GetNextShop(): Types.Shop?
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
		if RandomValid.IsValid(shop) then
			table.insert(filteredShops, shop)
		end
	end

	if #filteredShops == 0 then
		exhaustedPlayers[nextPlayer] = true
		return _GetNextShop()
	end

	local index = random:NextInteger(1, #filteredShops)
	local shop = filteredShops[index]

	local processedShop = Data.FromDataShop(shop, nextPlayer)

	return processedShop
end

RandomFeed.GetNextShop = Util.ToFuture(Util.CreateYieldDebounce(_GetNextShop))

return RandomFeed

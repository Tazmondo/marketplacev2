local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataService = require(ServerStorage.Modules.Data.DataService)
local Base36 = require(ReplicatedStorage.Modules.Shared.Base36)
local ShopService = require(ServerStorage.Modules.ShopService)

return function(context, recipientPlayers, bucks)
	local player = context.Executor
	local shop = ShopService:GetShopOfPlayer(player)
	if not shop then
		return "Not in a shop."
	end

	if shop.shareCode then
		return `Code: {Base36.Encode(shop.shareCode)}`
	end

	local code = DataService:GenerateNextShareCode(player, shop.owner, shop.GUID):Await()
	if not code then
		return `Failed to generate share code.`
	end

	return `Code: {Base36.Encode(code)}`
end

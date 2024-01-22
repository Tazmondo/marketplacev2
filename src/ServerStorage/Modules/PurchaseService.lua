local PurchaseService = {}

local MarketplaceService = game:GetService("MarketplaceService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local ShopService = require(script.Parent.ShopService)

local gainsStore = MemoryStoreService:GetSortedMap("Rewards")

local EXPIRATION = 60 * 60 * 24 * 21 -- 3 weeks

function HandlePurchase(player: Player, assetId: number, purchased: boolean)
	if not purchased then
		return
	end

	local shop = ShopService:GetShopOfPlayer(player)
	if not shop then
		return
	end

	local ownerId = shop.owner
	local itemDetails = DataFetch.GetItemDetails(assetId):Await()
	if not itemDetails or not itemDetails.price then
		return
	end

	local cut = math.floor(itemDetails.price * 0.4 * Config.OwnerCut)

	gainsStore:UpdateAsync(`{ownerId}`, function(data: number?, sortKey: number?)
		data = data or 0
		assert(data)

		local newData = data + cut
		return newData, newData
	end, EXPIRATION)
end

function PurchaseService:Initialize()
	MarketplaceService.PromptPurchaseFinished:Connect(HandlePurchase)
end

PurchaseService:Initialize()

return PurchaseService

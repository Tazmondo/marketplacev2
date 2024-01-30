local PurchaseService = {}

local MarketplaceService = game:GetService("MarketplaceService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataService = require(ServerStorage.Modules.Data.DataService)
local PurchaseEvents = require(ReplicatedStorage.Events.PurchaseEvents)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)

local purchaseMemory = MemoryStoreService:GetSortedMap("Rewards")

local EXPIRATION = 60 * 60 * 24 * 21 -- 3 weeks

local pendingPurchases: { [Player]: number } = {}

local function HandlePromptFinished(player: Player, assetId: number, purchased: boolean)
	if not purchased then
		pendingPurchases[player] = nil
		return
	end

	DataService:WriteData(player, function(data)
		data.purchases += 1
	end)

	local ownerId = pendingPurchases[player]
	if not ownerId then
		return
	end
	pendingPurchases[player] = nil

	local itemDetails = DataFetch.GetItemDetails(assetId):Await()
	if not itemDetails or not itemDetails.price then
		return
	end

	local cut = math.floor(itemDetails.price * 0.4 * Config.OwnerCut)

	purchaseMemory:UpdateAsync(`{ownerId}`, function(data: number?, sortKey: number?)
		data = data or 0
		assert(data)

		local newData = data + cut
		return newData, newData
	end, EXPIRATION)
end

local function HandlePurchaseAssetEvent(player: Player, assetId: number, shopOwner: number?)
	if shopOwner then
		pendingPurchases[player] = shopOwner
	end

	-- When we get exclusive deals we will need to secure this so users can't buy the exclusive assets.
	MarketplaceService:PromptPurchase(player, assetId)
end

local function PlayerRemoving(player: Player)
	pendingPurchases[player] = nil
end

function PurchaseService:Initialize()
	MarketplaceService.PromptPurchaseFinished:Connect(HandlePromptFinished)
	PurchaseEvents.Asset:SetServerListener(HandlePurchaseAssetEvent)

	Players.PlayerRemoving:Connect(PlayerRemoving)
end

PurchaseService:Initialize()

return PurchaseService

local PurchaseService = {}

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local NotificationEvents = require(ReplicatedStorage.Events.NotificationEvents)
local EffectsService = require(script.Parent.EffectsService)
local ShopService = require(script.Parent.ShopService)
local DataService = require(ServerStorage.Modules.Data.DataService)
local PurchaseEvents = require(ReplicatedStorage.Events.PurchaseEvents)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Future = require(ReplicatedStorage.Packages.Future)

local pendingPurchases: { [Player]: number } = {}

-- How long after the last purchase is made it will send the request out
local UPDATEDELAY = 60

type Update = {
	amount: number,
	owner: number,
	updateThread: thread,
}

type PassProductInfo = {
	PriceInRobux: number,
	Creator: {
		CreatorTargetId: number,
	},
	Name: string,
}

local outgoingUpdates: { [number]: Update } = {}

local function SendUpdate(owner: number, amount: number)
	return Future.new(function()
		outgoingUpdates[owner] = nil
		local success = DataService:SendEarnedUpdate(owner, amount):Await()

		-- If it failed to save then just put it back into the queue
		if not success then
			RegisterEarnedUpdate(owner, amount)
		end
	end)
end

function RegisterEarnedUpdate(owner: number, amount: number)
	local existing = outgoingUpdates[owner]
	if existing then
		amount += existing.amount
		task.cancel(existing.updateThread)
	end

	local newData = {
		owner = owner,
		amount = amount,
		updateThread = task.delay(UPDATEDELAY, SendUpdate, owner, amount),
	}

	outgoingUpdates[owner] = newData
end

local function DispatchEarnedEffect(buyer: Player, seller: number, amount: number)
	NotificationEvents.Raised:FireClient(buyer, amount, seller)

	local ownerPlayer = Players:GetPlayerByUserId(seller)
	if ownerPlayer then
		NotificationEvents.Earned:FireClient(ownerPlayer, amount)
	end

	local ownerShop = ShopService:ShopFromPlayerAndOwner(buyer, seller)
	if ownerShop then
		EffectsService.PurchaseEffect((ownerShop.cframe * CFrame.new(0, 10, 0)).Position)
	end

	RegisterEarnedUpdate(seller, amount)
end

local function AddPurchase(player: Player, price: number)
	local bux = price * Config.BuxMultiplier

	DataService:WriteData(player, function(data)
		data.purchases += 1
		data.totalSpent += price
		data.totalEarned += bux
		data.currentEarned += bux
	end)
end

local function HandlePromptFinished(player: Player, assetId: number, purchased: boolean)
	if not purchased then
		pendingPurchases[player] = nil
		return
	end

	local ownerId: number? = pendingPurchases[player]
	pendingPurchases[player] = nil

	local itemDetails = DataFetch.GetItemDetails(assetId):Await()
	if not itemDetails or not itemDetails.price then
		return
	end

	AddPurchase(player, itemDetails.price)

	if ownerId then
		local ownerBuxEarned = itemDetails.price * Config.BuxMultiplier
		DispatchEarnedEffect(player, ownerId, ownerBuxEarned)
	end
end

local function HandlePurchaseAssetEvent(player: Player, assetId: number, shopOwner: number?)
	if shopOwner then
		pendingPurchases[player] = shopOwner
	end

	-- When we get exclusive deals we will need to secure this so users can't buy the exclusive assets.
	MarketplaceService:PromptPurchase(player, assetId)
end

local function HandleDonationFinished(player: Player, assetId: number, purchased: boolean)
	if not purchased then
		return
	end

	local info = MarketplaceService:GetProductInfo(assetId, Enum.InfoType.GamePass) :: PassProductInfo

	AddPurchase(player, info.PriceInRobux)

	local ownerBuxEarned = info.PriceInRobux * 2
	DispatchEarnedEffect(player, info.Creator.CreatorTargetId, ownerBuxEarned)
end

local function HandleDonateEvent(player: Player, id: number)
	MarketplaceService:PromptGamePassPurchase(player, id)
end

local function PlayerRemoving(player: Player)
	pendingPurchases[player] = nil
end

local function HandleGameClose()
	-- clone it so removal from the table doesnt break the loop
	for _, update in table.clone(outgoingUpdates) do
		task.cancel(update.updateThread)
		SendUpdate(update.owner, update.amount):Await()
	end
end

function PurchaseService:Initialize()
	MarketplaceService.PromptPurchaseFinished:Connect(HandlePromptFinished)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(HandleDonationFinished)

	PurchaseEvents.Asset:SetServerListener(HandlePurchaseAssetEvent)
	PurchaseEvents.Donate:SetServerListener(HandleDonateEvent)

	Players.PlayerRemoving:Connect(PlayerRemoving)
	game:BindToClose(HandleGameClose)
end

PurchaseService:Initialize()

return PurchaseService

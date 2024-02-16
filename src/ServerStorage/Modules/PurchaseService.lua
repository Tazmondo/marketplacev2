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

type EarnedUpdate = {
	type: "Earned",
	amount: number,
	count: number,
	owner: number,
	updateThread: thread,
}

type DonateUpdate = {
	type: "Donate",
	amount: number,
	count: number,
	owner: number,
	updateThread: thread,
}

type Update = EarnedUpdate | DonateUpdate
type UpdateType = typeof(({} :: Update).type)

type PassProductInfo = {
	PriceInRobux: number,
	Creator: {
		CreatorTargetId: number,
		CreatorType: "User" | "Group",
	},
	Name: string,
}

local outgoingUpdates = {
	Sale = {} :: { [number]: EarnedUpdate },
	Donate = {} :: { [number]: DonateUpdate },
}

local function SendEarnedUpdate(owner: number, amount: number, count: number)
	return Future.new(function()
		outgoingUpdates.Sale[owner] = nil
		local success = DataService:SendEarnedUpdate(owner, amount, count):Await()

		-- If it failed to save then just put it back into the queue
		if not success then
			RegisterEarnedUpdate(owner, amount, count)
		end
	end)
end

function RegisterEarnedUpdate(owner: number, amount: number, count: number)
	local existing = outgoingUpdates.Sale[owner]
	if existing then
		amount += existing.amount
		task.cancel(existing.updateThread)
	end

	local newData: EarnedUpdate = {
		type = "Earned" :: "Earned",
		owner = owner,
		count = count,
		amount = amount,

		updateThread = task.delay(UPDATEDELAY, SendEarnedUpdate, owner, amount, count),
	}

	outgoingUpdates.Sale[owner] = newData
end

local function SendDonateUpdate(owner: number, amount: number, count: number)
	return Future.new(function()
		outgoingUpdates.Donate[owner] = nil
		local success = DataService:SendDonationUpdate(owner, amount, count):Await()

		if not success then
			RegisterDonateUpdate(owner, amount, count)
		end
	end)
end

function RegisterDonateUpdate(owner: number, amount: number, count: number)
	return Future.new(function()
		local existing = outgoingUpdates.Donate[owner]
		if existing then
			amount += existing.amount
			task.cancel(existing.updateThread)
		end

		local newData: DonateUpdate = {
			type = "Donate" :: "Donate",
			owner = owner,
			amount = amount,
			count = count,
			updateThread = task.delay(UPDATEDELAY, SendDonateUpdate, owner, amount, count),
		}

		outgoingUpdates.Donate[owner] = newData
	end)
end

local function DispatchEarnedEffect(buyer: Player, seller: number, robux: number, shopbux: number)
	NotificationEvents.EarnedShopbux:FireClient(buyer, shopbux)

	local ownerPlayer = Players:GetPlayerByUserId(seller)
	if ownerPlayer then
		NotificationEvents.ReceiveSale:FireClient(ownerPlayer, robux, buyer.UserId)
		NotificationEvents.EarnedShopbux:FireClient(ownerPlayer, shopbux)
	end

	local ownerShop = ShopService:ShopFromPlayerAndOwner(buyer, seller)
	if ownerShop then
		EffectsService.PurchaseEffect((ownerShop.cframe * CFrame.new(0, 10, 0)).Position)
	end

	RegisterEarnedUpdate(seller, shopbux, 1)
end

local function DispatchDonationEffect(buyer: Player, seller: number, robux: number, shopbux: number)
	NotificationEvents.Donated:FireClient(buyer, robux, seller)
	NotificationEvents.EarnedShopbux:FireClient(buyer, shopbux)

	local ownerPlayer = Players:GetPlayerByUserId(seller)
	if ownerPlayer then
		NotificationEvents.ReceiveDonation:FireClient(ownerPlayer, robux, buyer.UserId)
	end

	local ownerShop = ShopService:ShopFromPlayerAndOwner(buyer, seller)
	if ownerShop then
		EffectsService.PurchaseEffect((ownerShop.cframe * CFrame.new(0, 10, 0)).Position)
	end

	RegisterDonateUpdate(seller, robux, 1)
end

local function HandlePromptFinished(player: Player, assetId: number, purchased: boolean)
	if not purchased then
		pendingPurchases[player] = nil
		return
	end

	local ownerId: number? = pendingPurchases[player]
	pendingPurchases[player] = nil
	if not ownerId or ownerId == player.UserId then
		-- don't process if players purchase from their own shops
		return
	end

	local itemDetails = DataFetch.GetItemDetails(assetId):Await()
	if not itemDetails or not itemDetails.price then
		return
	end

	local bux = itemDetails.price * Config.BuxMultiplier

	DataService:WriteData(player, function(data)
		data.purchases += 1
		data.shopbux += bux
		data.totalShopbux += bux
	end)

	DispatchEarnedEffect(player, ownerId, itemDetails.price, bux)
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

	local success = false
	local info
	while not success do
		success, info = pcall(function()
			return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.GamePass) :: PassProductInfo
		end)
		if not success then
			warn(info)
			task.wait(2)
		end
	end

	if info.Creator.CreatorTargetId == game.CreatorId and info.Creator.CreatorType == game.CreatorType.Name then
		-- Our gamepass was bought, so ignore.
		return
	end

	local bux = info.PriceInRobux * Config.BuxMultiplier
	DataService:WriteData(player, function(data)
		data.purchases += 1
		data.shopbux += bux
		data.totalShopbux += bux
	end)

	DispatchDonationEffect(player, info.Creator.CreatorTargetId, info.PriceInRobux, bux)
end

local function HandleDonateEvent(player: Player, id: number)
	MarketplaceService:PromptGamePassPurchase(player, id)
end

local function PlayerRemoving(player: Player)
	pendingPurchases[player] = nil
end

local function HandleGameClose()
	-- clone it so removal from the table doesnt break the loop
	for _, update in table.clone(outgoingUpdates.Sale) do
		task.cancel(update.updateThread)
		SendEarnedUpdate(update.owner, update.amount, update.count):Await()
	end

	for _, update in table.clone(outgoingUpdates.Donate) do
		task.cancel(update.updateThread)
		SendDonateUpdate(update.owner, update.amount, update.count):Await()
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

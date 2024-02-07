local PurchaseService = {}

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

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

	local experienceCut = 0.4
	if itemDetails.standType and itemDetails.standType ~= "Accessory" then
		-- Classic clothing only gives us 10%, while all other assets give 40%
		experienceCut = 0.1
	end

	local cut = math.floor(itemDetails.price * experienceCut * Config.OwnerCut)

	DataService:WriteData(player, function(data)
		data.purchases += 1
		data.totalSpent += itemDetails.price
	end)

	if ownerId then
		RegisterEarnedUpdate(ownerId, cut)
	end
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

local function HandleGameClose()
	-- clone it so removal from the table doesnt break the loop
	for _, update in table.clone(outgoingUpdates) do
		task.cancel(update.updateThread)
		SendUpdate(update.owner, update.amount):Await()
	end
end

function PurchaseService:Initialize()
	MarketplaceService.PromptPurchaseFinished:Connect(HandlePromptFinished)
	PurchaseEvents.Asset:SetServerListener(HandlePurchaseAssetEvent)

	Players.PlayerRemoving:Connect(PlayerRemoving)
	game:BindToClose(HandleGameClose)
end

PurchaseService:Initialize()

return PurchaseService

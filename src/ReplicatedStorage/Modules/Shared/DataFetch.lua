local DataFetch = {}
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Util)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

type AssetProductInfo = {
	Name: string,
	Description: string?,
	PriceInRobux: number?,
	Created: string,
	Updated: string,
	IsForSale: boolean,
	Sales: number?,
	ProductId: number,
	Creator: {
		CreatorType: "User" | "Group" | nil,
		CreatorTargetId: number,
		Name: string?,
	},
	CollectiblesItemDetails: {
		CollectibleLowestResalePrice: number?,
		TotalQuantity: number?,
	}?,
	TargetId: number,
	ProductType: "User Product",
	AssetId: number,
	AssetTypeId: number,
	IsNew: boolean,
	IsLimited: boolean,
	IsLimitedUnique: boolean,
	IsPublicDomain: boolean,
	Remaining: number?,
	ContentRatingTypeId: number,
	MinimumMembershipLevel: number,
}

type BundleProductInfo = {
	BundleType: "BodyParts",
	Name: string,
	Description: string,
	Id: number,
	Items: {
		{
			Id: number,
			Name: string,
			Type: "Asset" | "UserOutfit",
		}
	},
}

export type Limited = "Limited" | "LimitedU" | "UGC"

export type Item = {
	creator: string,
	name: string,
	assetId: number,
	assetType: Enum.AvatarAssetType,
	price: number?,
	owned: boolean?,
	limited: Limited?,
}

export type BundleBodyParts = {
	LeftLeg: number?,
	LeftArm: number?,
	RightArm: number?,
	RightLeg: number?,
	Torso: number?,
	Head: number?,
}

DataFetch.ItemBought = Signal()

local cachedItems: { [number]: Item } = {}
local cachedOwnedItems: { [Player]: { [number]: Item } } = {}

local cachedBundles: { [number]: BundleProductInfo } = {}
local cachedBundleBodyParts: { [number]: BundleBodyParts } = {}

local validAssets: { [Enum.AvatarAssetType]: true? } = {
	[Enum.AvatarAssetType.Hat] = true,
	[Enum.AvatarAssetType.HairAccessory] = true,
	[Enum.AvatarAssetType.FaceAccessory] = true,
	[Enum.AvatarAssetType.NeckAccessory] = true,
	[Enum.AvatarAssetType.ShoulderAccessory] = true,
	[Enum.AvatarAssetType.FrontAccessory] = true,
	[Enum.AvatarAssetType.BackAccessory] = true,
	[Enum.AvatarAssetType.WaistAccessory] = true,
	[Enum.AvatarAssetType.TShirtAccessory] = true,
	[Enum.AvatarAssetType.ShirtAccessory] = true,
	[Enum.AvatarAssetType.PantsAccessory] = true,
	[Enum.AvatarAssetType.JacketAccessory] = true,
	[Enum.AvatarAssetType.SweaterAccessory] = true,
	[Enum.AvatarAssetType.ShortsAccessory] = true,
	[Enum.AvatarAssetType.DressSkirtAccessory] = true,
	[Enum.AvatarAssetType.LeftArm] = true,
	[Enum.AvatarAssetType.RightArm] = true,
	[Enum.AvatarAssetType.LeftLeg] = true,
	[Enum.AvatarAssetType.RightLeg] = true,
	[Enum.AvatarAssetType.Head] = true,
	[Enum.AvatarAssetType.Torso] = true,
}

local validBodyParts = {
	[Enum.AvatarAssetType.LeftArm] = true,
	[Enum.AvatarAssetType.RightArm] = true,
	[Enum.AvatarAssetType.LeftLeg] = true,
	[Enum.AvatarAssetType.RightLeg] = true,
	[Enum.AvatarAssetType.Head] = true,
	[Enum.AvatarAssetType.Torso] = true,
}

local validAssetNames: { [string]: true? } = {}
for validAsset, _ in validAssets do
	validAssetNames[validAsset.Name] = true
end

local assetTypeIdMap = {}
for i, enum in Enum.AvatarAssetType:GetEnumItems() :: { Enum.AvatarAssetType } do
	assetTypeIdMap[enum.Value] = enum
end

-- local function GenerateBatcher<T>(avatarItemType: Enum.AvatarItemType, typer: T)
-- 	local batch = {}
-- 	local delay = 0.2
-- 	local fetchedSignal: Signal.Signal<{ T }>?

-- 	local function Fetch(signal: Signal.Signal<{ T }>)
-- 		fetchedSignal = nil
-- 		local fetchBatch = batch
-- 		batch = {}

-- 		signal:Fire(AvatarEditorService:GetBatchItemDetails(fetchBatch, avatarItemType))
-- 	end

-- 	local function Get(id: number): T
-- 		table.insert(batch, id)
-- 		if not fetchedSignal then
-- 			local newSignal = Signal()
-- 			fetchedSignal = newSignal

-- 			task.delay(delay, Fetch, newSignal)
-- 		end
-- 		assert(fetchedSignal, "")
-- 		-- Index of this addition
-- 		local index = #batch

-- 		return fetchedSignal:Wait()[index]
-- 	end

-- 	return Get
-- end

function DataFetch.GetItemDetails(assetId: number, ownership: Player?)
	return Future.new(function(assetId): Item?
		if ownership ~= nil and not cachedOwnedItems[ownership] then
			cachedOwnedItems[ownership] = {}
		end

		local cached = cachedItems[assetId]
		if cached then
			if ownership == nil then
				return cached
			end

			local cachedOwnedItem = cachedOwnedItems[ownership][assetId]
			if cachedOwnedItem then
				return cachedOwnedItem
			end

			local ownedSuccess, owned = pcall(function()
				return MarketplaceService:PlayerOwnsAsset(ownership, assetId)
			end)

			local newItem = TableUtil.Copy(cached, true)
			newItem.owned = ownedSuccess and owned
			cachedOwnedItems[ownership][assetId] = newItem
			return newItem
		end

		local getInfoSuccess, details = pcall(function()
			return MarketplaceService:GetProductInfo(assetId) :: AssetProductInfo
		end)

		if not getInfoSuccess then
			warn("Could not fetch item details", details)
			return nil
		end

		local ownedSuccess, owned
		if ownership then
			ownedSuccess, owned = pcall(function()
				return MarketplaceService:PlayerOwnsAsset(ownership, assetId)
			end)
		else
			ownedSuccess, owned = false, false
		end

		local price = if details.Remaining
				and details.Remaining == 0
				and details.CollectiblesItemDetails
			then details.CollectiblesItemDetails.CollectibleLowestResalePrice
			elseif details.IsPublicDomain then 0 -- Item is free
			else details.PriceInRobux

		local limited: Limited? = nil
		if details.CollectiblesItemDetails then
			limited = "UGC"
		elseif details.IsLimited then
			limited = "Limited"
		elseif details.IsLimitedUnique then
			limited = "LimitedU"
		end

		local assetType = assetTypeIdMap[details.AssetTypeId]

		local item: Item = {
			assetId = assetId,
			name = details.Name,
			assetType = assetType,
			creator = details.Creator.Name or "Roblox",
			price = price,
			owned = if ownership then ownedSuccess and owned else nil,
			limited = limited,
		}

		if ownership then
			cachedOwnedItems[ownership][assetId] = item
		end
		cachedItems[assetId] = item

		return item
	end, assetId)
end

function DataFetch.PlayerOwnsAsset(asset: number, player: Player)
	return Future.new(function()
		local ownedSuccess, owned = pcall(function()
			return MarketplaceService:PlayerOwnsAsset(player, asset)
		end)

		if not ownedSuccess then
			-- warn(owned)
		end

		return ownedSuccess and owned
	end)
end

function DataFetch.IsAssetTypeValid(assetType: string)
	return validAssetNames[assetType] == true
end

function DataFetch.IsAssetTypeIdValid(assetType: number)
	return validAssetNames[Enum.AvatarAssetType:GetEnumItems()[assetType].Name] == true
end

function DataFetch.GetValidAssetArray()
	local array = {}
	for asset, _ in validAssets do
		table.insert(array, asset)
	end
	return array
end

function DataFetch.GetBundle(bundleId: number)
	return Future.new(function(bundleId: number): BundleProductInfo?
		local cached = cachedBundles[bundleId]
		if cached then
			return cached
		end

		local success, details = pcall(function(bundleId)
			return MarketplaceService:GetProductInfo(bundleId, Enum.InfoType.Bundle) :: BundleProductInfo
		end, bundleId)

		if not success then
			warn(details)
			return nil
		end

		cachedBundles[bundleId] = details

		return details
	end, bundleId)
end

function DataFetch.GetBundleBodyParts(bundleId: number)
	return Future.new(function(): BundleBodyParts?
		local cached = cachedBundleBodyParts[bundleId]
		if cached then
			return cached
		end

		local details = DataFetch.GetBundle(bundleId):Await()
		if not details then
			return nil
		end

		local itemFutures = TableUtil.Map(details.Items, function(item)
			if item.Type ~= "Asset" then
				return Future.new(function(): Item?
					return nil
				end)
			end

			return DataFetch.GetItemDetails(item.Id)
		end)

		local items = Util.AwaitAllFutures(itemFutures):Await()

		local outputParts = {}

		for i, item in items do
			assert(item, "Item was nil.")
			if item.assetType == Enum.AvatarAssetType.DynamicHead then
				item.assetType = Enum.AvatarAssetType.Head
			end

			if validBodyParts[item.assetType] then
				outputParts[item.assetType.Name] = item.assetId
			end
		end

		cachedBundleBodyParts[bundleId] = outputParts

		return outputParts
	end)
end

local function Initialize()
	Players.PlayerRemoving:Connect(function(player)
		cachedOwnedItems[player] = nil
	end)

	MarketplaceService.PromptPurchaseFinished:Connect(function(player, id, purchased)
		if not purchased then
			return
		end

		if not cachedOwnedItems[player] then
			cachedOwnedItems[player] = {}
		end

		if cachedOwnedItems[player][id] then
			cachedOwnedItems[player][id].owned = true
		end

		DataFetch.ItemBought:Fire(player, id, purchased)
	end)
end

Initialize()

return DataFetch

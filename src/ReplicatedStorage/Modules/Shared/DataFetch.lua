local DataFetch = {}
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Future = require(ReplicatedStorage.Packages.Future)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Types = require(script.Parent.Types)

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

local cachedItems: { [number]: Types.Item } = {}
local cachedOwnedItems: { [Player]: { [number]: Types.Item } } = {}

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
}

local validAssetNames: { [string]: true? } = {}
for validAsset, _ in validAssets do
	validAssetNames[validAsset.Name] = true
end

local assetTypeIdMap = {}
for i, enum in Enum.AvatarAssetType:GetEnumItems() :: { Enum.AvatarAssetType } do
	assetTypeIdMap[enum.Value] = enum
end

function DataFetch.GetItemDetails(assetId: number, ownership: Player?)
	return Future.new(function(assetId): Types.Item?
			local cached = cachedItems[assetId]
			if cached then
			if ownership == nil then
				return cached
			end

			if not cachedOwnedItems[ownership] then
				cachedOwnedItems[ownership] = {}
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

		local limited: Types.Limited? = nil
		if details.CollectiblesItemDetails then
			limited = "UGC"
		elseif details.IsLimited then
			limited = "Limited"
		elseif details.IsLimitedUnique then
			limited = "LimitedU"
		end

		local assetType = assetTypeIdMap[details.AssetTypeId]

		local item: Types.Item = {
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

Players.PlayerRemoving:Connect(function(player)
	cachedOwnedItems[player] = nil
end)

return DataFetch

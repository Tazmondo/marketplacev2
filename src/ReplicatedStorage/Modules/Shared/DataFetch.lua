local DataFetch = {}
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Future = require(ReplicatedStorage.Packages.Future)
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
	IsNew: boolean,
	IsLimited: boolean,
	IsLimitedUnique: boolean,
	IsPublicDomain: boolean,
	Remaining: number?,
	ContentRatingTypeId: number,
	MinimumMembershipLevel: number,
}

local cachedItems: { [number]: Types.Item } = {}

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

function DataFetch.GetItemDetails(assetId: number, ownership: Player?)
	return Future.new(function(assetId)
		if cachedItems[assetId] then
			return cachedItems[assetId] :: Types.Item?
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
			else details.PriceInRobux

		local item: Types.Item = {
			assetId = assetId,
			name = details.Name,
			creator = details.Creator.Name or "Roblox",
			price = price,
			owned = if ownership then ownedSuccess and owned else nil,
		}

		cachedItems[assetId] = item

		return item
	end, assetId)
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

return DataFetch

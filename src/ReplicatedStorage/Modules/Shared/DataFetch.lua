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

local validAssets: { [string]: true? } = {
	Hat = true,
	HairAccessory = true,
	FaceAccessory = true,
	NeckAccessory = true,
	ShoulderAccessory = true,
	FrontAccessory = true,
	BackAccessory = true,
	WaistAccessory = true,
	TShirtAccessory = true,
	ShirtAccessory = true,
	PantsAccessory = true,
	JacketAccessory = true,
	SweaterAccessory = true,
	ShortsAccessory = true,
	DressSkirtAccessory = true,
}

function DataFetch.GetItemDetails(assetId: number)
	return Future.new(function(assetId)
		if cachedItems[assetId] then
			return cachedItems[assetId] :: Types.Item?
		end

		local success, details = pcall(function()
			return MarketplaceService:GetProductInfo(assetId) :: AssetProductInfo
		end)

		if not success then
			warn("Could not fetch item details", details)
			return nil
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
		}

		cachedItems[assetId] = item

		return item
	end, assetId)
end

function DataFetch.IsAssetTypeValid(assetType: string)
	return validAssets[assetType] == true
end

function DataFetch.IsAssetTypeIdValid(assetType: number)
	return validAssets[Enum.AssetType:GetEnumItems()[assetType].Name] == true
end

return DataFetch

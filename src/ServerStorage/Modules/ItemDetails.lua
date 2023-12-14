local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)
local ItemDetails = {}

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

function ItemDetails.GetItemDetails(assetId: number)
	return Future.Try(function(assetId)
		local details = MarketplaceService:GetProductInfo(assetId) :: AssetProductInfo

		local price = if details.PriceInRobux and details.PriceInRobux > 0 then details.PriceInRobux else nil
		local creator = details.Creator.Name or "Roblox"

		return {
			assetId = assetId,
			creator = creator,
			price = price,
			name = details.Name,
		} :: Types.Item
	end, assetId)
end

return ItemDetails

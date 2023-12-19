local DataFetch = {}
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Future = require(ReplicatedStorage.Packages.Future)
local Types = require(script.Parent.Types)

type ProductInfo = {
	Name: string,
	Creator: { Name: string? },
	PriceInRobux: number?,
}

local cachedItems: { [number]: Types.Item } = {}

function DataFetch.GetItemDetails(assetId: number)
	return Future.new(function(assetId)
		if cachedItems[assetId] then
			return cachedItems[assetId] :: Types.Item?
		end

		local success, details = pcall(function()
			return MarketplaceService:GetProductInfo(assetId) :: ProductInfo
		end)

		if not success then
			warn("Could not fetch item details", details)
			return nil
		end

		local item: Types.Item = {
			assetId = assetId,
			name = details.Name,
			creator = details.Creator.Name or "Roblox",
			price = details.PriceInRobux,
		}

		cachedItems[assetId] = item

		return item
	end, assetId)
end

return DataFetch

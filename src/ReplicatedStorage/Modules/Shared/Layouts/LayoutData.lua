local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

export type LayoutId = "Shop 1" | "Shop 2" | "Shop 3" | "Shop 4" | "Shop 5" | "Shop 6" | "Shop 7" | "Shop 8" | "Shop 9"

export type BuyableLayout = {
	type: "Buyable",
	price: number,
	thumb: number,
}

export type FreeLayout = {
	type: "Free",
	thumb: number,
}

export type Layout = BuyableLayout | FreeLayout

local function BuyableLayout(price: number, thumb: number): BuyableLayout
	return {
		type = "Buyable",
		price = price,
		thumb = thumb,
	}
end

local function FreeLayout(thumb: number): FreeLayout
	return {
		type = "Free",
		thumb = thumb,
	}
end

local layoutData: { [LayoutId]: Layout } = {
	["Shop 1"] = FreeLayout(16341180044),
	["Shop 2"] = BuyableLayout(99, 16341180363),
	["Shop 3"] = BuyableLayout(199, 1634118082),
	["Shop 4"] = BuyableLayout(199, 16341181086),
	["Shop 5"] = BuyableLayout(299, 16341181424),
	["Shop 6"] = BuyableLayout(299, 16341181751),
	["Shop 7"] = BuyableLayout(399, 16341182107),
	["Shop 8"] = BuyableLayout(699, 16341182480),
	["Shop 9"] = BuyableLayout(799, 16341182480),
}

TableUtil.Lock(layoutData)

export type StorefrontId =
	"Storefront 1"
	| "Storefront 2"
	| "Storefront 3"
	| "Storefront 4"
	| "Storefront 5"
	| "Storefront 6"
	| "Storefront 7"
	| "Storefront 8"
	| "Storefront 9"
	| "Storefront 10"

local storeFrontData: { [StorefrontId]: number } = {
	["Storefront 1"] = 16139933518,
	["Storefront 2"] = 16139933726,
	["Storefront 3"] = 16139934005,
	["Storefront 4"] = 16139934245,
	["Storefront 5"] = 16139934469,
	["Storefront 6"] = 16139934694,
	["Storefront 7"] = 16139933199,
	["Storefront 8"] = 16139935206,
	["Storefront 9"] = 16139935464,
	["Storefront 10"] = 16139935740,
}

return {
	layoutData = layoutData,
	storeFrontData = storeFrontData,
}

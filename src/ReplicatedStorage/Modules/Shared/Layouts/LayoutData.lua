local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

export type LayoutId = "Shop 1" | "Shop 2" | "Shop 3" | "Shop 4" | "Shop 5" | "Shop 6" | "Shop 7"

local layoutData: { [LayoutId]: number } = {
	["Shop 1"] = 15688473519,
	["Shop 2"] = 15688473638,
	["Shop 3"] = 15688473772,
	["Shop 4"] = 15693431898,
	["Shop 5"] = 15998005134,
	["Shop 6"] = 15998007352,
	["Shop 7"] = 16000178420,
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
	["Storefront 1"] = 15688473519,
	["Storefront 2"] = 15688473519,
	["Storefront 3"] = 15688473519,
	["Storefront 4"] = 15688473519,
	["Storefront 5"] = 15688473519,
	["Storefront 6"] = 15688473519,
	["Storefront 7"] = 15688473519,
	["Storefront 8"] = 15688473519,
	["Storefront 9"] = 15688473519,
	["Storefront 10"] = 15688473519,
}

return {
	layoutData = layoutData,
	storeFrontData = storeFrontData,
}

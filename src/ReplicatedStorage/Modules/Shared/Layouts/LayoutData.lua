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

return {
	layoutData = layoutData,
}

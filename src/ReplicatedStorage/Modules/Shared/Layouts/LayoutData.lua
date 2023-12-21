local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

export type LayoutId = "Shop 1" | "Shop 2" | "Shop 3" | "Shop 4"

local layoutData: { [LayoutId]: number } = {
	["Shop 1"] = 15688473519,
	["Shop 2"] = 15688473638,
	["Shop 3"] = 15688473772,
	["Shop 4"] = 15693431898,
}
TableUtil.Lock(layoutData)
return {
	layoutData = layoutData,
}

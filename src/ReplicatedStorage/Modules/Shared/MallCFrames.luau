local Util = require(script.Parent.Util)
local shopFolder = workspace:FindFirstChild("Mall Shops") :: Folder?
assert(shopFolder, 'Workspace did not have a "Mall Shops" folder.')

export type ShopType = "Dynamic" | "Claimable" | "Sponsored" | "Randomized"

type Shop = {
	type: ShopType,
	cframe: CFrame,
}

local shops: { Shop } = {}
local dynamicShop: Shop & { type: "Dynamic" }

for i, child in shopFolder:GetChildren() do
	if not child:IsA("BasePart") then
		continue
	end

	-- They are not hidden in studio to aid with building, so hide them here.
	child.Transparency = 1

	local name: ShopType = child.Name :: ShopType
	if name == "Dynamic" then
		dynamicShop = { type = "Dynamic" :: "Dynamic", cframe = child.CFrame }
	elseif name == "Sponsored" or name == "Claimable" or name == "Randomized" then
		table.insert(shops, {
			type = name,
			cframe = child.CFrame,
		})
	else
		Util.ExhaustiveMatch(name)
	end
end

local function FuzzyEq(cf1: CFrame, cf2: CFrame)
	return (cf1.Position - cf2.Position).Magnitude < 5
end

local function GetShop(cframe: CFrame): Shop?
	for _, shop in shops do
		if FuzzyEq(cframe, shop.cframe) then
			return shop
		end
	end
	if FuzzyEq(cframe, dynamicShop.cframe) then
		return dynamicShop
	end
	return
end

return {
	shops = shops,
	dynamicShop = assert(dynamicShop, "No dynamic shop found."),
	GetShop = GetShop,
}

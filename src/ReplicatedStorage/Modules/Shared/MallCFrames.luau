local shopFolder = workspace:FindFirstChild("Mall Shops") :: Folder?
assert(shopFolder, 'Workspace did not have a "Mall Shops" folder.')

local shops: { CFrame } = {}
local dynamicShop: CFrame

for i, child in shopFolder:GetChildren() do
	if not child:IsA("BasePart") then
		continue
	end

	-- They are not hidden in studio to aid with building, so hide them here.
	child.Transparency = 1

	if child.Name == "Dynamic" then
		dynamicShop = child:GetPivot()
	else
		table.insert(shops, child:GetPivot())
	end
end

local function GetShopCFrame(cframe: CFrame): CFrame?
	for _, shopCFrame in shops do
		if (shopCFrame.Position - cframe.Position).Magnitude < 5 then
			return shopCFrame
		end
	end
	return
end

return {
	shops = shops,
	dynamicShop = assert(dynamicShop, "No dynamic shop found."),
	GetShopCFrame = GetShopCFrame,
}

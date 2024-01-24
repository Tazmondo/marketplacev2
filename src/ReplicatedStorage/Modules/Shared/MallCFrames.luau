local shopFolder = workspace:FindFirstChild("Mall Shops") :: Folder?
assert(shopFolder, 'Workspace did not have a "Mall Shops" folder.')

local shops: { CFrame } = {}
local dynamicShop: CFrame

for i, child in shopFolder:GetChildren() do
	if not child:IsA("PVInstance") then
		continue
	end

	if child.Name == "Dynamic" then
		dynamicShop = child:GetPivot()
	else
		table.insert(shops, child:GetPivot())
	end
end

return {
	shops = shops,
	dynamicShop = assert(dynamicShop, "No dynamic shop found."),
}

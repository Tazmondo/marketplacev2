local Material = {}

local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local UITypes = require(ReplicatedStorage.Modules.Client.UI.UITypes)

type MaterialSet = {
	material: Enum.Material,
	variant: string?,
}

local baseMaterialMap: { [string]: Enum.Material? } = {}
for i, material in Enum.Material:GetEnumItems() :: { Enum.Material } do
	baseMaterialMap[material.Name] = material
end

local materialGui = (StarterGui:FindFirstChild("Main") :: UITypes.Main).ControllerEdit.TexturePicker
local validMaterials: { [string]: true } = {}
for i, child in materialGui:GetChildren() do
	if child:IsA("ImageButton") then
		validMaterials[child.Name] = true
		assert(
			baseMaterialMap[child.Name] or MaterialService:FindFirstChild(child.Name),
			`{child.Name} from material gui was not a valid material.`
		)
	end
end

function Material:GetMaterialSet(materialName: string): MaterialSet?
	if not validMaterials[materialName] then
		return nil
	end

	local variant = MaterialService:FindFirstChild(materialName) :: MaterialVariant?
	local base = baseMaterialMap[materialName]

	local material = if variant then variant.BaseMaterial elseif base then base else nil
	if material then
		return {
			material = material,
			variant = if variant then variant.Name else nil,
		}
	else
		return nil
	end
end

function Material:TextureExists(texture: string)
	return Material:GetMaterialSet(texture) ~= nil
end

function Material:GetDefault()
	return "Plastic"
end
assert(Material:GetMaterialSet(Material:GetDefault()), "Default material did not exist")

function ValidateNoDuplicateVariants()
	for i, variant in MaterialService:GetChildren() do
		assert(baseMaterialMap[variant.Name] == nil, `Variant {variant.Name} was a duplicate of a base material!`)
	end
end

ValidateNoDuplicateVariants()

return Material

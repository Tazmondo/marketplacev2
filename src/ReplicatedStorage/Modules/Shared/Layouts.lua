local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Config = require(script.Parent.Config)
local Util = require(script.Parent.Util)

export type LayoutId = "Shop 1" | "Shop 2" | "Shop 3" | "Shop 4"

export type Layout = {
	id: LayoutId,
	displayThumbId: number,
	modelTemplate: Model,
	getValidStandPositions: () -> { [Vector3]: boolean },
}

local LayoutFolder = ReplicatedStorage.Assets.Layouts :: Folder

local savedLayouts: { [LayoutId]: Layout } = {}

local Layouts = {}

-- So this loop is only run once and when it's needed
function GenerateValidPositionFunction(model: Model): () -> { [Vector3]: boolean }
	local validPositions

	return function()
		if validPositions then
			return validPositions
		end
		validPositions = {}

		local cframe = model:GetPivot()
		for i, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant:HasTag(Config.StandTag) then
				local roundedPosition = Util.RoundedVector(cframe:PointToObjectSpace(descendant.Position))
				validPositions[roundedPosition] = true
			end
		end

		return validPositions
	end
end

function Layouts:LayoutIdExists(id: string)
	return savedLayouts[id :: LayoutId] ~= nil
end

function Layouts:GuardLayoutId(id: unknown): LayoutId
	assert(typeof(id) == "string" and savedLayouts[id :: LayoutId] ~= nil)
	return id :: LayoutId
end

function Layouts:GetLayout(id: LayoutId)
	return savedLayouts[id]
end

function Layouts:GetLayouts()
	return savedLayouts
end

-- Cause writing the table out every time is a pain
function SetupLayout(id: LayoutId, thumbId: number)
	local model = LayoutFolder:FindFirstChild(id)
	assert(model and model:IsA("Model"), `Could not find model layout with id: {id}`)

	local logo = model:FindFirstChild("ShopLogo")
	assert(logo and logo:IsA("BasePart"), `Layout {id} did not have a ShopLogo`)

	local decal = logo:FindFirstChild("Decal")
	assert(decal and decal:IsA("Decal"), `ShopLogo did not have a decal in {id}`)

	savedLayouts[id] = TableUtil.Lock({
		id = id,
		displayThumbId = thumbId,
		modelTemplate = model,
		getValidStandPositions = GenerateValidPositionFunction(model),
	})
end

SetupLayout("Shop 1", 15688473519)
SetupLayout("Shop 2", 15688473638)
SetupLayout("Shop 3", 15688473772)
SetupLayout("Shop 4", 15693431898)

function Layouts:GetDefaultLayoutId(): LayoutId
	return "Shop 1"
end

return Layouts

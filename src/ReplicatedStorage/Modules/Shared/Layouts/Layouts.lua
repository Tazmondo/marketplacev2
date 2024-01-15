local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local LayoutData = require(script.Parent.LayoutData)

type PositionFunction = () -> { [Vector3]: boolean }
export type Layout = {
	id: LayoutData.LayoutId,
	displayThumbId: number,
	modelTemplate: Model,
	getValidStandPositions: PositionFunction,
	getValidOutfitStandPositions: PositionFunction,
	getNumberOfStands: () -> number,
}

local LayoutFolder = ReplicatedStorage.Assets.Layouts :: Folder

local savedLayouts: { [LayoutData.LayoutId]: Layout } = {}

local Layouts = {}

-- So this loop is only run once and when it's needed
function GenerateValidPositionFunctions(model: Model): (PositionFunction, PositionFunction)
	local validPositions
	local validOutfitPositions

	return function()
		if validPositions then
			return validPositions
		end
		validPositions = {}

		local cframe = model:GetPivot()
		for i, descendant in model:GetDescendants() do
			if descendant:HasTag(Config.StandTag) then
				assert(descendant:IsA("BasePart"), "Stand was tagged but was not a basepart.")

				local roundedPosition = Util.RoundedVector(cframe:PointToObjectSpace(descendant.Position))
				validPositions[roundedPosition] = true
			end
		end

		return validPositions
	end, function()
		if validOutfitPositions then
			return validOutfitPositions
		end
		validOutfitPositions = {}
		local cframe = model:GetPivot()
		for i, descendant in model:GetDescendants() do
			if descendant:HasTag(Config.OutfitStandTag) then
				assert(descendant:IsA("Model"), "Outfit Stand was tagged but was not a model.")

				local roundedPosition = Util.RoundedVector(cframe:PointToObjectSpace(descendant:GetPivot().Position))
				validOutfitPositions[roundedPosition] = true
			end
		end

		return validOutfitPositions
	end
end

-- Only run once per layout and only when needed
function GenerateNumberOfStandsFunction(...: PositionFunction): () -> number
	local positionAmount
	local positionFunctions = { ... }

	return function()
		if positionAmount then
			return positionAmount
		end

		positionAmount = 0
		for _, func in positionFunctions do
			for position, _ in func() do
				positionAmount += 1
			end
		end

		return positionAmount
	end
end

function Layouts:LayoutIdExists(id: string): boolean
	return savedLayouts[id :: LayoutData.LayoutId] ~= nil
end

function Layouts:GuardLayoutId(id: unknown): LayoutData.LayoutId
	assert(typeof(id) == "string" and savedLayouts[id :: LayoutData.LayoutId] ~= nil)
	return id :: LayoutData.LayoutId
end

function Layouts:GetLayout(id: LayoutData.LayoutId)
	return savedLayouts[id]
end

function Layouts:GetLayouts()
	return savedLayouts
end

-- Cause writing the table out every time is a pain
function SetupLayout(id: LayoutData.LayoutId, thumbId: number)
	local model = LayoutFolder:FindFirstChild(id)
	assert(model and model:IsA("Model"), `Could not find model layout with id: {id}`)

	assert(model.PrimaryPart, `Layout {id} did not have PrimaryPart set to a pivot.`)

	local logo = model:FindFirstChild("ShopLogo")
	assert(logo and logo:IsA("BasePart"), `ShopLogo not found in {id}`)

	local gui = logo:FindFirstChildOfClass("SurfaceGui")
	assert(gui, `ShopLogo did not have gui in {id}`)

	local image = gui:FindFirstChildOfClass("ImageLabel")
	assert(image, `ShopLogo did not have an imagelabel in {id}`)

	local validPositionFunction, validOutfitPositionFunction = GenerateValidPositionFunctions(model)
	local standAmountFunction = GenerateNumberOfStandsFunction(validPositionFunction, validOutfitPositionFunction)

	savedLayouts[id] = TableUtil.Lock({
		id = id,
		displayThumbId = thumbId,
		modelTemplate = model,
		getValidStandPositions = validPositionFunction,
		getValidOutfitStandPositions = validOutfitPositionFunction,
		getNumberOfStands = standAmountFunction,
	})
end

for layout: LayoutData.LayoutId, thumbnail in LayoutData.layoutData do
	SetupLayout(layout, thumbnail)
end

assert(Layouts:LayoutIdExists(Config.DefaultLayout), `Default layout {Config.DefaultLayout} is not a valid layout.`)

return Layouts

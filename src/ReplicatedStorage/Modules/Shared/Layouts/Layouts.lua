local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local LayoutData = require(script.Parent.LayoutData)

export type Layout = {
	id: LayoutData.LayoutId,
	displayThumbId: number,
	modelTemplate: Model,
	getValidStandPositions: () -> { [Vector3]: boolean },
	getNumberOfStands: () -> number,
}

local LayoutFolder = ReplicatedStorage.Assets.Layouts :: Folder

local savedLayouts: { [LayoutData.LayoutId]: Layout } = {}

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

-- Only run once per layout and only when needed
function GenerateNumberOfStandsFunction(generatePositions: () -> { [Vector3]: boolean })
	local positionAmount

	return function()
		if positionAmount then
			return positionAmount
		end

		positionAmount = 0
		for position, _ in generatePositions() do
			positionAmount += 1
		end

		return positionAmount
	end
end

function Layouts:LayoutIdExists(id: string)
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

	local logo = model:FindFirstChild("ShopLogo")
	assert(logo and logo:IsA("BasePart"), `ShopLogo not found in {id}`)

	local gui = logo:FindFirstChildOfClass("SurfaceGui")
	assert(gui, `ShopLogo did not have gui in {id}`)

	local image = gui:FindFirstChildOfClass("ImageLabel")
	assert(image, `ShopLogo did not have an imagelabel in {id}`)

	local validPositionFunction = GenerateValidPositionFunction(model)
	local standAmountFunction = GenerateNumberOfStandsFunction(validPositionFunction)

	savedLayouts[id] = TableUtil.Lock({
		id = id,
		displayThumbId = thumbId,
		modelTemplate = model,
		getValidStandPositions = GenerateValidPositionFunction(model),
		getNumberOfStands = standAmountFunction,
	})
end

function Layouts:GetDefaultLayoutId(): LayoutData.LayoutId
	return "Shop 1"
end

for layout: LayoutData.LayoutId, thumbnail in LayoutData.layoutData do
	SetupLayout(layout, thumbnail)
end

return Layouts

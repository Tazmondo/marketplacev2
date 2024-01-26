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
	attachment: CFrame,
	hasLogo: boolean,
	getValidStandPositions: PositionFunction,
	getValidOutfitStandPositions: PositionFunction,
	getNumberOfStands: () -> number,
}

export type Storefront = {
	id: LayoutData.StorefrontId,
	displayThumbId: number,
	modelTemplate: Model,
	attachment: CFrame,
	getNameLabel: (Model) -> TextLabel,
}

local LayoutFolder = ReplicatedStorage.Assets.Layouts :: Folder
local StorefrontFolder = ReplicatedStorage.Assets.Storefronts :: Folder

local savedLayouts: { [LayoutData.LayoutId]: Layout } = {}
local savedStorefronts: { [LayoutData.StorefrontId]: Storefront } = {}

local Layouts = {}

-- So this loop is only run once and when it's needed
local function GenerateValidPositionFunctions(model: Model): (PositionFunction, PositionFunction)
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
local function GenerateNumberOfStandsFunction(...: PositionFunction): () -> number
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
	return assert(savedLayouts[id], `{id} is not a valid layout id!`)
end

function Layouts:GetLayouts()
	return savedLayouts
end

-- Cause writing the table out every time is a pain
local function SetupLayout(id: LayoutData.LayoutId, thumbnail: number)
	local model = LayoutFolder:FindFirstChild(id)
	assert(model and model:IsA("Model"), `Could not find model layout with id: {id}`)

	local logo = model:FindFirstChild("ShopLogo")

	if logo then
		local gui = logo:FindFirstChildOfClass("SurfaceGui")
		assert(gui, `ShopLogo did not have gui in {id}`)

		local image = gui:FindFirstChildOfClass("ImageLabel")
		assert(image, `ShopLogo did not have an imagelabel in {id}`)
	end

	local attachmentPart = model:FindFirstChild("FrontAttachment")
	assert(
		attachmentPart and attachmentPart:IsA("BasePart"),
		`Layout {id} did not have a front attachment, or it was not a part.`
	)

	-- They are not hidden in studio to aid with building, so hide them here.
	attachmentPart.Transparency = 1

	local attachmentCFrame = attachmentPart.CFrame:ToObjectSpace(model:GetPivot())

	local validPositionFunction, validOutfitPositionFunction = GenerateValidPositionFunctions(model)
	local standAmountFunction = GenerateNumberOfStandsFunction(validPositionFunction, validOutfitPositionFunction)

	savedLayouts[id] = TableUtil.Lock({
		id = id,
		displayThumbId = thumbnail,
		modelTemplate = model,
		hasLogo = logo ~= nil,
		attachment = attachmentCFrame,
		getValidStandPositions = validPositionFunction,
		getValidOutfitStandPositions = validOutfitPositionFunction,
		getNumberOfStands = standAmountFunction,
	})
end

function Layouts:StorefrontIdExists(id: string): boolean
	return savedStorefronts[id :: LayoutData.StorefrontId] ~= nil
end

function Layouts:GuardStorefrontId(id: unknown): LayoutData.StorefrontId
	assert(typeof(id) == "string" and savedStorefronts[id :: LayoutData.StorefrontId] ~= nil)
	return id :: LayoutData.StorefrontId
end

function Layouts:GetStorefront(id: LayoutData.StorefrontId)
	return assert(savedStorefronts[id], `{id} is not a valid storefront id!`)
end

function Layouts:GetStorefronts()
	return savedStorefronts
end

function Layouts:GetRandomStorefrontId(seed: number?): LayoutData.StorefrontId
	local random = Random.new(seed or math.random())

	local storefronts = TableUtil.Values(Layouts:GetStorefronts())
	local randomStorefront: LayoutData.StorefrontId = storefronts[random:NextInteger(1, #storefronts)].id

	return randomStorefront
end

local function SetupStorefront(id: LayoutData.StorefrontId, thumbnail: number)
	local model = StorefrontFolder:FindFirstChild(id)
	assert(model and model:IsA("Model"), `Could not find model storefront with id: {id}`)

	local attachmentPart = model:FindFirstChild("FrontAttachment")
	assert(
		attachmentPart and attachmentPart:IsA("BasePart"),
		`Storefront "{id}" did not have a front attachment, or it was not a part.`
	)

	-- They are not hidden in studio to aid with building, so hide them here.
	attachmentPart.Transparency = 1

	local attachmentCFrame = attachmentPart.CFrame:ToObjectSpace(model:GetPivot())

	local function getNameLabel(model: Model): TextLabel
		return model:FindFirstChild("TextLabel", true) :: TextLabel
	end

	local textLabel = getNameLabel(model)
	assert(textLabel and textLabel:IsA("TextLabel"), `Storefront "{id}" did not have a name label.`)

	savedStorefronts[id] = TableUtil.Lock({
		id = id,
		displayThumbId = thumbnail,
		modelTemplate = model,
		attachment = attachmentCFrame,
		getNameLabel = getNameLabel,
	})
end

for layout: LayoutData.LayoutId, thumbnail in LayoutData.layoutData do
	SetupLayout(layout, thumbnail)
end

for storefront: LayoutData.StorefrontId, thumbnail in LayoutData.storeFrontData do
	SetupStorefront(storefront, thumbnail)
end

assert(Layouts:LayoutIdExists(Config.DefaultLayout), `Default layout {Config.DefaultLayout} is not a valid layout.`)

return Layouts

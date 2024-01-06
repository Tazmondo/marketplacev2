--!nolint LocalShadow
local CatalogUI = {}

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local UILoader = require(script.Parent.UILoader)

local MAXPAGES = 4
local MAXITEMS = 60

local accessoryCategories = {
	Back = Enum.AvatarAssetType.BackAccessory,
	Face = Enum.AvatarAssetType.FaceAccessory,
	Front = Enum.AvatarAssetType.FrontAccessory,
	Head = Enum.AvatarAssetType.Hat,
	Hair = Enum.AvatarAssetType.HairAccessory,
	Neck = Enum.AvatarAssetType.NeckAccessory,
	Waist = Enum.AvatarAssetType.WaistAccessory,
	Shoulder = Enum.AvatarAssetType.ShoulderAccessory,
}

local clothingCategories = {
	["Dresses & Skirts"] = Enum.AvatarAssetType.DressSkirtAccessory,
	Jackets = Enum.AvatarAssetType.JacketAccessory,
	Shirts = Enum.AvatarAssetType.ShirtAccessory,
	Shorts = Enum.AvatarAssetType.ShortsAccessory,
	Pants = Enum.AvatarAssetType.PantsAccessory,
	Sweaters = Enum.AvatarAssetType.SweaterAccessory,
	["T-Shirts"] = Enum.AvatarAssetType.TShirtAccessory,
}

type SearchResult = {
	Id: number,
	Name: string,
	Price: number?,
	CreatorType: "User" | "Group",
	AssetType: string?,
}

type Category = "Accessories" | "Clothing"

local gui = UILoader:GetCatalog().Catalog
local content = gui.Content
local tabs = content.Tabs.Frame

local currentCategory: Category = "Clothing"
local currentAssetType: Enum.AvatarAssetType? = nil

local function PopulateResults(results: { SearchResult })
	local scrollFrame = if currentAssetType
		then content.Results.ListWrapper.List
		else content.SearchResults.ListWrapper.List

	for i, item in scrollFrame:GetChildren() do
		if item:IsA("ImageButton") and item:GetAttribute("Temporary") then
			item:Destroy()
		end
	end

	-- Must cast here as the union itemwrapper type doesn't work too well
	local template = scrollFrame.ItemWrapper :: typeof(content.Results.ListWrapper.List.ItemWrapper)
	template.Visible = false

	for i, result in results do
		local item = template:Clone()
	end
end

local function Search()
	-- todo: add filters
	local paramsInstance: any = CatalogSearchParams.new()

	local searchText = content.Actions.Frame.Search.Text
	if searchText ~= "" then
		paramsInstance.SearchKeyword = searchText
	end
	if currentAssetType then
		paramsInstance.AssetTypes = { currentAssetType }
	end

	paramsInstance.IncludeOffSale = false

	if not currentAssetType then
		-- No category is selected, so do big search
		content.Categories.Visible = false
		content.Tabs.Visible = false
		content.SearchResults.Visible = false
	end

	task.spawn(function()
		local success, pages = pcall(function()
			return AvatarEditorService:SearchCatalog(paramsInstance)
		end)

		if not success then
			PopulateResults({})
			return
		end

		local filteredItems = {}
		local currentPage = 1

		while true do
			local items = pages:GetCurrentPage() :: { SearchResult }
			for i, item in items do
				-- if creatorMode ~= "All" and creatorMode ~= item.CreatorType then
				-- 	continue
				-- end

				if item.AssetType and DataFetch.IsAssetTypeValid(item.AssetType) then
					table.insert(filteredItems, item)
				end
			end

			if pages.IsFinished or currentPage == MAXPAGES or #filteredItems >= MAXITEMS then
				break
			end

			pages:AdvanceToNextPageAsync()
			currentPage += 1
		end

		PopulateResults(filteredItems)
	end)
end

local function RenderCategory()
	local checkTable: { [string]: Enum.AvatarAssetType? } = if currentCategory == "Clothing"
		then clothingCategories
		else accessoryCategories

	for i, button in content.Categories.List:GetChildren() do
		if button:IsA("ImageButton") then
			button.Visible = checkTable[button.Name] ~= nil
		end
	end
end

local function RenderHeaders()
	-- Bug with Luau lsp means this type can't be in-lined or syntax highlighting breaks
	type Header = typeof(tabs.Accessories)

	local function RenderHeader(header: Header)
		if header.Name == currentCategory then
			header.BackgroundTransparency = 0
			header.ItemImage.ImageTransparency = 0
			header.TextLabel.TextTransparency = 0
		else
			header.BackgroundTransparency = 1
			header.ItemImage.ImageTransparency = 0.8
			header.TextLabel.TextTransparency = 0.8
		end
	end

	RenderHeader(tabs.Accessories)
	RenderHeader(tabs.Clothing)

	RenderCategory()
end

local function SubCategoryClicked(categoryType: Enum.AvatarAssetType)
	currentAssetType = categoryType
	content.Categories.Visible = false
	content.Results.Visible = true
	Search()
end

function CatalogUI:ToggleDisplay(force: boolean?)
	local visible = if force == nil then not gui.Visible else force
	gui.Visible = visible
end

function CatalogUI:Initialize()
	gui.Visible = false
	content.Results.Visible = false
	content.Categories.Visible = true

	content.Actions.Close.Activated:Connect(function()
		gui.Visible = false
	end)
	content.Results.ListWrapper.Actions.Close.Activated:Connect(function()
		content.Results.Visible = false
		content.Categories.Visible = true
	end)

	for i, button in tabs:GetChildren() do
		if button:IsA("TextButton") then
			button.Activated:Connect(function()
				currentCategory = button.Name :: Category
				RenderHeaders()
			end)
		end
	end

	for i, subCategory in content.Categories.List:GetChildren() do
		if subCategory:IsA("ImageButton") then
			local categoryType = assert(
				accessoryCategories[subCategory.Name] or clothingCategories[subCategory.Name],
				`Category button {subCategory:GetFullName()} was not registered.`
			)

			subCategory.Activated:Connect(function()
				SubCategoryClicked(categoryType)
			end)
		end
	end

	RenderHeaders()
end

CatalogUI:Initialize()

return CatalogUI

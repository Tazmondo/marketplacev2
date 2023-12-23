local AddItemUI = {}

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Signal = require(ReplicatedStorage.Packages.Signal)
local UILoader = require(script.Parent.UILoader)

type SearchResult = {
	Id: number,
	Name: string,
	Price: number?,
	CreatorType: "User" | "Group",
	AssetType: string?,
}

local gui = UILoader:GetMain().AddItemID
local searchFrame = gui.SearchWrapper.Search.Search

local currentPosition: Vector3? = nil

type SearchMode = "Name" | "Id"
local searchModes: { SearchMode } = { "Name", "Id" }
type CreatorMode = "All" | "User" | "Group"
local creatorModes: { CreatorMode } = { "All", "User", "Group" }

-- State that can't be represented easily with just the UI
local extraState = {
	includeOffsale = false,
	sort = Enum.CatalogSortType.Relevance,
	searchMode = 1,
	creatorMode = 1,
}

local sortNames: { [Enum.CatalogSortType]: string? } = {
	[Enum.CatalogSortType.MostFavorited] = "Most Favourited",
	[Enum.CatalogSortType.PriceHighToLow] = "High - Low",
	[Enum.CatalogSortType.PriceLowToHigh] = "Low - High",
	[Enum.CatalogSortType.RecentlyCreated] = "Recent",
}

AddItemUI.Added = Signal()

function AddItemUI:Display(roundedPosition: Vector3)
	gui.Visible = true
	currentPosition = roundedPosition
end

function AddItemUI:Hide()
	gui.Visible = false
	currentPosition = nil
end

function ToggleSearch()
	gui.SearchWrapper.Visible = not gui.SearchWrapper.Visible
end

function CycleSort()
	local items: { Enum.CatalogSortType } = Enum.CatalogSortType:GetEnumItems()

	local currentIndex = assert(table.find(items, extraState.sort))
	local newIndex = currentIndex + 1
	if newIndex > #items then
		newIndex = 1
	end

	local newSort = items[newIndex]
	extraState.sort = newSort
	searchFrame.Bottom.Filter.TextLabel.Text = sortNames[newSort] or newSort.Name
end

function CycleSearch()
	local newIndex = extraState.searchMode + 1
	if newIndex > #searchModes then
		newIndex = 1
	end
	extraState.searchMode = newIndex
	searchFrame.Top.ItemName.Toggle.TextLabel.Text = searchModes[newIndex]
end

function CycleCreator()
	local newIndex = extraState.creatorMode + 1
	if newIndex > #creatorModes then
		newIndex = 1
	end
	extraState.creatorMode = newIndex
	searchFrame.Top.Creator.Toggle.TextLabel.Text = creatorModes[newIndex]
end

function ToggleIncludeOffsale()
	extraState.includeOffsale = not extraState.includeOffsale

	local newColour = if extraState.includeOffsale then Color3.fromRGB(0, 120, 244) else Color3.fromRGB(49, 49, 49)
	local newTextColor = if extraState.includeOffsale
		then Color3.fromRGB(255, 255, 255)
		else Color3.fromRGB(178, 178, 178)

	searchFrame.Bottom.OffSale.BackgroundColor3 = newColour
	searchFrame.Bottom.OffSale.TextLabel.TextColor3 = newTextColor
end

function PopulateResults(results: { SearchResult })
	local resultsFrame = gui.SearchResults.Grid
	for i, child in resultsFrame:GetChildren() do
		if child:IsA("ImageButton") and child:GetAttribute("Temporary") then
			child:Destroy()
		end
	end

	-- Scroll to top
	resultsFrame.CanvasPosition = Vector2.new()

	print("Rendering results:", results)

	local template = resultsFrame.Row
	template.Visible = false
	for i, result in results do
		local newRow = template:Clone()
		newRow.Visible = true
		newRow.Thumb.Image = Thumbs.GetAsset(result.Id)
		newRow.Details.NameLabel.Text = result.Name
		if result.Price then
			newRow.Details.Frame.Price.Text = tostring(result.Price)
		else
			newRow.Details.Frame.Visible = false
		end

		newRow:SetAttribute("Temporary", true)
		newRow.Activated:Connect(function()
			Add(result.Id)
		end)

		newRow.Parent = template.Parent
	end
end

function RenderOutline(textBox: TextBox & {
	UIStroke: UIStroke,
})
	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		textBox.UIStroke.Enabled = textBox.Text ~= ""
	end)
end

function Search()
	if searchModes[extraState.searchMode] == "Id" then
		local id = tonumber(searchFrame.Top.ItemName.Text)
		if not id then
			return
		end

		Add(id)
		return
	end

	-- Need to cast to any as luau lsp wasnt up to date with the latest api, giving incorrect type errors
	-- https://create.roblox.com/docs/reference/engine/datatypes/CatalogSearchParams
	local params: any = CatalogSearchParams.new()

	params.SearchKeyword = searchFrame.Top.ItemName.Text
	params.CreatorName = searchFrame.Top.Creator.Text

	local min = tonumber(searchFrame.Bottom.Min.Text)
	local max = tonumber(searchFrame.Bottom.Max.Text)
	if min then
		params.MinPrice = min
	end
	if max then
		params.MaxPrice = max
	end
	params.IncludeOffSale = extraState.includeOffsale
	params.SortType = extraState.sort

	task.spawn(function()
		-- Yields
		local pages = AvatarEditorService:SearchCatalog(params)

		local filteredItems = {}
		local creatorMode = creatorModes[extraState.creatorMode]

		while #filteredItems < 250 do
			local items = pages:GetCurrentPage() :: { SearchResult }
			for i, item in items do
				if creatorMode ~= "All" and creatorMode ~= item.CreatorType then
					continue
				end

				if item.AssetType and DataFetch.IsAssetTypeValid(item.AssetType) then
					table.insert(filteredItems, item)
				end
			end

			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end

		PopulateResults(filteredItems)

		gui.SearchWrapper.Visible = false
	end)
end

function Add(id: number)
	if not currentPosition then
		return
	end

	AddItemUI.Added:Fire(currentPosition, id)
	AddItemUI:Hide()
end

function AddItemUI:Initialize()
	gui.Visible = false
	gui.SearchWrapper.Visible = false

	gui.Title.Close.ImageButton.Activated:Connect(AddItemUI.Hide)
	gui.Title.Search.ImageButton.Activated:Connect(ToggleSearch)

	searchFrame.Actions.Search.Activated:Connect(Search)
	searchFrame.Bottom.Filter.Activated:Connect(CycleSort)
	searchFrame.Bottom.OffSale.Activated:Connect(ToggleIncludeOffsale)
	searchFrame.Top.ItemName.Toggle.Activated:Connect(CycleSearch)
	searchFrame.Top.Creator.Toggle.Activated:Connect(CycleCreator)

	RenderOutline(searchFrame.Top.ItemName)

	RenderOutline(searchFrame.Top.Creator)

	RenderOutline(searchFrame.Bottom.Min)

	RenderOutline(searchFrame.Bottom.Max)

	searchFrame.Bottom.Filter.TextLabel.Text = sortNames[extraState.sort] or extraState.sort.Name
	searchFrame.Top.ItemName.Toggle.TextLabel.Text = searchModes[extraState.searchMode]
	searchFrame.Top.Creator.Toggle.TextLabel.Text = creatorModes[extraState.creatorMode]

	Search()
end

AddItemUI:Initialize()

return AddItemUI

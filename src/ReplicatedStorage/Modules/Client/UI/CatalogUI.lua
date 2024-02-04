local CatalogUI = {}

local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local ConfirmUI = require(script.Parent.ConfirmUI)
local CartController = require(ReplicatedStorage.Modules.Client.CartController)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Future = require(ReplicatedStorage.Packages.Future)
local UILoader = require(script.Parent.UILoader)
local Device = require(ReplicatedStorage.Modules.Client.Device)
local Loaded = require(ReplicatedStorage.Modules.Client.Loaded)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local DataController = require(ReplicatedStorage.Modules.Client.DataController)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local DataEvents = require(ReplicatedStorage.Events.DataEvents)
local PurchaseEvents = require(ReplicatedStorage.Events.PurchaseEvents)
local CharacterCache = require(ReplicatedStorage.Modules.Client.CharacterCache)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Bin = require(ReplicatedStorage.Packages.Bin)

type UseMode = "Wear" | "Select"
type DisplayMode = "Marketplace" | "Inventory" | "OutfitPane"
type Category = "Clothing" | "Accessories" | "Characters" | "Wearing"

type ClothingCategory =
	"Dresses & Skirts"
	| "Jackets"
	| "Shirts"
	| "Shorts"
	| "Pants"
	| "Sweaters"
	| "T-Shirts"
	| "Classic T-Shirts"
	| "Shirts"
	| "Pants"
type AccessoryCategory = "Back" | "Face" | "Front" | "Head" | "Hair" | "Neck" | "Waist" | "Shoulder"
type SubCategory = ClothingCategory | AccessoryCategory | "Wearing" | "Outfits" | "Characters"
type SearchResult = {
	Id: number,
	Name: string,
	ItemType: "Bundle" | "Asset",
	Price: number?,
	LowestPrice: number?,
	LowestResalePrice: number?,
	UnitsAvailableForConsumption: number?,
	HasResellers: boolean?,
	CreatorType: "User" | "Group",
	AssetType: string?,
	ItemRestrictions: { "Limited" | "LimitedUnique" | "Collectible" | "ThirteenPlus" },
	BundleType: "BodyParts" | nil,
}

local accessoryOrder = {
	Hair = 1,
	Head = 2,
	Face = 3,
	Neck = 4,
	Front = 5,
	Back = 6,
	Shoulder = 7,
	Waist = 8,
}

local clothingOrder = {
	Jackets = 1,
	Sweaters = 2,
	Shirts = 3,
	["T-Shirts"] = 4,
	Pants = 5,
	Shorts = 6,
	["Dresses & Skirts"] = 7,
	["Classic T-Shirts"] = 8,
	["Classic Shirts"] = 9,
	["Classic Pants"] = 10,
}

local wearingOrder = {
	Wearing = 1,
	Outfits = 2,
}

local charactersOrder = {
	Characters = 1,
}

local categories = {
	Marketplace = {
		Clothing = {
			["Dresses & Skirts"] = Enum.AvatarAssetType.DressSkirtAccessory,
			Jackets = Enum.AvatarAssetType.JacketAccessory,
			Shirts = Enum.AvatarAssetType.ShirtAccessory,
			Shorts = Enum.AvatarAssetType.ShortsAccessory,
			Pants = Enum.AvatarAssetType.PantsAccessory,
			Sweaters = Enum.AvatarAssetType.SweaterAccessory,
			["T-Shirts"] = Enum.AvatarAssetType.TShirtAccessory,
			["Classic T-Shirts"] = Enum.AvatarAssetType.TShirt,
			["Classic Shirts"] = Enum.AvatarAssetType.Shirt,
			["Classic Pants"] = Enum.AvatarAssetType.Pants,
		},
		Accessories = {
			Back = Enum.AvatarAssetType.BackAccessory,
			Face = Enum.AvatarAssetType.FaceAccessory,
			Front = Enum.AvatarAssetType.FrontAccessory,
			Head = Enum.AvatarAssetType.Hat,
			Hair = Enum.AvatarAssetType.HairAccessory,
			Neck = Enum.AvatarAssetType.NeckAccessory,
			Waist = Enum.AvatarAssetType.WaistAccessory,
			Shoulder = Enum.AvatarAssetType.ShoulderAccessory,
		},
		Characters = {
			Characters = newproxy(), -- use newproxy so we just have some unique value for comparisons
		},
	},
	Inventory = {
		Wearing = {
			Wearing = newproxy(),
			Outfits = newproxy(),
		},
	},
}

CatalogUI.VisibilityUpdated = Signal()

local ItemSelected: Signal.Signal<number, Types.StandType> = Signal()
local OutfitSelected: Signal.Signal<HumanoidDescription> = Signal()

local previewing = false

local animationFolder = ReplicatedStorage.Assets.Animations
local idleAnimation = animationFolder.Idle
local currentIdleTrack: AnimationTrack? = nil

local currentUseMode: UseMode = "Wear"
local currentMode: DisplayMode = "Marketplace"
local currentCategory: Category = "Clothing"
local currentSubcategory: SubCategory = "Jackets"

local searchIdentifier = newproxy() -- Used so old searches dont overwrite new ones
local searchPages: CatalogPages? = nil
local currentlySearching = false
local currentResults: { SearchResult } = {}

type CreatorMode = "All" | "User" | "Group"
local creatorModes: { CreatorMode } = { "All", "User", "Group" }

-- State that can't be represented easily with just the UI
local extraState = {
	includeOffSale = false,
	limiteds = false,
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

local studio = assert(workspace:FindFirstChild("Studio"), "Could not find studio in workspace.") :: Model
local studioCamera =
	assert(studio:FindFirstChild("StudioCamera"), "Studio did not have a StudioCamera part.") :: BasePart
studioCamera.Transparency = 1
local studioStand = assert(studio:FindFirstChild("StudioStand"), "Studio did not have a stand part.") :: BasePart

local gui = UILoader:GetCatalog().Catalog

function CycleSort()
	local items: { Enum.CatalogSortType } = Enum.CatalogSortType:GetEnumItems()

	local currentIndex = assert(table.find(items, extraState.sort))
	local newIndex = currentIndex + 1
	if newIndex > #items then
		newIndex = 1
	end

	local newSort = items[newIndex]
	extraState.sort = newSort
	gui.RightPane.Overlay.Filter.Search.Bottom.Filter.TextLabel.Text = sortNames[newSort] or newSort.Name

	PopulateResults()
end

function CycleCreator()
	local newIndex = extraState.creatorMode + 1
	if newIndex > #creatorModes then
		newIndex = 1
	end
	extraState.creatorMode = newIndex
	gui.RightPane.Overlay.Filter.Search.Top.Creator.Toggle.TextLabel.Text = creatorModes[newIndex]

	PopulateResults()
end

function ToggleIncludeOffSale()
	extraState.includeOffSale = not extraState.includeOffSale

	local newColour = if extraState.includeOffSale then Color3.fromRGB(0, 120, 244) else Color3.fromRGB(49, 49, 49)
	local newTextColor = if extraState.includeOffSale
		then Color3.fromRGB(255, 255, 255)
		else Color3.fromRGB(178, 178, 178)

	gui.RightPane.Overlay.Filter.Search.Bottom.OffSale.BackgroundColor3 = newColour
	gui.RightPane.Overlay.Filter.Search.Bottom.OffSale.TextLabel.TextColor3 = newTextColor

	PopulateResults()
end

function ToggleLimiteds()
	extraState.limiteds = not extraState.limiteds
	local newColour = if extraState.limiteds then Color3.fromRGB(0, 120, 244) else Color3.fromRGB(49, 49, 49)
	local newTextColor = if extraState.limiteds then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(178, 178, 178)

	gui.RightPane.Overlay.Filter.Search.Top.IsLimited.BackgroundColor3 = newColour
	gui.RightPane.Overlay.Filter.Search.Top.IsLimited.TextLabel.TextColor3 = newTextColor

	PopulateResults()
end

function RefreshResults()
	local list = gui.RightPane.Marketplace.Results.ListWrapper.List
	for i, child in list:GetChildren() do
		if child:GetAttribute("Temporary") then
			child:Destroy()
		end
	end

	list.NewOutfit.Visible = false

	local template = list.ItemWrapper
	template.Visible = false

	for i, result in currentResults do
		local item = template:Clone()
		item.Name = "item"
		item:SetAttribute("Temporary", true)
		item.Visible = true
		item.ImageFrame.Frame.ItemImage.Image = if result.ItemType == "Asset"
			then Thumbs.GetAsset(result.Id)
			else Thumbs.GetBundle(result.Id)

		local isLimited = TableUtil.Find(result.ItemRestrictions, function(restriction)
			return restriction == "Limited" or restriction == "LimitedUnique" or restriction == "Collectible"
		end) ~= nil

		item.IsLimited.Visible = isLimited

		if CartController:IsEquipped(result.Id) then
			item.Buy.Visible = true
			item.Buy.TextLabel.Text = tostring(
				if result.HasResellers and result.LowestResalePrice
					then result.LowestResalePrice
					else result.LowestPrice or result.Price or 0
			)
			item.Buy.Activated:Connect(function()
				if result.ItemType == "Asset" then
					PurchaseEvents.Asset:FireServer(result.Id)
				elseif result.ItemType == "Bundle" then
					MarketplaceService:PromptBundlePurchase(Players.LocalPlayer, result.Id)
				end
			end)
			item.UIStroke.Enabled = true
		else
			item.UIStroke.Enabled = false
			item.Buy.Visible = false
		end

		item.Activated:Connect(function()
			if result.ItemType == "Asset" then
				if currentUseMode == "Wear" then
					if result.AssetType == "TShirt" or result.AssetType == "Shirt" or result.AssetType == "Pants" then
						CartController:ToggleClassicClothing(result.Id, result.AssetType)
					else
						CartController:ToggleInCart(result.Id)
					end
					RefreshResults()
				elseif currentUseMode == "Select" then
					local type: Types.StandType = if result.AssetType == "TShirt"
							or result.AssetType == "Shirt"
							or result.AssetType == "Pants"
						then result.AssetType
						else "Accessory"
					ItemSelected:Fire(result.Id, type)
				end
			elseif result.ItemType == "Bundle" then
				if currentUseMode == "Wear" then
					CartController:EquipPackage(result.Id)
					RefreshResults()
				else
					-- Don't do anything when use mode is select
				end
			end
		end)

		item.Parent = list
	end
end

function AddSearchResults(results: { SearchResult })
	for i, result in results do
		table.insert(currentResults, result)
	end

	RefreshResults()
end

function ClearResults()
	currentResults = {}
	searchPages = nil
	RefreshResults()
end

function ProcessPage()
	if not searchPages then
		return
	end

	local filteredItems = {}

	local items = searchPages:GetCurrentPage() :: { SearchResult }
	for i, item in items do
		if
			(item.ItemType == "Asset" and item.AssetType and DataFetch.IsAssetTypeValid(item.AssetType))
			or item.ItemType == "Bundle"
		then
			table.insert(filteredItems, item)
		end
	end

	print("Searched: ", #filteredItems, items)

	AddSearchResults(filteredItems)
end

function ReadNextPage()
	return Future.new(function()
		if currentlySearching or not searchPages or searchPages.IsFinished then
			return
		end
		currentlySearching = true
		searchPages:AdvanceToNextPageAsync()
		currentlySearching = false
		ProcessPage()
	end)
end

function GenerateSearchObject(): CatalogSearchParams
	local overlay = gui.RightPane.Overlay

	local paramsInstance = CatalogSearchParams.new()

	local searchText = overlay.Search.Search.Search.Text
	local creatorText = overlay.Filter.Search.Top.Creator.Text
	local minPrice = tonumber(overlay.Filter.Search.Bottom.Min.Text)
	local maxPrice = tonumber(overlay.Filter.Search.Bottom.Max.Text)

	paramsInstance.SearchKeyword = searchText;
	(paramsInstance :: any).CreatorName = creatorText

	if minPrice then
		paramsInstance.MinPrice = minPrice
	end

	if maxPrice then
		paramsInstance.MaxPrice = maxPrice
	end

	(paramsInstance :: any).IncludeOffSale = extraState.includeOffSale;
	(paramsInstance :: any).SalesTypeFilter = if extraState.limiteds
		then Enum.SalesTypeFilter.Collectibles
		else Enum.SalesTypeFilter.All

	paramsInstance.SortType = extraState.sort

	if currentCategory == "Characters" then
		print("Bundle");
		(paramsInstance :: any).BundleTypes = { Enum.BundleType.BodyParts }
	else
		local currentAssetType: Enum.AvatarAssetType? = categories[currentMode][currentCategory][currentSubcategory]

		if currentAssetType then
			-- we can make this cast, as AvatarAssetType is actually a subset of AssetType
			-- https://create.roblox.com/docs/reference/engine/enums/AssetType
			-- https://create.roblox.com/docs/reference/engine/enums/AvatarAssetType
			paramsInstance.AssetTypes = { (currentAssetType :: any) :: Enum.AssetType }
		end
	end

	return paramsInstance
end

function SearchCatalog()
	ClearResults()
	if currentMode ~= "Marketplace" then
		return
	end
	print("Searching catalog")

	local identifier = newproxy()
	searchIdentifier = identifier
	currentlySearching = true

	task.spawn(function()
		local success, pages = pcall(function()
			return AvatarEditorService:SearchCatalog(GenerateSearchObject())
		end)

		if not success or identifier ~= searchIdentifier then
			warn(pages)
			return
		end
		searchPages = pages
		currentlySearching = false
		ProcessPage()
	end)
end

local function RenderOutfitToViewport(
	viewport: ViewportFrame & { WorldModel: WorldModel },
	description: Types.SerializedDescription
)
	return Future.new(
		function(viewport: ViewportFrame & { WorldModel: WorldModel }, description: Types.SerializedDescription)
			local outfitModelTemplate = CharacterCache:LoadWithDescription(description):Await()

			if not outfitModelTemplate or not viewport.Parent then
				return
			end

			local existing = viewport.WorldModel:FindFirstChildOfClass("Model")
			if existing then
				existing:Destroy()
			end

			local outfitModel = outfitModelTemplate:Clone()

			-- Camera offset from the centre of the character
			local cameraOffset = (studioStand.CFrame + Vector3.new(0, 3.19, 0)):ToObjectSpace(studioCamera.CFrame)

			local camera = viewport.CurrentCamera or Instance.new("Camera", viewport)
			viewport.CurrentCamera = camera
			camera.CameraType = Enum.CameraType.Scriptable
			camera.FieldOfView = 16

			outfitModel:PivotTo(CFrame.new())
			outfitModel.Parent = viewport.WorldModel
			camera.CFrame = outfitModel:GetPivot():ToWorldSpace(cameraOffset)
		end,
		viewport,
		description
	)
end

function RenderOutfits()
	ClearResults()

	local list = gui.RightPane.Marketplace.Results.ListWrapper.List

	local data = DataController:UnwrapData()
	if not data then
		return
	end

	list.NewOutfit.Visible = true

	local template = list.OutfitWrapper
	template.Visible = false

	for _, dataOutfit in data.outfits do
		local outfit = Data.FromDataOutfit(dataOutfit)
		local row = template:Clone()

		row.Visible = true
		row.Title.Visible = true
		row.Title.TextLabel.Text = outfit.name

		local function Equipped(stroke: UIStroke, base: HumanoidDescription)
			local description = CartController:GetDescription():Await()
			stroke.Enabled = HumanoidDescription.FuzzyEq(description, base)
		end

		task.spawn(Equipped, row.UIStroke, outfit.description)
		local conn = CartController.CartUpdated:Connect(function()
			Equipped(row.UIStroke, outfit.description)
		end)
		row.Destroying:Once(conn)

		row:SetAttribute("Temporary", true)

		row.Activated:Connect(function()
			if currentUseMode == "Wear" then
				CartController:UseDescription(outfit.description)
			else
				OutfitSelected:Fire(outfit.description)
			end
		end)

		row.Delete.Activated:Connect(function()
			local confirmed = ConfirmUI:Confirm(ConfirmUI.Confirmations.DeleteOutfit):Await()
			if confirmed then
				DataEvents.DeleteOutfit:FireServer(dataOutfit.name, dataOutfit.description)
			end
		end)

		row.Parent = template.Parent

		RenderOutfitToViewport(row.ImageFrame.Frame.OutfitImage, dataOutfit.description)
	end
end

function RenderWearing()
	ClearResults()

	local list = gui.RightPane.Marketplace.Results.ListWrapper.List
	list.NewOutfit.Visible = false

	local template = list.ItemWrapper
	template.Visible = false

	local cart = CartController:GetCartItems()

	local function renderItem(
		layoutOrder: number,
		id: number,
		equipped: boolean,
		type: Types.StandType | Enum.BodyPart,
		shopOwner: number?
	)
		local item = template:Clone()

		item.ImageFrame.Frame.ItemImage.Image = Thumbs.GetAsset(id)

		item.Visible = true
		item:SetAttribute("Temporary", true)
		item.LayoutOrder = layoutOrder -- so most recent additions are at the top, and body parts are at the bottom
		item.UIStroke.Enabled = equipped

		item.Activated:Connect(function()
			-- Toggle equip
			if currentUseMode == "Wear" then
				item.UIStroke.Enabled = not item.UIStroke.Enabled
				if typeof(type) ~= "EnumItem" then
					if type == "Accessory" then
						CartController:ToggleEquipped(id)
					else
						CartController:ToggleClassicClothing(id, type)
					end
				elseif typeof(type) == "EnumItem" then
					CartController:EquipBodyPart(type, if item.UIStroke.Enabled then id else nil, shopOwner)
				end
			elseif currentUseMode == "Select" and typeof(type) ~= "EnumItem" then
				ItemSelected:Fire(id, type)
			end
		end)

		item.Buy.Activated:Connect(function()
			PurchaseEvents.Asset:FireServer(id, shopOwner)
		end)

		item.Parent = template.Parent

		DataFetch.GetItemDetails(id, Players.LocalPlayer):After(function(details)
			if item.Parent == nil then
				return
			end

			local owned = if details then (details.owned or false) else false
			item.Owned.Visible = owned

			local price = if details and details.price then tostring(details.price) else nil
			item.Buy.Visible = not owned and CartController:IsEquipped(id) and price ~= nil

			if price then
				item.Buy.TextLabel.Text = price
			end

			if not details then
				return
			end

			item.IsLimited.Visible = details.limited ~= nil
		end)
	end

	for i, cartItem in ipairs(cart) do
		local order = (if cartItem.bodyPart then 1000 else 0) + #cart - i
		renderItem(
			order,
			cartItem.id,
			cartItem.equipped,
			if cartItem.bodyPart then cartItem.bodyPart else "Accessory",
			cartItem.shopOwner
		)
	end

	for clothing, item in CartController:GetClassicClothing() do
		renderItem(-100, item.id, item.equipped, clothing :: Types.StandType)
	end
end

function PopulateResults()
	if currentMode == "Marketplace" then
		SearchCatalog()
	elseif currentSubcategory == "Wearing" then
		RenderWearing()
	elseif currentSubcategory == "Outfits" then
		RenderOutfits()
	end
end

local function CreateNewOutfit()
	return Future.new(function()
		local outfitName = ConfirmUI:RequestInput(ConfirmUI.InputRequests.CreateOutfit):Await()
		if not outfitName then
			return
		end

		DataEvents.CreateOutfit:FireServer(
			outfitName,
			HumanoidDescription.Serialize(CartController:GetDescription():Await())
		)
	end)
end

function SwitchSubCategory(newCategory: SubCategory)
	if newCategory == currentSubcategory then
		return
	end

	-- Clear out unequipped items when switching tabs
	if currentSubcategory == "Wearing" then
		print("Clearing unequipped")
		CartController:ClearUnequippedItems()
	end

	currentSubcategory = newCategory
	PopulateResults()
	RenderSubcategories()
end

function RenderSubcategories()
	local list = gui.RightPane.Marketplace.Categories.Frame.List
	for i, child in list:GetChildren() do
		if child:GetAttribute("Temporary") then
			child:Destroy()
		end
	end

	local template = list.Template
	template.Visible = false
	local subCategories = categories[currentMode][currentCategory]

	local selected

	for subCategory, _ in subCategories do
		local header = template:Clone()
		header.Visible = true
		header.Name = subCategory
		header.TextLabel.Text = subCategory

		if subCategory == currentSubcategory then
			header.TextLabel.TextColor3 = Color3.fromRGB(10, 132, 255)
			selected = header
		else
			header.TextLabel.TextColor3 = Color3.fromRGB(162, 162, 162)
		end

		header.LayoutOrder = assert(
			clothingOrder[subCategory]
				or accessoryOrder[subCategory]
				or wearingOrder[subCategory]
				or charactersOrder[subCategory],
			`No order found for: {subCategory}`
		)

		header.Activated:Connect(function()
			SwitchSubCategory(subCategory)
		end)
		header:SetAttribute("Temporary", true)

		header.Parent = template.Parent
	end

	local middle = list.AbsolutePosition.X + (list.AbsoluteSize.X / 2)
	local currentPosition = selected.AbsolutePosition.X + (selected.AbsoluteSize.X / 2)
	local delta = currentPosition - middle
	local newPosition = list.CanvasPosition + Vector2.new(delta, 0)

	TweenService:Create(
		list,
		TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ CanvasPosition = newPosition }
	):Play()
end

function RenderCategories()
	local tabs = gui.RightPane.Marketplace.Tabs.Categories.List

	type Header = typeof(tabs.Accessories)

	local function RenderHeader(header: Header)
		header.Visible = true

		if header.Name == currentCategory then
			header.BackgroundTransparency = 0
			header.ItemImage.ImageTransparency = 0
			header.TextLabel.TextTransparency = 0
		elseif not categories[currentMode][header.Name] then
			header.Visible = false
		else
			header.BackgroundTransparency = 1
			header.ItemImage.ImageTransparency = 0.8
			header.TextLabel.TextTransparency = 0.8
		end
	end

	RenderHeader(tabs.Accessories)
	RenderHeader(tabs.Clothing)
	RenderHeader(tabs.Body)
	RenderHeader(tabs.Characters)
	RenderHeader(tabs.Wearing)
end

function SwitchCategory(newCategory: Category)
	if newCategory == currentCategory then
		return
	end

	currentCategory = newCategory
	if newCategory == "Accessories" then
		SwitchSubCategory("Hair")
	elseif newCategory == "Clothing" then
		SwitchSubCategory("Jackets")
	elseif newCategory == "Characters" then
		SwitchSubCategory("Characters")
	elseif newCategory == "Wearing" then
		SwitchSubCategory("Wearing")
	else
		error(`Invalid category passed: {newCategory}`)
	end

	RenderCategories()
end

function SwitchMode(newMode: DisplayMode)
	if newMode == currentMode then
		return
	end
	local switcher = gui.RightPane.Switcher
	local overlay = gui.RightPane.Overlay

	currentMode = newMode
	if newMode == "Marketplace" then
		SwitchCategory("Clothing")
		overlay.Visible = true
	elseif newMode == "Inventory" then
		SwitchCategory("Wearing")
		overlay.Visible = false
	elseif newMode == "OutfitPane" then
		return
	else
		error("Mode not registered!")
	end

	type Switcher = typeof(switcher.Inventory)
	local function RenderSwitcher(switcher: Switcher)
		local selected = switcher.Name == currentMode
		if selected then
			switcher.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			switcher.BackgroundTransparency = 0
		else
			switcher.BackgroundTransparency = 1
		end

		switcher.DeselectedIcon.Visible = not selected
		switcher.SelectedIcon.Visible = selected
	end

	RenderSwitcher(switcher.Marketplace)
	RenderSwitcher(switcher.Inventory)
end

function HandleResultsScrolled()
	local results = gui.RightPane.Marketplace.Results.ListWrapper.List

	-- The position of the bottom of the results relative to how much has been scrolled
	local bottomPosition = results.CanvasPosition.Y + results.AbsoluteSize.Y

	if
		bottomPosition < (results.AbsoluteCanvasSize.Y * 0.8) - 50 -- allow for some leeway
		or currentlySearching
		or not searchPages
		or searchPages.IsFinished
	then
		return
	end

	ReadNextPage()
end

local outfitPaneTracker = newproxy()
local outfitBinAdd, outfitBinRemove = Bin()
function HideOutfitPreviewPage()
	gui.RightPane.Marketplace.Visible = true
	gui.RightPane.Switcher.Visible = true
	gui.RightPane.Controls.Reset.Visible = true
	gui.RightPane.Outfit.Visible = false

	outfitPaneTracker = newproxy()
	outfitBinRemove()
end

function RenderOutfitPreviewPage(outfit: HumanoidDescription, shopOwner: number?)
	return Future.new(function(outfit: HumanoidDescription, shopOwner: number?)
		local tracker = newproxy()
		outfitPaneTracker = tracker
		outfitBinRemove()

		local outfitUI = gui.RightPane.Outfit

		outfitUI.Visible = true
		gui.RightPane.Switcher.Visible = false
		gui.RightPane.Controls.Reset.Visible = false
		gui.RightPane.Marketplace.Visible = false

		local currentDescription = CartController:GetDescription():Await()
		if outfitPaneTracker ~= tracker then
			return
		end

		local partialDescription = HumanoidDescription.WithAccessories(currentDescription, outfit)

		local currentButton = outfitUI.Previews.Current
		local partialButton = outfitUI.Previews.Partial

		-- If body parts don't change, we don't need this partial button
		partialButton.Visible = not HumanoidDescription.FuzzyEq(partialDescription, outfit)

		local fullButton = outfitUI.Previews.Full

		currentButton.UIStroke.Enabled = true

		RenderOutfitToViewport(
			currentButton.ImageFrame.Frame.OutfitImage,
			HumanoidDescription.Serialize(currentDescription)
		)

		RenderOutfitToViewport(
			partialButton.ImageFrame.Frame.OutfitImage,
			HumanoidDescription.Serialize(partialDescription)
		)

		RenderOutfitToViewport(fullButton.ImageFrame.Frame.OutfitImage, HumanoidDescription.Serialize(outfit))

		local function ApplyOnClicked(button: GuiButton, description: HumanoidDescription)
			outfitBinAdd(button.Activated:Connect(function()
				CartController:UseDescription(description, shopOwner)
			end))
		end

		ApplyOnClicked(currentButton, currentDescription)
		ApplyOnClicked(partialButton, partialDescription)
		ApplyOnClicked(fullButton, outfit)

		local itemSet: { string | Enum.BodyPart } = {}
		for i, accessory in currentDescription:GetAccessories(true) do
			itemSet[accessory.AssetId] = "Accessory"
		end
		for i, accessory in outfit:GetAccessories(true) do
			itemSet[accessory.AssetId] = "Accessory"
		end
		for i, partEnum in Enum.BodyPart:GetEnumItems() :: { Enum.BodyPart } do
			local currentId = (currentDescription :: any)[partEnum.Name]
			local outfitId = (outfit :: any)[partEnum.Name]
			if currentId ~= 0 then
				itemSet[currentId] = partEnum
			end
			if outfitId ~= 0 then
				itemSet[outfitId] = partEnum
			end
		end

		local function addClothing(description: HumanoidDescription)
			if description.GraphicTShirt ~= 0 then
				itemSet[description.GraphicTShirt] = "TShirt"
			end
			if description.Shirt ~= 0 then
				itemSet[description.Shirt] = "Shirt"
			end
			if description.Pants ~= 0 then
				itemSet[description.Pants] = "Pants"
			end
		end
		addClothing(currentDescription)
		addClothing(outfit)

		if outfitPaneTracker ~= tracker then
			return
		end

		for i, itemElement in outfitUI.Wearing.ListWrapper.List:GetChildren() do
			if itemElement:GetAttribute("Temporary") then
				itemElement:Destroy()
			end
		end

		local itemTemplate = gui.RightPane.Marketplace.Results.ListWrapper.List.ItemWrapper
		for id, itemType in itemSet do
			local itemElement = itemTemplate:Clone()

			itemElement.Visible = true
			itemElement.Buy.Visible = false
			itemElement.Owned.Visible = false
			itemElement:SetAttribute("Temporary", true)
			itemElement:SetAttribute("AssetId", id)
			itemElement:SetAttribute("Purchaseable", typeof(itemType) == "string")
			itemElement.ImageFrame.Frame.ItemImage.Image = Thumbs.GetAsset(id)

			local layoutOrder
			if typeof(itemType) == "string" then
				if itemType == "Accessory" then
					layoutOrder = 0
				else
					layoutOrder = -100
				end
			else
				layoutOrder = 1000
			end
			itemElement.LayoutOrder = layoutOrder

			itemElement.Activated:Connect(function()
				if itemType == "Accessory" then
					CartController:ToggleInCart(id, shopOwner)
				elseif itemType == "TShirt" or itemType == "Shirt" or itemType == "Pants" then
					CartController:ToggleClassicClothing(id, itemType, shopOwner)
				else
					assert(typeof(itemType) == "EnumItem")
					if itemElement.UIStroke.Enabled then
						CartController:EquipBodyPart(itemType, nil, shopOwner)
					else
						CartController:EquipBodyPart(itemType, id, shopOwner)
					end
				end
			end)

			itemElement.Buy.Activated:Connect(function()
				PurchaseEvents.Asset:FireServer(id, shopOwner)
			end)

			itemElement.Parent = outfitUI.Wearing.ListWrapper.List

			DataFetch.GetItemDetails(id, Players.LocalPlayer):After(function(details)
				if not details or itemElement.Parent == nil then
					return
				end

				itemElement.IsLimited.Visible = details.limited ~= nil
				if itemType == "Accessory" then
					itemElement.Buy.Visible = not details.owned and CartController:IsInCart(id) and details.price ~= nil
					itemElement.Buy.TextLabel.Text = if details.price then tostring(details.price) else "N/A"
				end
				itemElement.Owned.Visible = details.owned or false
				itemElement:SetAttribute("Owned", details.owned)
			end)
		end

		local function RenderEquipped()
			for i, itemElement in outfitUI.Wearing.ListWrapper.List:GetChildren() :: { typeof(itemTemplate) } do
				if itemElement:GetAttribute("Temporary") then
					local inCart = CartController:IsEquipped(itemElement:GetAttribute("AssetId"))
					local owned = itemElement:GetAttribute("Owned")

					itemElement.UIStroke.Enabled = inCart
					if owned ~= nil then
						itemElement.Buy.Visible = not owned and inCart and itemElement:GetAttribute("Purchaseable")
					end
				end
			end

			local updatedDescription = CartController:GetDescription():Await()

			-- Use fuzzy here as the order may differ between applied outfit, and rendered outfit, after selecting it.
			currentButton.UIStroke.Enabled = HumanoidDescription.FuzzyEq(currentDescription, updatedDescription)
			partialButton.UIStroke.Enabled = HumanoidDescription.FuzzyEq(partialDescription, updatedDescription)
			fullButton.UIStroke.Enabled = HumanoidDescription.FuzzyEq(outfit, updatedDescription)
		end

		RenderEquipped()
		if outfitPaneTracker ~= tracker then
			return
		end
		outfitBinAdd(CartController.CartUpdated:Connect(RenderEquipped))
	end, outfit, shopOwner)
end

local renderTrack = newproxy()
function RenderPreviewPane(description: HumanoidDescription)
	return Future.new(function(description: HumanoidDescription)
		local tracker = newproxy()
		renderTrack = tracker

		local replicatedModel = CharacterCache:LoadWithDescription(description):Await()
		if not replicatedModel then
			warn("Received nil character model from server.")
			return
		end

		if renderTrack ~= tracker then
			-- Overwritten by a new render request
			return
		end

		-- Need to clone as the original model gets destroyed
		local model = replicatedModel:Clone()
		replicatedModel:Destroy()
		model.Name = "CharacterModel"

		local existingModel = studio:FindFirstChild(model.Name)
		if existingModel then
			existingModel:Destroy()
		end

		local HRP = model:FindFirstChild("HumanoidRootPart") :: BasePart
		local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

		-- Silences "exception while signaling: Must be a LuaSourceContainer" error
		local animateScript = model:FindFirstChild("Animate") :: LocalScript?
		if animateScript then
			animateScript.Enabled = false -- just destroying didn't work, need to disable first.
			animateScript:Destroy()
		end

		-- Allow accessories to attach
		model:PivotTo(studioStand.CFrame + Vector3.new(0, humanoid.HipHeight + (HRP.Size.Y / 2), 0))
		HRP.Anchored = true
		model.Parent = studio

		-- Must only play after parenting to workspace
		local newTrack = animator:LoadAnimation(idleAnimation)
		newTrack:Play(0)
		if currentIdleTrack then
			newTrack.TimePosition = currentIdleTrack.TimePosition
		end

		currentIdleTrack = newTrack
	end, description)
end

local delayedSearchTask: thread? = nil
function HandleSearchUpdated()
	if delayedSearchTask then
		task.cancel(delayedSearchTask)
	end

	delayedSearchTask = task.delay(1, function()
		PopulateResults()
	end)
end

function HandleSearched()
	if delayedSearchTask then
		task.cancel(delayedSearchTask)
		delayedSearchTask = nil
	end
	PopulateResults()
end

function ToggleSearch()
	local search = gui.RightPane.Overlay.Search
	local searchAction = gui.RightPane.Overlay.Actions.Search
	search.Visible = not search.Visible
	searchAction.ItemImage.Visible = not search.Visible
	searchAction.Close.Visible = search.Visible

	if not search.Visible then
		search.Search.Search.Text = ""
	elseif Device() == "PC" then
		search.Search.Search:CaptureFocus()
	end
end

function ToggleFilter()
	local filter = gui.RightPane.Overlay.Filter
	local filterAction = gui.RightPane.Overlay.Actions.Filter
	filter.Visible = not filter.Visible
	filterAction.ItemImage.Visible = not filter.Visible
	filterAction.Close.Visible = filter.Visible
end

function HandleReset()
	local confirmed = ConfirmUI:Confirm(ConfirmUI.Confirmations.ResetAvatar):Await()
	if not confirmed then
		return
	end

	CartController:Reset()
end

function CatalogUI:Hide()
	-- Toggles visibility off
	if gui.Visible then
		CatalogUI:Display(currentMode, currentUseMode)
	end
end

function CatalogUI:DisplayOutfit(outfit: HumanoidDescription)
	CatalogUI:Display("OutfitPane", "Wear", false)
	RenderOutfitPreviewPage(outfit)
end

function CatalogUI:Display(mode: DisplayMode, useMode: UseMode, previewDisabled: boolean?)
	if currentMode == "OutfitPane" then
		HideOutfitPreviewPage()
	end

	local cam = workspace.CurrentCamera
	currentUseMode = useMode

	if mode ~= "OutfitPane" then
		gui.RightPane.Marketplace.Visible = true
	else
		gui.RightPane.Marketplace.Visible = false
	end

	if mode == currentMode and (previewDisabled == nil or (previewDisabled == not previewing)) then
		local visible = not gui.Visible
		gui.Visible = visible
	else
		-- Switching modes, so make sure it is visible.
		gui.Visible = true
	end

	CatalogUI.VisibilityUpdated:Fire(gui.Visible)

	-- This can occasionally error
	pcall(function()
		StarterGui:SetCore("TopbarEnabled", not gui.Visible)
	end)

	-- UI should never be enabled before the character has loaded.
	if Loaded:HasCharacterLoaded() then
		UILoader:GetMain().Enabled = not gui.Visible
	end

	if gui.Visible and not previewDisabled then
		cam.CameraType = Enum.CameraType.Scriptable
		cam.FieldOfView = 20
		previewing = true
	else
		cam.CameraType = Enum.CameraType.Custom
		cam.FieldOfView = 80
		previewing = false
	end

	if not gui.Visible then
		return
	end

	SwitchMode(mode)

	if not previewDisabled then
		local leftCentre = gui.RightPane.AbsolutePosition.X / 2 -- get centre of the left side of the screen
		local offCentreProportion = leftCentre / (cam.ViewportSize.X / 2)
		local horizontalFov = cam.FieldOfView * cam.ViewportSize.X / cam.ViewportSize.Y
		local angleDifference = offCentreProportion * (horizontalFov / 3)

		cam.CFrame = studioCamera.CFrame * CFrame.Angles(0, -math.rad(angleDifference), 0)
	end
end

local selectTracker = newproxy()
function CatalogUI:SelectItem()
	return Future.new(function(): { id: number, type: Types.StandType }?
		local tracker = newproxy()
		selectTracker = tracker
		CatalogUI:Hide()

		CatalogUI:Display("Marketplace", "Select", true)

		local selectedId: number? = nil
		local selectedType: Types.StandType? = nil
		local parentThread = coroutine.running()
		local selectedThread: thread
		local visibilityThread: thread

		selectedThread = task.spawn(function()
			selectedId, selectedType = ItemSelected:Wait()
			task.cancel(visibilityThread)
			coroutine.resume(parentThread)
		end)

		visibilityThread = task.spawn(function()
			gui:GetPropertyChangedSignal("Visible"):Wait()
			task.cancel(selectedThread)
			coroutine.resume(parentThread)
		end)

		coroutine.yield()

		if selectTracker == tracker then
			CatalogUI:Hide()

			if selectedId and selectedType then
				return {
					id = selectedId,
					type = selectedType,
				}
			else
				return nil
			end
		else
			return nil
		end
	end)
end

function CatalogUI:SelectOutfit()
	return Future.new(function(): HumanoidDescription?
		local tracker = newproxy()
		selectTracker = tracker
		CatalogUI:Hide()

		CatalogUI:Display("Inventory", "Select", true)
		SwitchSubCategory("Outfits")

		local selectedOutfit: HumanoidDescription? = nil
		local parentThread = coroutine.running()
		local selectedThread: thread
		local visibilityThread: thread

		selectedThread = task.spawn(function()
			selectedOutfit = OutfitSelected:Wait()
			task.cancel(visibilityThread)
			coroutine.resume(parentThread)
		end)

		visibilityThread = task.spawn(function()
			gui:GetPropertyChangedSignal("Visible"):Wait()
			task.cancel(selectedThread)
			coroutine.resume(parentThread)
		end)

		coroutine.yield()

		if selectTracker == tracker then
			CatalogUI:Hide()

			return selectedOutfit
		else
			return nil
		end
	end)
end

function CatalogUI:IsDisplayed()
	return gui.Visible
end

function CatalogUI:Initialize()
	CatalogUI:Hide()

	local categoryHeaders = gui.RightPane.Marketplace.Tabs.Categories.List

	for i, header in categoryHeaders:GetChildren() do
		if header:IsA("TextButton") then
			header.Activated:Connect(function()
				SwitchCategory(header.Name :: Category)
			end)
		end
	end

	gui.RightPane.Switcher.Marketplace.Activated:Connect(function()
		SwitchMode("Marketplace")
	end)
	gui.RightPane.Switcher.Inventory.Activated:Connect(function()
		SwitchMode("Inventory")
	end)

	gui.RightPane.Overlay.Actions.Search.Activated:Connect(ToggleSearch)
	gui.RightPane.Overlay.Actions.Filter.Activated:Connect(ToggleFilter)

	gui.RightPane.Overlay.Search.Search.Search:GetPropertyChangedSignal("Text"):Connect(HandleSearchUpdated)
	gui.RightPane.Overlay.Search.Search.Search.ReturnPressedFromOnScreenKeyboard:Connect(HandleSearched)
	gui.RightPane.Overlay.Search.Search.Search.FocusLost:Connect(HandleSearched)

	local function RenderOutline(textBox: TextBox & {
		UIStroke: UIStroke,
	})
		textBox:GetPropertyChangedSignal("Text"):Connect(function()
			textBox.UIStroke.Enabled = textBox.Text ~= ""
		end)
	end

	gui.RightPane.Overlay.Filter.Visible = false
	local filter = gui.RightPane.Overlay.Filter.Search

	RenderOutline(filter.Bottom.Max)
	RenderOutline(filter.Bottom.Min)
	RenderOutline(filter.Top.Creator)

	filter.Bottom.Filter.Activated:Connect(CycleSort)
	filter.Bottom.OffSale.Activated:Connect(ToggleIncludeOffSale)
	filter.Top.Creator.Toggle.Activated:Connect(CycleCreator)
	filter.Top.IsLimited.Activated:Connect(ToggleLimiteds)

	filter.Bottom.Max:GetPropertyChangedSignal("Text"):Connect(HandleSearchUpdated)
	filter.Bottom.Min:GetPropertyChangedSignal("Text"):Connect(HandleSearchUpdated)
	filter.Top.Creator:GetPropertyChangedSignal("Text"):Connect(HandleSearchUpdated)

	gui.RightPane.Controls.Close.Activated:Connect(CatalogUI.Hide)
	gui.RightPane.Controls.Reset.Activated:Connect(HandleReset)

	gui.RightPane.Marketplace.Results.ListWrapper.List
		:GetPropertyChangedSignal("CanvasPosition")
		:Connect(HandleResultsScrolled)

	gui.RightPane.Marketplace.Results.ListWrapper.List.NewOutfit.Activated:Connect(CreateNewOutfit)

	CartController.CartUpdated:Connect(function(items: { CartController.CartItem })
		CartController:GetDescription():After(function(description)
			RenderPreviewPane(description)
		end)

		if currentSubcategory == "Wearing" then
			RenderWearing()
		end
	end)

	DataController.Updated:Connect(function()
		if currentSubcategory == "Outfits" then
			PopulateResults()
		end
	end)

	-- Do initial render
	RenderCategories()
	RenderSubcategories()
	PopulateResults()
end

CatalogUI:Initialize()

return CatalogUI

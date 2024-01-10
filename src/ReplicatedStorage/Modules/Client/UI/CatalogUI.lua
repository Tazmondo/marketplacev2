local CatalogUI = {}
local AvatarEditorService = game:GetService("AvatarEditorService")
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

local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)
local Device = require(ReplicatedStorage.Modules.Client.Device)
local Loaded = require(ReplicatedStorage.Modules.Client.Loaded)
local PurchaseAssetEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.PurchaseAssetEvent):Client()

type DisplayMode = "Marketplace" | "Inventory"

type ClothingCategory = "Dresses & Skirts" | "Jackets" | "Shirts" | "Shorts" | "Pants" | "Sweaters" | "T-Shirts"
type AccessoryCategory = "Back" | "Face" | "Front" | "Head" | "Hair" | "Neck" | "Waist" | "Shoulder"
type SubCategory = ClothingCategory | AccessoryCategory | "Current" | "Outfits"
type SearchResult = {
	Id: number,
	Name: string,
	Price: number?,
	CreatorType: "User" | "Group",
	AssetType: string?,
}

type Category = "Clothing" | "Accessories" | "Wearing"

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
}

local wearingOrder = {
	Current = 1,
	Outfits = 2,
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
	},
	Inventory = {
		Wearing = {
			Current = true,
			Outfits = true,
		},
	},
}

local animationFolder = ReplicatedStorage.Assets.Animations
local idleAnimation = animationFolder.Idle
local currentIdleTrack: AnimationTrack? = nil

local currentMode: DisplayMode = "Marketplace"

local currentCategory: Category = "Clothing"
local currentSubcategory: SubCategory = "Jackets"

local searchIdentifier = newproxy() -- Used so old searches dont overwrite new ones
local searchPages: CatalogPages? = nil
local currentlySearching = false
local currentResults: { SearchResult } = {}

local studio = assert(workspace:FindFirstChild("Studio"), "Could not find studio in workspace.") :: Model
local studioCamera =
	assert(studio:FindFirstChild("StudioCamera"), "Studio did not have a StudioCamera part.") :: BasePart
studioCamera.Transparency = 1
local studioStand = assert(studio:FindFirstChild("StudioStand"), "Studio did not have a stand part.") :: BasePart

local gui = UILoader:GetCatalog().Catalog

function RefreshResults()
	local list = gui.RightPane.Marketplace.Results.ListWrapper.List
	for i, child in list:GetChildren() do
		if child:GetAttribute("Temporary") then
			child:Destroy()
		end
	end

	local template = list.ItemWrapper
	template.Visible = false

	for i, result in currentResults do
		local item = template:Clone()
		item.Name = "item"
		item:SetAttribute("Temporary", true)
		item.Visible = true
		item.ImageFrame.Frame.ItemImage.Image = Thumbs.GetAsset(result.Id)

		if CartController:IsInCart(result.Id) then
			item.Buy.Visible = true
			item.Buy.TextLabel.Text = tostring(result.Price)
			item.Buy.Activated:Connect(function()
				PurchaseAssetEvent:Fire(result.Id)
			end)
			item.UIStroke.Enabled = true
		else
			item.UIStroke.Enabled = false
			item.Buy.Visible = false
		end

		-- using .Activated here doesnt work on mobile
		item.MouseButton1Down:Connect(function()
			CartController:ToggleInCart(result.Id)
			RefreshResults()
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
	if not searchPages or searchPages.IsFinished then
		return
	end

	local filteredItems = {}

	local items = searchPages:GetCurrentPage() :: { SearchResult }
	for i, item in items do
		if item.AssetType and DataFetch.IsAssetTypeValid(item.AssetType) then
			table.insert(filteredItems, item)
		end
	end

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

function SearchCatalog()
	ClearResults()
	if currentMode ~= "Marketplace" then
		return
	end

	local identifier = newproxy()
	searchIdentifier = identifier
	currentlySearching = true

	local overlay = gui.RightPane.Overlay

	-- types for this instance are incorrect
	local paramsInstance: any = CatalogSearchParams.new()
	paramsInstance.SearchKeyword = overlay.Search.Search.Search.Text

	local currentAssetType: Enum.AvatarAssetType? = categories[currentMode][currentCategory][currentSubcategory]

	if currentAssetType then
		paramsInstance.AssetTypes = { currentAssetType }
	end

	print("Searching...")

	task.spawn(function()
		local success, pages = pcall(function()
			return AvatarEditorService:SearchCatalog(paramsInstance)
		end)

		if not success or identifier ~= searchIdentifier then
			return
		end
		searchPages = pages
		currentlySearching = false
		ProcessPage()
	end)
end

function RenderInventory()
	ClearResults()
	if currentMode ~= "Inventory" then
		return
	end

	local list = gui.RightPane.Marketplace.Results.ListWrapper.List

	local template = list.ItemWrapper
	template.Visible = false

	local cart = CartController:GetCart()

	for i, cartItem in cart do
		local item = template:Clone()

		item.ImageFrame.Frame.ItemImage.Image = Thumbs.GetAsset(cartItem.id)

		item.Visible = true
		item:SetAttribute("Temporary", true)
		item.LayoutOrder = #cart - i -- so most recent additions are at the top
		item.UIStroke.Enabled = cartItem.equipped

		-- Toggle equip
		item.Activated:Connect(function()
			item.UIStroke.Enabled = not item.UIStroke.Enabled
			CartController:ToggleEquipped(cartItem.id)
		end)

		item.Parent = template.Parent

		DataFetch.GetItemDetails(cartItem.id, Players.LocalPlayer):After(function(details)
			local owned = if details then (details.owned or false) else false
			item.Owned.Visible = owned
			item.Buy.Visible = not owned

			if not details then
				return
			end

			item.IsLimited.Visible = details.limited ~= nil
		end)
	end
end

local function PopulateResults()
	if currentMode == "Marketplace" then
		SearchCatalog()
	elseif currentSubcategory == "Current" then
		RenderInventory()
	end
end

function SwitchSubCategory(newCategory: SubCategory)
	if newCategory == currentSubcategory then
		return
	end

	print(currentSubcategory, newCategory)
	-- Clear out unequipped items when switching tabs
	if currentSubcategory == "Current" then
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
			clothingOrder[subCategory] or accessoryOrder[subCategory] or wearingOrder[subCategory],
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
	elseif newCategory == "Wearing" then
		SwitchSubCategory("Current")
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

local renderTrack = newproxy()
function RenderPreviewPane(accessories: { number })
	return Future.new(function(accessories: { number })
		local tracker = newproxy()
		renderTrack = tracker

		local success, replicatedModel = AvatarEvents.GenerateModel:Call(accessories):Await()
		if not success or not replicatedModel then
			if not success then
				warn(replicatedModel)
			else
				warn("Received nil character model from server.")
			end
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

		local existingModel = studio:FindFirstChild("CharacterModel")
		if existingModel then
			existingModel:Destroy()
		end

		local HRP = model:FindFirstChild("HumanoidRootPart") :: BasePart
		local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

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
	end, accessories)
end

local delayedSearchTask: thread? = nil
function HandleSearchUpdated()
	if delayedSearchTask then
		task.cancel(delayedSearchTask)
	end

	delayedSearchTask = task.delay(1.5, function()
		SearchCatalog()
	end)
end

function HandleSearched()
	if delayedSearchTask then
		task.cancel(delayedSearchTask)
		delayedSearchTask = nil
	end
	SearchCatalog()
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
		CatalogUI:Display(currentMode)
	end
end

function CatalogUI:Display(mode: DisplayMode, previewDisabled: boolean?)
	local cam = workspace.CurrentCamera

	if mode == currentMode then
		local visible = not gui.Visible
		gui.Visible = visible
	else
		-- Switching modes, so make sure it is visible.
		gui.Visible = true
	end

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
	else
		cam.CameraType = Enum.CameraType.Custom
		cam.FieldOfView = 80
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

	gui.RightPane.Controls.Close.Activated:Connect(CatalogUI.Hide)
	gui.RightPane.Controls.Reset.Activated:Connect(HandleReset)

	gui.RightPane.Marketplace.Results.ListWrapper.List
		:GetPropertyChangedSignal("CanvasPosition")
		:Connect(HandleResultsScrolled)

	CartController.CartUpdated:Connect(function(items: { CartController.CartItem })
		RenderPreviewPane(CartController:GetEquippedIds())
		if currentSubcategory == "Current" then
			RenderInventory()
		end
	end)

	-- Do initial render
	RenderCategories()
	RenderSubcategories()
	SearchCatalog()
end

CatalogUI:Initialize()

return CatalogUI

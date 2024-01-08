local CatalogUI = {}
local AvatarEditorService = game:GetService("AvatarEditorService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local CartController = require(ReplicatedStorage.Modules.Client.CartController)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Future = require(ReplicatedStorage.Packages.Future)
local UILoader = require(script.Parent.UILoader)

local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)
local PurchaseAssetEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.PurchaseAssetEvent):Client()

type DisplayMode = "Marketplace" | "Outfit"

type ClothingCategory = "Dresses & Skirts" | "Jackets" | "Shirts" | "Shorts" | "Pants" | "Sweaters" | "T-Shirts"
type AccessoryCategory = "Back" | "Face" | "Front" | "Head" | "Hair" | "Neck" | "Waist" | "Shoulder"
type SearchResult = {
	Id: number,
	Name: string,
	Price: number?,
	CreatorType: "User" | "Group",
	AssetType: string?,
}

type Category = "Clothing" | "Accessories"

local accessoryCategories: { [AccessoryCategory]: Enum.AvatarAssetType } = {
	Back = Enum.AvatarAssetType.BackAccessory,
	Face = Enum.AvatarAssetType.FaceAccessory,
	Front = Enum.AvatarAssetType.FrontAccessory,
	Head = Enum.AvatarAssetType.Hat,
	Hair = Enum.AvatarAssetType.HairAccessory,
	Neck = Enum.AvatarAssetType.NeckAccessory,
	Waist = Enum.AvatarAssetType.WaistAccessory,
	Shoulder = Enum.AvatarAssetType.ShoulderAccessory,
}

local clothingCategories: { [ClothingCategory]: Enum.AvatarAssetType } = {
	["Dresses & Skirts"] = Enum.AvatarAssetType.DressSkirtAccessory,
	Jackets = Enum.AvatarAssetType.JacketAccessory,
	Shirts = Enum.AvatarAssetType.ShirtAccessory,
	Shorts = Enum.AvatarAssetType.ShortsAccessory,
	Pants = Enum.AvatarAssetType.PantsAccessory,
	Sweaters = Enum.AvatarAssetType.SweaterAccessory,
	["T-Shirts"] = Enum.AvatarAssetType.TShirtAccessory,
}

local currentMode: DisplayMode = "Marketplace"
local currentCategory: Category = "Accessories"
local currentSubcategory: ClothingCategory | AccessoryCategory = "Waist"

local searchIdentifier = newproxy() -- Used so old searches dont overwrite new ones
local searchPages: CatalogPages? = nil
local currentResults: { SearchResult } = {}

local gui = UILoader:GetCatalog().Catalog

local function RefreshResults()
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

		item.Activated:Connect(function()
			CartController:ToggleInCart(result.Id)
			RefreshResults()
		end)

		item.Parent = list

		DataFetch.PlayerOwnsAsset(result.Id, Players.LocalPlayer):After(function(owned)
			if item.Parent == nil then
				return
			end

			if owned then
				item.Buy.Visible = false
				item.Owned.Visible = true
			end
		end)
	end
end

local function AddSearchResults(results: { SearchResult })
	for i, result in results do
		table.insert(currentResults, result)
	end

	RefreshResults()
end

local function ClearResults()
	currentResults = {}
	searchPages = nil
	RefreshResults()
end

local function SearchCatalog()
	ClearResults()

	local identifier = newproxy()
	searchIdentifier = identifier

	-- todo: add filters
	local paramsInstance: any = CatalogSearchParams.new()

	local currentAssetType: Enum.AvatarAssetType? = accessoryCategories[currentSubcategory :: AccessoryCategory]
		or clothingCategories[currentSubcategory :: ClothingCategory]

	if currentAssetType then
		paramsInstance.AssetTypes = { currentAssetType }
	end

	task.spawn(function()
		local success, pages = pcall(function()
			return AvatarEditorService:SearchCatalog(paramsInstance)
		end)

		if not success or identifier ~= searchIdentifier then
			return
		end

		local filteredItems = {}

		local items = pages:GetCurrentPage() :: { SearchResult }
		for i, item in items do
			if item.AssetType and DataFetch.IsAssetTypeValid(item.AssetType) then
				table.insert(filteredItems, item)
			end
		end

		AddSearchResults(filteredItems)
	end)
end

local function GetAccessoryTableForCategory(
	category: Category
): { [ClothingCategory | AccessoryCategory]: Enum.AvatarAssetType }
	if category == "Clothing" then
		return clothingCategories
	elseif category == "Accessories" then
		return accessoryCategories
	else
		error(`Invalid category provided! {category}`)
	end
end

local function RenderSubcategories()
	local list = gui.RightPane.Marketplace.Categories.Frame.List
	for i, child in list:GetChildren() do
		if child:GetAttribute("Temporary") then
			child:Destroy()
		end
	end

	local template = list.Template
	template.Visible = false
	local subCategories = GetAccessoryTableForCategory(currentCategory)

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

		header.Activated:Connect(function()
			currentSubcategory = subCategory :: any
			SearchCatalog()
			RenderSubcategories()
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

local function RenderCategories()
	local tabs = gui.RightPane.Marketplace.Tabs.Categories.List

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
end

local function SwitchCategory(newCategory: Category)
	if newCategory == currentCategory then
		return
	end

	if newCategory == "Accessories" then
		currentCategory = "Accessories"
		currentSubcategory = "Waist"
	elseif newCategory == "Clothing" then
		currentCategory = "Clothing"
		currentSubcategory = "Shorts"
	else
		error(`Invalid category passed: {newCategory}`)
	end

	RenderCategories()
	RenderSubcategories()
	SearchCatalog()
end

local function RenderPreviewPane(accessories: { number })
	return Future.new(function(accessories: { number })
		local success, replicatedModel = AvatarEvents.GenerateModel:Call(accessories):Await()
		if not success or not replicatedModel then
			if not success then
				warn(replicatedModel)
			else
				warn("Received nil character model from server.")
			end
			return
		end

		-- Need to clone as the original model gets destroyed
		local model = replicatedModel:Clone()
		replicatedModel:Destroy()

		local CAMERA_OFFSET = CFrame.new(
			-19.3596764,
			5.94872379,
			-26.8514004,
			-0.81115222,
			0.077896364,
			-0.579624236,
			-5.26325294e-08,
			0.99108994,
			0.133193776,
			0.584835112,
			0.108040452,
			-0.803924799
		)
		local CAMERA_FOV = 20

		local viewport = gui.LeftPane.Preview.ViewportFrame
		local camera = viewport.CurrentCamera or Instance.new("Camera", viewport)
		viewport.CurrentCamera = camera
		camera.FieldOfView = CAMERA_FOV

		local existingModel = viewport:FindFirstChildOfClass("Model")
		if existingModel then
			existingModel:Destroy()
		end

		-- Allow accessories to attach
		model:PivotTo(CFrame.new(0, -200, 0))
		model.Parent = workspace
		RunService.Heartbeat:Wait()

		model.Parent = viewport
		camera.CFrame = model:GetPivot():ToWorldSpace(CAMERA_OFFSET)
	end, accessories)
end

function CatalogUI:Hide()
	-- Toggles visibility off
	CatalogUI:Display(currentMode)
end

function CatalogUI:Display(mode: DisplayMode, previewDisabled: boolean?)
	if mode == currentMode then
		local visible = not gui.Visible
		gui.Visible = visible
	else
		-- Switching modes, so make sure it is visible.
		gui.Visible = true
	end

	StarterGui:SetCore("TopbarEnabled", not gui.Visible)

	if not gui.Visible then
		return
	end

	gui.LeftPane.Visible = not (previewDisabled or false)
	gui.RightPane.Close.Visible = not gui.LeftPane.Visible -- only show rightpane close if leftpane is not open
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

	gui.RightPane.Close.Activated:Connect(CatalogUI.Hide)
	gui.LeftPane.Close.Activated:Connect(CatalogUI.Hide)

	CartController.CartUpdated:Connect(RenderPreviewPane)

	-- Do initial render
	RenderCategories()
	RenderSubcategories()
	SearchCatalog()
end

CatalogUI:Initialize()

return CatalogUI

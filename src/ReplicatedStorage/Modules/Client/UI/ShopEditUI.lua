-- Sorry this code is ugly, but it gets the job done.

local ShopEditUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataEvents = require(ReplicatedStorage.Events.DataEvents)
local ConfirmUI = require(script.Parent.ConfirmUI)
local ProfileUI = require(script.Parent.ProfileUI)
local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local Base36 = require(ReplicatedStorage.Modules.Shared.Base36)
local ShopSettingsUI = require(script.Parent.ShopSettingsUI)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain().ControllerEdit

local activeShop: Types.Shop? = nil
local selectedTexture: string? = nil

ShopEditUI.ShopSelected = Signal() :: Signal.Signal<Data.Shop>

local function SelectButton(button: Instance?, visible: boolean)
	local wrapper = gui.Wrapper
	for i, v in wrapper:GetChildren() do
		local outline = v:FindFirstChild("SelectedOutline") :: UIStroke?
		if outline then
			if v == button and visible then
				outline.Enabled = true
			else
				outline.Enabled = false
			end
		end
	end
end

local function SelectFrame(frame: Instance?)
	local ret = false

	for i, v in gui:GetChildren() do
		if v.Name == "Wrapper" or not v:IsA("Frame") then
			continue
		end

		if v == frame then
			v.Visible = not v.Visible
			ret = v.Visible
		else
			v.Visible = false
		end
	end

	ShopSettingsUI:Close()

	return ret
end

local function TogglePrimaryColor()
	local visible = SelectFrame(gui.PrimaryColorPicker)
	SelectButton(gui.Wrapper.CurrentPrimaryColor, visible)
end

local function ToggleAccentColor()
	local visible = SelectFrame(gui.AccentColorPicker)
	SelectButton(gui.Wrapper.CurrentAccentColor, visible)
end

local function ToggleTexture()
	local visible = SelectFrame(gui.TexturePicker)
	SelectButton(gui.Wrapper.CurrentTexture, visible)
end

local function ToggleLayoutFrame()
	local visible = SelectFrame(gui.LayoutPicker)
	SelectButton(gui.Wrapper.CurrentLayout, visible)
end

local function ToggleStorefrontFrame()
	local visible = SelectFrame(gui.StorefrontPicker)
	SelectButton(gui.Wrapper.Storefront, visible)
end

local function ToggleShareFrame()
	local visible = SelectFrame(gui.ShareLink)
	SelectButton(gui.Wrapper.Share, visible)
end

local function ShowSettings()
	if ShopSettingsUI:IsOpen() then
		ShopSettingsUI:Close()
		SelectButton(gui.Wrapper.ShopSettings, false)
	else
		if not activeShop then
			return
		end

		SelectFrame()
		ShopSettingsUI:Display(activeShop)
		SelectButton(gui.Wrapper.ShopSettings, true)
	end
end

local function UpdatePrimaryColourPickerSelection(color: Color3)
	for i, child in gui.PrimaryColorPicker:GetChildren() do
		if child:IsA("ImageButton") then
			local outline = assert(child:FindFirstChild("SelectedOutline"), "Button did not have outline") :: UIStroke
			outline.Enabled = child.BackgroundColor3 == color
		end
	end
end

local function UpdateAccentColourPickerSelection(color: Color3)
	for i, child in gui.AccentColorPicker:GetChildren() do
		if child:IsA("ImageButton") then
			local outline = assert(child:FindFirstChild("SelectedOutline"), "Button did not have outline") :: UIStroke
			outline.Enabled = child.BackgroundColor3 == color
		end
	end
end

local function UpdateTextureSelection(texture: string)
	for i, child in gui.TexturePicker:GetChildren() do
		if child:IsA("ImageButton") then
			local outline = assert(child:FindFirstChild("SelectedOutline"), "Button did not have outline") :: UIStroke
			local enabled = child.Name == texture
			outline.Enabled = enabled

			if enabled then
				gui.Wrapper.CurrentTexture.Image = child.Image
			end
		end
	end
end

local function UpdateLayoutSelection(layoutId: string)
	for i, layout in gui.LayoutPicker.ScrollingFrame:GetChildren() do
		if layout:IsA("ImageButton") then
			local outline = assert(layout:FindFirstChild("SelectedOutline"), "Layout did not have outline") :: UIStroke
			outline.Enabled = layout.Name == layoutId
		end
	end
end

local function UpdateStorefrontSelection(storefrontId: string)
	for i, storefront in gui.StorefrontPicker.ScrollingFrame:GetChildren() do
		if storefront:IsA("ImageButton") then
			local outline =
				assert(storefront:FindFirstChild("SelectedOutline"), "Layout did not have outline") :: UIStroke
			outline.Enabled = storefront.Name == storefrontId
		end
	end
end

local function Update()
	if not activeShop or not selectedTexture then
		return
	end

	ShopEvents.UpdateSettings:FireServer({
		name = activeShop.name,
		primaryColor = gui.Wrapper.CurrentPrimaryColor.BackgroundColor3,
		accentColor = gui.Wrapper.CurrentAccentColor.BackgroundColor3,
		thumbId = activeShop.thumbId,
		logoId = activeShop.logoId,
		texture = selectedTexture,
	})
end

local function PickPrimaryColor(color: Color3)
	gui.Wrapper.CurrentPrimaryColor.BackgroundColor3 = color
	UpdatePrimaryColourPickerSelection(color)
	Update()
end

local function PickAccentColor(color: Color3)
	gui.Wrapper.CurrentAccentColor.BackgroundColor3 = color
	UpdateAccentColourPickerSelection(color)
	Update()
end

local function PickTexture(texture: string)
	UpdateTextureSelection(texture)
	selectedTexture = texture
	Update()
end

function ShopEditUI:Hide()
	gui.Visible = false
	activeShop = nil
	selectedTexture = nil
	ShopSettingsUI:Close()
end

local function RenderShareFrame(shareCode: number?)
	local frame = gui.ShareLink
	if shareCode then
		frame.TextBox.Visible = true
		frame.TextBox.Text = Base36.Encode(shareCode)
		frame.Generate.Visible = false
	else
		frame.Generate.Visible = true
		frame.TextBox.Visible = false
	end
end

local function GenerateShareCode(guid: string)
	return Future.new(function()
		local frame = gui.ShareLink

		frame.Generate.TextLabel.Text = "Generating..."
		frame.Generate.Active = false
		frame.Generate.AutoButtonColor = false

		local success, code = DataEvents.GenerateShareCode:Call(guid):Await()

		frame.Generate.TextLabel.Text = "Generate"
		frame.Generate.Active = true
		frame.Generate.AutoButtonColor = true

		if not success then
			return
		end

		RenderShareFrame(code)
	end)
end

function ShopEditUI:Display(shop: Types.Shop)
	activeShop = shop
	selectedTexture = shop.texture

	gui.Visible = true
	gui.Wrapper.CurrentPrimaryColor.BackgroundColor3 = shop.primaryColor
	gui.Wrapper.CurrentAccentColor.BackgroundColor3 = shop.accentColor

	UpdatePrimaryColourPickerSelection(shop.primaryColor)
	UpdateAccentColourPickerSelection(shop.accentColor)
	UpdateTextureSelection(shop.texture)
	UpdateLayoutSelection(shop.layoutId)
	RenderShareFrame(shop.shareCode)
end

local function SwitchLayout(id: LayoutData.LayoutId)
	return Future.new(function()
		if not activeShop then
			return
		end

		local filledStands = TableUtil.Filter(activeShop.stands, function(stand)
			return stand.item ~= nil
		end)
		local filledOutfits = TableUtil.Filter(activeShop.outfitStands, function(outfit)
			return outfit.description ~= nil
		end)

		-- Don't need to show switch prompt if the shop is not filled in at all.
		if #filledStands + #filledOutfits > 0 then
			local confirmed = ConfirmUI:Confirm(ConfirmUI.Confirmations.SwitchLayout):Await()
			if not confirmed then
				return
			end
		end

		UpdateLayoutSelection(id)
		ShopEvents.UpdateLayout:FireServer(id)
	end)
end

local function SwitchStorefront(id: LayoutData.StorefrontId)
	UpdateStorefrontSelection(id)
	ShopEvents.UpdateStorefront:FireServer(id)
end

local function OpenShops()
	ProfileUI:SelectShop():After(function(shop)
		if not shop then
			return
		end
		ShopEditUI.ShopSelected:Fire(shop)
	end)
end

-- Should only be called once
local function PopulateLayoutFrame()
	local frame = gui.LayoutPicker.ScrollingFrame
	local template = frame.Layout
	template.Visible = false
	local layouts = Layouts:GetLayouts()

	for id, layout in layouts do
		local newLayout = template:Clone()
		newLayout.Visible = true
		newLayout.Image = `rbxassetid://{layout.displayThumbId}`
		newLayout.Name = id

		newLayout.Activated:Connect(function()
			SwitchLayout(layout.id)
		end)

		if id == Config.DefaultLayout then
			newLayout.LayoutOrder = -1
		end

		newLayout.Parent = frame
	end
end

local function PopulateStorefrontFrame()
	local frame = gui.StorefrontPicker.ScrollingFrame
	local template = frame.Layout
	template.Visible = false
	local storefronts = Layouts:GetStorefronts()

	for id, storefront in storefronts do
		local newStorefront = template:Clone()
		newStorefront.Visible = true
		newStorefront.Image = `rbxassetid://{storefront.displayThumbId}`
		newStorefront.Name = id

		newStorefront.Activated:Connect(function()
			SwitchStorefront(storefront.id)
		end)

		newStorefront.Parent = frame
	end
end

function ShopEditUI:Initialize()
	gui.Visible = false
	SelectFrame()
	SelectButton(nil, false)

	gui.Wrapper.CurrentPrimaryColor.Activated:Connect(TogglePrimaryColor)
	gui.Wrapper.CurrentAccentColor.Activated:Connect(ToggleAccentColor)
	gui.Wrapper.CurrentTexture.Activated:Connect(ToggleTexture)
	gui.Wrapper.CurrentLayout.Activated:Connect(ToggleLayoutFrame)
	gui.Wrapper.Storefront.Activated:Connect(ToggleStorefrontFrame)
	gui.Wrapper.ShopSettings.Activated:Connect(ShowSettings)
	gui.Wrapper.Share.Activated:Connect(ToggleShareFrame)
	gui.Wrapper.Profile.Activated:Connect(OpenShops)

	gui.ShareLink.Generate.Activated:Connect(function()
		if activeShop then
			GenerateShareCode(activeShop.GUID)
		end
	end)

	PopulateLayoutFrame()
	PopulateStorefrontFrame()

	-- Not the prettiest but gets the job done
	for i, child in gui.PrimaryColorPicker:GetChildren() do
		if child:IsA("ImageButton") then
			child.Activated:Connect(function()
				PickPrimaryColor(child.BackgroundColor3)
			end)
		end
	end

	for i, child in gui.AccentColorPicker:GetChildren() do
		if child:IsA("ImageButton") then
			child.Activated:Connect(function()
				PickAccentColor(child.BackgroundColor3)
			end)
		end
	end

	for i, child in gui.TexturePicker:GetChildren() do
		if child:IsA("ImageButton") then
			child.Activated:Connect(function()
				PickTexture(child.Name)
			end)
		end
	end

	-- Make sure all the colors in the color picker are actually valid
	for i, child in gui.PrimaryColorPicker:GetChildren() do
		if child:IsA("ImageButton") then
			local color = child.BackgroundColor3
			if not Config.PrimaryColors[color:ToHex()] then
				warn("Invalid primary color found in color picker:", child:GetFullName())
			end
		end
	end

	for i, child in gui.AccentColorPicker:GetChildren() do
		if child:IsA("ImageButton") then
			local color = child.BackgroundColor3
			if not Config.AccentColors[color:ToHex()] then
				warn("Invalid accent color found in color picker:", child:GetFullName())
			end
		end
	end
end

ShopEditUI:Initialize()

return ShopEditUI

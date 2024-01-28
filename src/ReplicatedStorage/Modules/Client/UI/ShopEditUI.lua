-- Sorry this code is ugly, but it gets the job done.

local ShopEditUI = {}

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileUI = require(script.Parent.ProfileUI)
local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local ShopSettingsUI = require(script.Parent.ShopSettingsUI)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Base64 = require(ReplicatedStorage.Packages.Base64)
local Signal = require(ReplicatedStorage.Packages.Signal)
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

local function GenerateDeeplink(ownerId: number, GUID: string)
	local data: Types.LaunchData = {
		ownerId = ownerId,
		GUID = GUID,
	}
	local json = HttpService:JSONEncode(data)
	local b64 = Base64.encode(json)

	return `https://www.roblox.com/games/start?placeId={game.PlaceId}&launchData={b64}`
end

function ShopEditUI:Display(shop: Types.Shop)
	activeShop = shop
	selectedTexture = shop.texture

	gui.Visible = true
	gui.Wrapper.CurrentPrimaryColor.BackgroundColor3 = shop.primaryColor
	gui.Wrapper.CurrentAccentColor.BackgroundColor3 = shop.accentColor

	gui.ShareLink.TextBox.Text = GenerateDeeplink(shop.owner, shop.GUID)

	UpdatePrimaryColourPickerSelection(shop.primaryColor)
	UpdateAccentColourPickerSelection(shop.accentColor)
	UpdateTextureSelection(shop.texture)
	UpdateLayoutSelection(shop.layoutId)
end

local function SwitchLayout(id: LayoutData.LayoutId)
	UpdateLayoutSelection(id)
	ShopEvents.UpdateLayout:FireServer(id)
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

function ShopEditUI:Initialize()
	gui.Visible = false
	SelectFrame()
	SelectButton(nil, false)

	gui.Wrapper.CurrentPrimaryColor.Activated:Connect(TogglePrimaryColor)
	gui.Wrapper.CurrentAccentColor.Activated:Connect(ToggleAccentColor)
	gui.Wrapper.CurrentTexture.Activated:Connect(ToggleTexture)

	gui.Wrapper.CurrentLayout.Activated:Connect(ToggleLayoutFrame)
	gui.Wrapper.ShopSettings.Activated:Connect(ShowSettings)
	gui.Wrapper.Profile.Activated:Connect(OpenShops)

	PopulateLayoutFrame()

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

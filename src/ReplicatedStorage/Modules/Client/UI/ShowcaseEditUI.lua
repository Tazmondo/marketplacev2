-- Sorry this code is ugly, but it gets the job done.

local ShowcaseEditUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShowcaseNavigationUI = require(script.Parent.ShowcaseNavigationUI)
local ShowcaseSettingsUI = require(script.Parent.ShowcaseSettingsUI)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local UILoader = require(script.Parent.UILoader)

local UpdateShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.UpdateShowcaseEvent):Client()

local gui = UILoader:GetMain().ControllerEdit

local activeShowcase: Types.NetworkShowcase? = nil

function TogglePrimaryColor()
	gui.PrimaryColorPicker.Visible = not gui.PrimaryColorPicker.Visible
	gui.Wrapper.CurrentPrimaryColor.SelectedOutline.Enabled = gui.PrimaryColorPicker.Visible
	gui.Wrapper.CurrentAccentColor.SelectedOutline.Enabled = false
	gui.Wrapper.CurrentTexture.SelectedOutline.Enabled = false

	gui.AccentColorPicker.Visible = false
	gui.TexturePicker.Visible = false
end

function ToggleAccentColor()
	gui.AccentColorPicker.Visible = not gui.AccentColorPicker.Visible
	gui.Wrapper.CurrentAccentColor.SelectedOutline.Enabled = gui.AccentColorPicker.Visible
	gui.Wrapper.CurrentPrimaryColor.SelectedOutline.Enabled = false
	gui.Wrapper.CurrentTexture.SelectedOutline.Enabled = false

	gui.PrimaryColorPicker.Visible = false
	gui.TexturePicker.Visible = false
end

function ToggleTexture()
	gui.TexturePicker.Visible = not gui.TexturePicker.Visible
	gui.Wrapper.CurrentTexture.SelectedOutline.Enabled = gui.TexturePicker.Visible
	gui.Wrapper.CurrentAccentColor.SelectedOutline.Enabled = false
	gui.Wrapper.CurrentPrimaryColor.SelectedOutline.Enabled = false

	gui.PrimaryColorPicker.Visible = false
	gui.AccentColorPicker.Visible = false
end

function PickPrimaryColor(color: Color3)
	gui.Wrapper.CurrentPrimaryColor.BackgroundColor3 = color
	UpdatePrimaryColourPickerSelection(color)
	Update()
end

function PickAccentColor(color: Color3)
	gui.Wrapper.CurrentAccentColor.BackgroundColor3 = color
	UpdateAccentColourPickerSelection(color)
	Update()
end

function UpdatePrimaryColourPickerSelection(color: Color3)
	for i, child in gui.PrimaryColorPicker:GetChildren() do
		if child:IsA("ImageButton") then
			local outline = assert(child:FindFirstChild("SelectedOutline"), "Button did not have outline") :: UIStroke
			outline.Enabled = child.BackgroundColor3 == color
		end
	end
end

function UpdateAccentColourPickerSelection(color: Color3)
	for i, child in gui.AccentColorPicker:GetChildren() do
		if child:IsA("ImageButton") then
			local outline = assert(child:FindFirstChild("SelectedOutline"), "Button did not have outline") :: UIStroke
			outline.Enabled = child.BackgroundColor3 == color
		end
	end
end

function Update()
	if not activeShowcase then
		return
	end

	UpdateShowcaseEvent:Fire({
		type = "UpdateSettings",
		name = activeShowcase.name,
		primaryColor = gui.Wrapper.CurrentPrimaryColor.BackgroundColor3,
		accentColor = gui.Wrapper.CurrentAccentColor.BackgroundColor3,
		thumbId = activeShowcase.thumbId,
	})
end

function ShowSettings()
	if ShowcaseSettingsUI:IsOpen() then
		ShowcaseSettingsUI:Close()
	else
		if not activeShowcase then
			return
		end

		ShowcaseSettingsUI:Display(activeShowcase)
	end
end

function Exit()
	ShowcaseNavigationUI:RejoinPlace()
end

function ShowcaseEditUI:Hide()
	gui.Visible = false
	activeShowcase = nil
end

function ShowcaseEditUI:Display(showcase: Types.NetworkShowcase)
	activeShowcase = showcase
	gui.Visible = true
	gui.Wrapper.CurrentPrimaryColor.BackgroundColor3 = showcase.primaryColor
	gui.Wrapper.CurrentAccentColor.BackgroundColor3 = showcase.accentColor

	gui.ShareLink.TextBox.Text = Util.GenerateDeeplink(showcase.owner, showcase.GUID)

	UpdatePrimaryColourPickerSelection(showcase.primaryColor)
	UpdateAccentColourPickerSelection(showcase.accentColor)
end

function ToggleShareFrame()
	gui.ShareLink.Visible = not gui.ShareLink.Visible
end

function ShowcaseEditUI:Initialize()
	gui.Visible = false
	gui.PrimaryColorPicker.Visible = false
	gui.AccentColorPicker.Visible = false
	gui.TexturePicker.Visible = false
	gui.ShareLink.Visible = false

	gui.Wrapper.CurrentPrimaryColor.Activated:Connect(TogglePrimaryColor)
	gui.Wrapper.CurrentAccentColor.Activated:Connect(ToggleAccentColor)
	gui.Wrapper.CurrentTexture.Activated:Connect(ToggleTexture)

	gui.Wrapper.ShopSettings.Activated:Connect(ShowSettings)
	gui.Wrapper.ShareLink.Activated:Connect(ToggleShareFrame)
	gui.Wrapper.Exit.Activated:Connect(Exit)

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

ShowcaseEditUI:Initialize()

return ShowcaseEditUI

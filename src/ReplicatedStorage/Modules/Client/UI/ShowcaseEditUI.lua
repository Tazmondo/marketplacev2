-- Sorry this code is ugly. It's not that complicated though.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local StringUtil = require(ReplicatedStorage.Modules.Shared.StringUtil)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local UILoader = require(script.Parent.UILoader)
local ShowcaseEditUI = {}

local gui = UILoader:GetMain().ControllerEdit

local activeShowcase: Types.NetworkShowcase? = nil

ShowcaseEditUI.UpdatePrimaryColor = Signal()
ShowcaseEditUI.UpdateAccentColor = Signal()
ShowcaseEditUI.UpdateTexture = Signal()
ShowcaseEditUI.UpdateName = Signal()
ShowcaseEditUI.Exit = Signal()

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
	ShowcaseEditUI.UpdatePrimaryColor:Fire(color)
	gui.Wrapper.CurrentPrimaryColor.BackgroundColor3 = color
	UpdatePrimaryColourPickerSelection(color)
end

function PickAccentColor(color: Color3)
	ShowcaseEditUI.UpdateAccentColor:Fire(color)
	gui.Wrapper.CurrentAccentColor.BackgroundColor3 = color
	UpdateAccentColourPickerSelection(color)
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

function Exit()
	ShowcaseEditUI.Exit:Fire()
end

function UpdateName()
	if not activeShowcase then
		return
	end

	local name = StringUtil.LimitString(gui.Wrapper.TextBox.Text, Config.MaxPlaceNameLength)
	if #name == 0 then
		gui.Wrapper.TextBox.Text = activeShowcase.name
		return
	end
	gui.Wrapper.TextBox.Text = name

	ShowcaseEditUI.UpdateName:Fire(name)
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
	gui.Wrapper.TextBox.Text = showcase.name

	UpdatePrimaryColourPickerSelection(showcase.primaryColor)
	UpdateAccentColourPickerSelection(showcase.accentColor)
end

function ShowcaseEditUI:Initialize()
	gui.Visible = false
	gui.PrimaryColorPicker.Visible = false
	gui.AccentColorPicker.Visible = false
	gui.TexturePicker.Visible = false

	gui.Wrapper.CurrentPrimaryColor.Activated:Connect(TogglePrimaryColor)
	gui.Wrapper.CurrentAccentColor.Activated:Connect(ToggleAccentColor)
	gui.Wrapper.CurrentTexture.Activated:Connect(ToggleTexture)

	gui.Wrapper.Exit.Activated:Connect(Exit)
	gui.Wrapper.TextBox.FocusLost:Connect(UpdateName)

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

-- Sorry this code is ugly, but it gets the job done.

local ShowcaseEditUI = {}

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShowcaseEvents = require(ReplicatedStorage.Events.ShowcaseEvents)
local ShowcaseNavigationUI = require(script.Parent.ShowcaseNavigationUI)
local ShowcaseSettingsUI = require(script.Parent.ShowcaseSettingsUI)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Base64 = require(ReplicatedStorage.Packages.Base64)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain().ControllerEdit

local activeShowcase: Types.NetworkShowcase? = nil
local selectedTexture: string? = nil

function SelectButton(button: Instance?, visible: boolean)
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

function SelectFrame(frame: Instance?)
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

	ShowcaseSettingsUI:Close()

	return ret
end

function TogglePrimaryColor()
	local visible = SelectFrame(gui.PrimaryColorPicker)
	SelectButton(gui.Wrapper.CurrentPrimaryColor, visible)
end

function ToggleAccentColor()
	local visible = SelectFrame(gui.AccentColorPicker)
	SelectButton(gui.Wrapper.CurrentAccentColor, visible)
end

function ToggleTexture()
	local visible = SelectFrame(gui.TexturePicker)
	SelectButton(gui.Wrapper.CurrentTexture, visible)
end

function ToggleLayoutFrame()
	local visible = SelectFrame(gui.LayoutPicker)
	SelectButton(gui.Wrapper.CurrentLayout, visible)
end

function ToggleShareFrame()
	local visible = SelectFrame(gui.ShareLink)
	SelectButton(gui.Wrapper.ShareLink, visible)
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

function PickTexture(texture: string)
	UpdateTextureSelection(texture)
	selectedTexture = texture
	Update()
end

function ShowSettings()
	if ShowcaseSettingsUI:IsOpen() then
		ShowcaseSettingsUI:Close()
		SelectButton(gui.Wrapper.ShopSettings, false)
	else
		if not activeShowcase then
			return
		end

		SelectFrame()
		ShowcaseSettingsUI:Display(activeShowcase)
		SelectButton(gui.Wrapper.ShopSettings, true)
	end
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

function UpdateTextureSelection(texture: string)
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

function UpdateLayoutSelection(layoutId: string)
	for i, layout in gui.LayoutPicker.ScrollingFrame:GetChildren() do
		if layout:IsA("ImageButton") then
			local outline = assert(layout:FindFirstChild("SelectedOutline"), "Layout did not have outline") :: UIStroke
			outline.Enabled = layout.Name == layoutId
		end
	end
end

function Update()
	if not activeShowcase or not selectedTexture then
		return
	end

	ShowcaseEvents.UpdateSettings:FireServer({
		name = activeShowcase.name,
		primaryColor = gui.Wrapper.CurrentPrimaryColor.BackgroundColor3,
		accentColor = gui.Wrapper.CurrentAccentColor.BackgroundColor3,
		thumbId = activeShowcase.thumbId,
		logoId = activeShowcase.logoId,
		texture = selectedTexture,
	})
end

function Exit()
	ShowcaseNavigationUI:RejoinPlace()
end

function ShowcaseEditUI:Hide()
	gui.Visible = false
	activeShowcase = nil
	selectedTexture = nil
end

function GenerateDeeplink(ownerId: number, GUID: string)
	local data: Types.LaunchData = {
		ownerId = ownerId,
		GUID = GUID,
	}
	local json = HttpService:JSONEncode(data)
	local b64 = Base64.encode(json)

	return `https://www.roblox.com/games/start?placeId={game.PlaceId}&launchData={b64}`
end

function ShowcaseEditUI:Display(showcase: Types.NetworkShowcase)
	activeShowcase = showcase
	selectedTexture = showcase.texture

	gui.Visible = true
	gui.Wrapper.CurrentPrimaryColor.BackgroundColor3 = showcase.primaryColor
	gui.Wrapper.CurrentAccentColor.BackgroundColor3 = showcase.accentColor

	gui.ShareLink.TextBox.Text = GenerateDeeplink(showcase.owner, showcase.GUID)

	UpdatePrimaryColourPickerSelection(showcase.primaryColor)
	UpdateAccentColourPickerSelection(showcase.accentColor)
	UpdateTextureSelection(showcase.texture)
	UpdateLayoutSelection(showcase.layoutId)
end

function SwitchLayout(id: LayoutData.LayoutId)
	UpdateLayoutSelection(id)
	ShowcaseEvents.UpdateLayout:FireServer(id)
end

-- Should only be called once
function PopulateLayoutFrame()
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

		if id == Layouts:GetDefaultLayoutId() then
			newLayout.LayoutOrder = -1
		end

		newLayout.Parent = frame
	end
end

function ShowcaseEditUI:Initialize()
	gui.Visible = false
	SelectFrame()
	SelectButton(nil, false)

	gui.Wrapper.CurrentPrimaryColor.Activated:Connect(TogglePrimaryColor)
	gui.Wrapper.CurrentAccentColor.Activated:Connect(ToggleAccentColor)
	gui.Wrapper.CurrentTexture.Activated:Connect(ToggleTexture)

	gui.Wrapper.CurrentLayout.Activated:Connect(ToggleLayoutFrame)
	gui.Wrapper.ShopSettings.Activated:Connect(ShowSettings)
	gui.Wrapper.ShareLink.Activated:Connect(ToggleShareFrame)
	gui.Wrapper.Exit.Activated:Connect(Exit)

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

ShowcaseEditUI:Initialize()

return ShowcaseEditUI

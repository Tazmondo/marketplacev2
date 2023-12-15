local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local StringUtil = require(ReplicatedStorage.Modules.Shared.StringUtil)
local Signal = require(ReplicatedStorage.Packages.Signal)
local UILoader = require(script.Parent.UILoader)
local ShowcaseEditUI = {}

local gui = UILoader:GetMain().ControllerEdit

ShowcaseEditUI.UpdateColour = Signal()
ShowcaseEditUI.UpdateName = Signal()
ShowcaseEditUI.Exit = Signal()

function ToggleColorPicker()
	gui.ColorPicker.Visible = not gui.ColorPicker.Visible
end

function PickColour(color: Color3)
	ShowcaseEditUI.UpdateColour:Fire(color)
	gui.ColorPicker.Visible = false
end

function Exit()
	ShowcaseEditUI.Exit:Fire()
end

function UpdateName()
	local name = StringUtil.LimitString(gui.Wrapper.TextBox.Text, Config.MaxPlaceNameLength)
	gui.Wrapper.TextBox.Text = name

	ShowcaseEditUI.UpdateName:Fire(name)
end

function ShowcaseEditUI:Hide()
	gui.Visible = false
end

function ShowcaseEditUI:Display()
	gui.Visible = true
end

function ShowcaseEditUI:Initialize()
	gui.Visible = false
	gui.ColorPicker.Visible = false

	gui.Wrapper.CurrentColor.Activated:Connect(ToggleColorPicker)
	gui.Wrapper.Exit.Activated:Connect(Exit)
	gui.Wrapper.TextBox.FocusLost:Connect(UpdateName)

	for i, child in gui.ColorPicker:GetChildren() do
		if child:IsA("ImageButton") then
			child.Activated:Connect(function()
				PickColour(child.BackgroundColor3)
			end)
		end
	end
end

ShowcaseEditUI:Initialize()

return ShowcaseEditUI

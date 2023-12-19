local AddItemUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain().AddItemID

local current: Vector3? = nil

AddItemUI.Added = Signal()

function AddItemUI:Display(roundedPosition: Vector3, currentId: number?)
	gui.Visible = true
	current = roundedPosition
	gui.Frame.TextBox.Text = if currentId then tostring(currentId) else ""
end

function AddItemUI:Hide()
	gui.Visible = false
	current = nil
end

function Add()
	if not current then
		return
	end

	local assetId = tonumber(gui.Frame.TextBox.Text)
	AddItemUI.Added:Fire(current, assetId)
	AddItemUI:Hide()
end

function AddItemUI:Initialize()
	gui.Visible = false

	gui.Frame.Actions.Add.Activated:Connect(Add)
	gui.Title.Close.ImageButton.Activated:Connect(AddItemUI.Hide)
end

AddItemUI:Initialize()

return AddItemUI

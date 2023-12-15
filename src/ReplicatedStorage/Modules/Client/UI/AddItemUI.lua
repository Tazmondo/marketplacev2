local AddItemUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain().AddItemID

local currentStand: BasePart? = nil

AddItemUI.Added = Signal()

function AddItemUI:Display(stand: BasePart)
	gui.Visible = true
	currentStand = stand
end

function AddItemUI:Hide()
	gui.Visible = false
	currentStand = nil
end

function Add()
	if not currentStand then
		return
	end

	local assetId = tonumber(gui.Frame.TextBox.Text)
	AddItemUI.Added:Fire(currentStand, assetId)
	AddItemUI:Hide()
end

function AddItemUI:Initialize()
	gui.Visible = false

	gui.Frame.Actions.Add.Activated:Connect(Add)
	gui.Title.Close.ImageButton.Activated:Connect(AddItemUI.Hide)
end

AddItemUI:Initialize()

return AddItemUI

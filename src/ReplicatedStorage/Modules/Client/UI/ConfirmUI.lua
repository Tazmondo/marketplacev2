local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfirmUI = {}

local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)
local UILoader = require(script.Parent.UILoader)

type Confirmation = {
	Title: string,
	Content: string,
	Proceed: string?,
	Cancel: string?,
}

ConfirmUI.Confirmations = {
	ResetAvatar = {
		Title = "Reset Avatar",
		Content = "Resetting your avatar will remove all items added to your avatar",
		Proceed = "Reset",
	} :: Confirmation,
}

local confirmationFrame = UILoader:GetConfirm().Confirm
local showing = false
local finishedSignal = Signal()

function ConfirmUI:Confirm(confirmation: Confirmation)
	return Future.new(function(): boolean
		if showing then
			return false
		end
		showing = true

		confirmationFrame.Title.Text = confirmation.Title
		confirmationFrame.Body.Text = confirmation.Content
		confirmationFrame.Actions.PrimaryButton.TextLabel.Text = confirmation.Proceed or "Proceed"
		confirmationFrame.Actions.SecondaryButton.TextLabel.Text = confirmation.Cancel or "Cancel"

		confirmationFrame.Visible = true

		local result = finishedSignal:Wait()
		showing = false
		confirmationFrame.Visible = false
		return result
	end)
end

function ConfirmUI:Initialize()
	confirmationFrame.Visible = false

	confirmationFrame.Actions.PrimaryButton.Activated:Connect(function()
		finishedSignal:Fire(true)
	end)

	confirmationFrame.Actions.SecondaryButton.Activated:Connect(function()
		finishedSignal:Fire(false)
	end)
end

ConfirmUI:Initialize()

return ConfirmUI

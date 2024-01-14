local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfirmUI = {}

local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)
local UILoader = require(script.Parent.UILoader)

type Confirmation = {
	Title: string,
	Content: string,
	Proceed: string,
	Cancel: string,
}

type InputRequest = {
	Title: string,
	PlaceholderText: string,
	Proceed: string,
	Cancel: string,
}

ConfirmUI.Confirmations = {
	ResetAvatar = {
		Title = "Reset Avatar",
		Content = "Resetting your avatar will remove all items added to your avatar",
		Proceed = "Reset",
		Cancel = "Cancel",
	} :: Confirmation,
}

ConfirmUI.InputRequests = {
	CreateOutfit = {
		Title = "Create Outfit",
		PlaceholderText = "Add a name...",
		Proceed = "Create",
		Cancel = "Cancel",
	} :: InputRequest,
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

		confirmationFrame.Input.Visible = false
		confirmationFrame.Body.Visible = true

		confirmationFrame.Title.Text = confirmation.Title
		confirmationFrame.Body.Text = confirmation.Content
		confirmationFrame.Actions.PrimaryButton.TextLabel.Text = confirmation.Proceed
		confirmationFrame.Actions.SecondaryButton.TextLabel.Text = confirmation.Cancel

		confirmationFrame.Visible = true

		local result = finishedSignal:Wait()
		showing = false
		confirmationFrame.Visible = false
		return result
	end)
end

function ConfirmUI:RequestInput(inputRequest: InputRequest)
	return Future.new(function(): string?
		if showing then
			return nil
		end
		showing = true

		local textInput = confirmationFrame.Input.TextInput

		confirmationFrame.Input.Visible = true
		confirmationFrame.Body.Visible = false
		confirmationFrame.Input.TextInput.Text = ""

		confirmationFrame.Title.Text = inputRequest.Title
		textInput.PlaceholderText = inputRequest.PlaceholderText
		confirmationFrame.Actions.PrimaryButton.TextLabel.Text = inputRequest.Proceed
		confirmationFrame.Actions.SecondaryButton.TextLabel.Text = inputRequest.Cancel

		confirmationFrame.Visible = true

		while true do
			local result = finishedSignal:Wait()
			if result and textInput.Text == "" then
				continue
			end
			showing = false
			confirmationFrame.Visible = false

			return if result then textInput.Text else nil
		end
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

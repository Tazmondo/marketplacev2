print("Initialize command controller")

local CommandController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

function CommandController.Initialize()
	local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient")) :: any -- booo bad module, shouldnt have to cast this
	Cmdr:SetActivationKeys({ Enum.KeyCode.Semicolon })
	Cmdr:SetEnabled(false)
	task.spawn(function()
		while Players.LocalPlayer:GetAttribute("Cmdr_Admin") == nil do
			Players.LocalPlayer:GetAttributeChangedSignal("Cmdr_Admin"):Wait()
		end
		Cmdr:SetEnabled(Players.LocalPlayer:GetAttribute("Cmdr_Admin"))
	end)

	TextChatService.SendingMessage:Connect(function(message)
		if message.Text:lower() == "cmdr" then
			Cmdr:Toggle()
		end
	end)
end

task.spawn(CommandController.Initialize)

return CommandController

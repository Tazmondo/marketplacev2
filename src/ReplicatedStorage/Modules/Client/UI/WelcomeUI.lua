local WelcomeUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UILoader = require(script.Parent.UILoader)
local DataController = require(ReplicatedStorage.Modules.Client.DataController)

local gui = UILoader:GetMain().Welcome

function WelcomeUI:Initialize()
	gui.Visible = false
	gui.Frame.Actions.PrimaryButton.Activated:Connect(function()
		gui.Visible = false
	end)

	task.spawn(function()
		local data = DataController:GetData():Await()

		if data.firstTime then
			gui.Visible = true
		end
	end)
end

WelcomeUI:Initialize()

return WelcomeUI

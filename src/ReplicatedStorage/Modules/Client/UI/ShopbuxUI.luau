local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataController = require(ReplicatedStorage.Modules.Client.DataController)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local UILoader = require(script.Parent.UILoader)
local ShopbuxUI = {}

local gui = UILoader:GetNavigation().Nav2.Shopbux
gui.Visible = false

local function HandleUpdate(data: Data.Data)
	gui.Frame.Amount.Text = tostring(data.shopbux)
end

local function Initialize()
	DataController:GetData():After(function(data)
		gui.Visible = true
		HandleUpdate(data)
		DataController.Updated:Connect(HandleUpdate)
	end)
end

Initialize()

return ShopbuxUI

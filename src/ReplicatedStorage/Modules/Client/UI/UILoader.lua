-- So that we don't need to waitforchild any UI objects, we can guarantee they exist at client runtime
-- By default, UI is tied to initial character loading, but this behaviour sucks as we want access to UI before the character has loaded

local UILoader = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Loaded = require(ReplicatedStorage.Modules.Client.Loaded)
local UITypes = require(script.Parent.UITypes)

local PlayerGui = Players.LocalPlayer.PlayerGui

function GetUI(uiName: string)
	if PlayerGui:FindFirstChild(uiName) then
		return PlayerGui[uiName]
	else
		local template = assert(StarterGui:FindFirstChild(uiName), `{uiName} did not exist in startergui`)
		assert(template:IsA("ScreenGui"))

		local newUI = template:Clone()
		newUI.Enabled = false
		newUI.Parent = PlayerGui
		return newUI
	end
end

local main = GetUI("Main") :: UITypes.Main

local nav = GetUI("Nav") :: UITypes.Nav

local catalog = GetUI("Catalog") :: UITypes.Catalog

local confirm = GetUI("Confirm") :: UITypes.Confirm

function UILoader:GetMain(): UITypes.Main
	return main
end

function UILoader:GetNavigation(): UITypes.Nav
	return nav
end

function UILoader:GetCatalog(): UITypes.Catalog
	return catalog
end

function UILoader:GetConfirm(): UITypes.Confirm
	return confirm
end

function UILoader:Initialize()
	-- Delete the extra UI that the server adds when the character loads
	PlayerGui.ChildAdded:Connect(function(instance)
		-- Need to check the name too as roblox parents other guis to playergui, e.g. proximity prompts
		if instance:IsA("ScreenGui") and StarterGui:FindFirstChild(instance.Name) then
			print("Destroying cloned gui:", instance.Name)
			instance:Destroy()
		end
	end)

	Loaded:CharacterLoadedFuture():After(function()
		main.Enabled = true
		nav.Enabled = true
		catalog.Enabled = true
		confirm.Enabled = true
	end)
end

UILoader:Initialize()

return UILoader

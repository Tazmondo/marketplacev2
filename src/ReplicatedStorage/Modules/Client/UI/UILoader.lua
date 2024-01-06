-- So that we don't need to waitforchild any UI objects, we can guarantee they exist at client runtime
-- By default, UI is tied to initial character loading, but this behaviour sucks as we want access to UI before the character has loaded

local UILoader = {}
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UITypes = require(script.Parent.UITypes)

local PlayerGui = Players.LocalPlayer.PlayerGui

function GetUI(uiName: string)
	if PlayerGui:FindFirstChild(uiName) then
		return PlayerGui[uiName]
	else
		local template = assert(StarterGui:FindFirstChild(uiName), `{uiName} did not exist in startergui`)
		local newUI = template:Clone()
		newUI.Parent = PlayerGui
		return newUI
	end
end

local main = GetUI("Main") :: UITypes.Main

local nav = GetUI("Nav") :: UITypes.Nav

local outfit = GetUI("Catalog") :: UITypes.Catalog

function UILoader:GetMain(): UITypes.Main
	return main
end

function UILoader:GetNavigation(): UITypes.Nav
	return nav
end

function UILoader:GetCatalog(): UITypes.Catalog
	return outfit
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
end

UILoader:Initialize()

return UILoader

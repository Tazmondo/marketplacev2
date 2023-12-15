-- So that we don't need to waitforchild any UI objects, we can guarantee they exist at client runtime
-- By default, UI is tied to initial character loading, but this behaviour sucks

local UILoader = {}
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UITypes = require(script.Parent.UITypes)

local PlayerGui = Players.LocalPlayer.PlayerGui

local main = StarterGui:FindFirstChild("Main") :: UITypes.Main?
assert(main, "Main ui did not exist")
main = main:Clone()
main.Parent = PlayerGui

local nav = StarterGui:FindFirstChild("Nav") :: UITypes.Nav?
assert(nav, "Navigation ui did not exist")
nav = nav:Clone()
nav.Parent = PlayerGui

function UILoader:GetMain(): UITypes.Main
	return main
end

function UILoader:GetNavigation(): UITypes.Nav
	return nav
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

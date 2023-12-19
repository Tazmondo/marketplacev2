local NavigationUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local ProfileUI = require(script.Parent.ProfileUI)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetNavigation()

function ProfileClicked()
	ProfileUI:Toggle()
end

function NavigationUI:Initialize()
	gui.Nav.Me.ImageButton.Image = Thumbs.GetHeadShot(Players.LocalPlayer.UserId)

	gui.Nav.Me.ImageButton.Activated:Connect(ProfileClicked)
end

NavigationUI:Initialize()

return NavigationUI

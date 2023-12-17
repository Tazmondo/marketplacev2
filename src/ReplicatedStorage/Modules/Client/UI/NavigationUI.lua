local NavigationUI = {}

local Players = game:GetService("Players")

local ProfileUI = require(script.Parent.ProfileUI)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetNavigation()

function ProfileClicked()
	ProfileUI:Toggle()
end

function NavigationUI:Initialize()
	gui.Nav.Me.ImageButton.Image = `rbxthumb://type=AvatarHeadShot&id={Players.LocalPlayer.UserId}&w=180&h=180`

	gui.Nav.Me.ImageButton.Activated:Connect(ProfileClicked)
end

NavigationUI:Initialize()

return NavigationUI

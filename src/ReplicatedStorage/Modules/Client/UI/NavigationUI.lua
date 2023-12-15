local NavigationUI = {}

local ProfileUI = require(script.Parent.ProfileUI)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetNavigation()

function ProfileClicked()
	ProfileUI:Show()
end

function NavigationUI:Initialize()
	gui.Nav.Me.ImageButton.Activated:Connect(ProfileClicked)
end

NavigationUI:Initialize()

return NavigationUI

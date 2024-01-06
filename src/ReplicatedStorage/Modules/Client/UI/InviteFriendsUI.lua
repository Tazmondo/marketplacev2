local InviteFriendsUI = {}

local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")

local gui: any = nil

local function HandleClicked()
	local details = Instance.new("ExperienceInviteOptions")
	details.PromptMessage = "Ask your friends to check out this Shop!"

	SocialService:PromptGameInvite(Players.LocalPlayer)
end

function InviteFriendsUI:Initialize()
	gui.Visible = false
	task.spawn(function()
		if SocialService:CanSendGameInviteAsync(Players.LocalPlayer) then
			gui.Visible = true
		end
	end)

	gui.somebutton.Activated:Connect(HandleClicked)
end
-- InviteFriendsUI:Initialize()

return InviteFriendsUI

local NavigationUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FeedEvents = require(ReplicatedStorage.Events.FeedEvents)
local CartUI = require(script.Parent.CartUI)
local FeedController = require(ReplicatedStorage.Modules.Client.FeedController)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local ProfileUI = require(script.Parent.ProfileUI)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetNavigation()
local nav = gui.Nav
local feedUI = gui.Feed

local feedNames: { [Types.FeedType]: string } = {
	["Editor"] = "Editor's Picks",
	["Popular"] = "Most Popular",
	["Random"] = "Random",
}

function ProfileClicked()
	ProfileUI:Toggle()
end

function AvatarClicked()
	CartUI:Toggle()
end

function ExpandFeedClicked()
	feedUI.Frame.Visible = not feedUI.Frame.Visible
end

function RegisterFeedButton(button: ImageButton)
	-- temporary
	if button.Name == "Search" then
		return
	end

	local feedName: Types.FeedType = Types.GuardFeed(button.Name)

	button.Activated:Connect(function()
		feedUI.Frame.Visible = false
		FeedEvents.Switch:FireServer(feedName)
	end)
end

function HandleFeedUpdated(feed: Types.FeedData, index: number)
	feedUI.Current.Feed.Text = feedNames[feed.type]
end

function NavigationUI:Initialize()
	feedUI.Frame.Visible = false

	nav.Profile.Frame.ImageLabel.Image = Thumbs.GetHeadShot(Players.LocalPlayer.UserId)

	FeedController.Updated:Connect(HandleFeedUpdated)
	nav.Profile.ImageButton.Activated:Connect(ProfileClicked)
	nav.Avatar.ImageButton.Activated:Connect(AvatarClicked)
	feedUI.Current.Expand.Activated:Connect(ExpandFeedClicked)
	feedUI.Current.Activated:Connect(ExpandFeedClicked)

	for i, button in feedUI.Frame:GetChildren() do
		if button:IsA("ImageButton") then
			RegisterFeedButton(button)
		end
	end
end

NavigationUI:Initialize()

return NavigationUI

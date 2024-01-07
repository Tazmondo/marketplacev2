local NavigationUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FeedEvents = require(ReplicatedStorage.Events.FeedEvents)
local Device = require(ReplicatedStorage.Modules.Client.Device)
local CatalogUI = require(script.Parent.CatalogUI)
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

local function CatalogClicked()
	CatalogUI:Display("Marketplace")
end

function ExpandFeedClicked()
	feedUI.Frame.Visible = not feedUI.Frame.Visible
end

function RegisterFeedButton(button: ImageButton)
	local feedName: Types.FeedType = Types.GuardFeed(button.Name)

	button.Activated:Connect(function()
		feedUI.Frame.Visible = false
		FeedEvents.Switch:FireServer(feedName)
	end)
end

function HandleFeedUpdated(feed: Types.FeedData, index: number)
	if not feed.viewedUser then
		feedUI.Current.Feed.Text = feedNames[feed.type]
	else
		local success, username = pcall(Players.GetNameFromUserIdAsync, Players, feed.viewedUser)
		feedUI.Current.Feed.Text = if success then `{username}'s Shops` else "Someone's Shops"
	end
end

local function ToggleSearchVisibility(force: boolean?)
	local visible = if force ~= nil then force else not feedUI.Search.Visible
	feedUI.Search.Visible = visible
	feedUI.Current.Visible = not visible

	if visible then
		feedUI.Search.Creator.Text = ""

		-- Capturing focus on mobile seems to hide the placeholder text, which is undesirable
		if Device() == "PC" then
			feedUI.Search.Creator:CaptureFocus()
		end
	end

	feedUI.ActionButton.ImageButton.SearchIcon.Visible = not visible
	feedUI.ActionButton.ImageButton.CloseIcon.Visible = visible
end

function UserSearch()
	local enteredText = feedUI.Search.Creator.Text
	if enteredText == "" then
		return
	end

	local userId = tonumber(enteredText)
	if not userId then
		local success, fetchedId = pcall(Players.GetUserIdFromNameAsync, Players, enteredText)
		if success then
			userId = fetchedId
		end
	end

	if not userId then
		return
	end

	local callSuccess, searchSuccess = FeedEvents.User:Call(userId):Await()
	print("Searching...", userId, searchSuccess)
	if callSuccess and searchSuccess then
		ToggleSearchVisibility(false)
	end
end

function NavigationUI:Initialize()
	feedUI.Frame.Visible = false
	ToggleSearchVisibility(false)

	nav.Profile.Frame.ImageLabel.Image = Thumbs.GetHeadShot(Players.LocalPlayer.UserId)

	FeedController.Updated:Connect(HandleFeedUpdated)

	nav.Profile.ImageButton.Activated:Connect(ProfileClicked)
	nav.Catalog.ImageButton.Activated:Connect(CatalogClicked)

	feedUI.Current.Expand.Activated:Connect(ExpandFeedClicked)
	feedUI.Current.Activated:Connect(ExpandFeedClicked)

	feedUI.ActionButton.ImageButton.Activated:Connect(function()
		ToggleSearchVisibility()
	end)
	feedUI.Search.Toggle.Activated:Connect(UserSearch)
	feedUI.Search.Creator.ReturnPressedFromOnScreenKeyboard:Connect(UserSearch)
	feedUI.Search.Creator.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			UserSearch()
		end
	end)

	for i, button in feedUI.Frame:GetChildren() do
		if button:IsA("ImageButton") then
			RegisterFeedButton(button)
		end
	end
end

NavigationUI:Initialize()

return NavigationUI

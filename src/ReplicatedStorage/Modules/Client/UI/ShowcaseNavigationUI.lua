local ShowcaseNavigationUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FeedController = require(ReplicatedStorage.Modules.Client.FeedController)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain().ControllerNav
local lastLoaded = os.clock()
local currentFeed: Types.FeedData? = nil
local currentIndex: number? = nil

function ShowcaseNavigationUI:Hide()
	gui.Visible = false
end

function ShowcaseNavigationUI:Display()
	print("Display feed:", currentFeed, currentIndex)

	if not currentFeed or #currentFeed.showcases == 0 or not currentIndex then
		gui.Visible = false
		return
	end
	local showcase = currentFeed.showcases[currentIndex]
	if not showcase then
		gui.Visible = false
		return
	end

	gui.ShopInfo.ProfileImage.Image = Thumbs.GetAsset(showcase.thumbId)

	gui.ShopInfo.Text.ShopName.Text = showcase.name

	gui.ShopInfo.Text.CreatorName.Text = ""

	local save = os.clock()
	lastLoaded = save
	Future.Try(Players.GetNameFromUserIdAsync, Players, showcase.owner):After(function(success, name)
		if lastLoaded ~= save then
			-- Another future has been started, so cancel this one.
			return
		end

		if success then
			gui.ShopInfo.Text.CreatorName.Text = `By {name}`
		else
			gui.ShopInfo.Text.CreatorName.Text = "failed to load creator name"
			warn("Failed to load creator name for:", showcase.owner)
		end
	end)

	if currentIndex <= 1 then
		gui.Back.ImageTransparency = 1
		gui.Back.BackgroundTransparency = 1
		gui.Back.Active = false
	else
		gui.Back.Active = true
		gui.Back.ImageTransparency = 0
		gui.Back.BackgroundTransparency = 0
	end

	if currentIndex == #currentFeed.showcases then
		gui.Forward.Active = false
		gui.Forward.ImageTransparency = 0.6
		gui.Forward.BackgroundTransparency = 0.8
	else
		gui.Forward.Active = true
		gui.Forward.ImageTransparency = 0
		gui.Forward.BackgroundTransparency = 0
	end

	gui.Visible = true
end

function ShowcaseNavigationUI:RejoinPlace()
	FeedController:BumpIndex(0)
end

function HandleUpdate(feed, index)
	currentFeed = feed
	currentIndex = index
	ShowcaseNavigationUI:Display()
end

function ShowcaseNavigationUI:Initialize()
	gui.Visible = false
	FeedController.Updated:Connect(HandleUpdate)

	gui.Forward.Activated:Connect(function()
		FeedController:BumpIndex(1)
	end)

	gui.Back.Activated:Connect(function()
		FeedController:BumpIndex(-1)
	end)
end

ShowcaseNavigationUI:Initialize()

return ShowcaseNavigationUI

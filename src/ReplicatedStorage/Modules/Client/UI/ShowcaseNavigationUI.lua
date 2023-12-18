local ShowcaseNavigationUI = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)
local UILoader = require(script.Parent.UILoader)

local MoveFeedEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.MoveFeedEvent):Client()
local UpdateFeedEvent = require(ReplicatedStorage.Events.Showcase.ServerFired.UpdateFeedEvent):Client()

local gui = UILoader:GetMain().ControllerNav
local lastLoaded = os.clock()
local currentFeed: { Types.Showcase }? = nil
local currentIndex: number? = nil

function ShowcaseNavigationUI:Hide()
	gui.Visible = false
end

function ShowcaseNavigationUI:Display()
	print("Display feed:", currentFeed, currentIndex)

	if not currentFeed or #currentFeed == 0 or not currentIndex then
		gui.Visible = false
		return
	end
	local showcase = currentFeed[currentIndex]
	if not showcase then
		gui.Visible = false
		return
	end

	gui.ShopInfo.ProfileImage.Image = `rbxthumb://type=Asset&id={showcase.thumbId}&w=420&h=420`

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
		gui.Back.ImageTransparency = 0.6
		gui.Back.BackgroundTransparency = 0.8
		gui.Back.Active = false
	else
		gui.Back.Active = true
		gui.Back.ImageTransparency = 0
		gui.Back.BackgroundTransparency = 0
	end

	if currentIndex == #currentFeed then
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

function HandleUpdateFeed(feed: { Types.Showcase })
	local newIndex = 1

	-- Preserve the index so it still matches up with the current showcase if the feed has changed in some way
	if currentFeed and currentIndex then
		local difference = #feed - #currentFeed
		if difference >= 0 and feed[currentIndex] and feed[currentIndex].GUID == currentFeed[currentIndex].GUID then
			-- List has only grown so keep index the same
			newIndex = currentIndex
		end
	end

	currentIndex = newIndex
	currentFeed = feed

	ShowcaseNavigationUI:Display()
end

function ShowcaseNavigationUI:RejoinPlace()
	if currentIndex then
		MoveFeedEvent:Fire(currentIndex)
	end
end

function ShowcaseNavigationUI:Initialize()
	gui.Visible = false
	UpdateFeedEvent:On(HandleUpdateFeed)

	gui.Forward.Activated:Connect(function()
		if currentIndex then
			currentIndex += 1
			MoveFeedEvent:Fire(currentIndex)
			ShowcaseNavigationUI:Display()
		end
	end)

	gui.Back.Activated:Connect(function()
		if currentIndex then
			currentIndex -= 1
			MoveFeedEvent:Fire(currentIndex)
			ShowcaseNavigationUI:Display()
		end
	end)
end

ShowcaseNavigationUI:Initialize()

return ShowcaseNavigationUI

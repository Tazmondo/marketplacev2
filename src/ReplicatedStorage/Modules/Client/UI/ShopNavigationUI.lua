local ShopNavigationUI = {}

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

function ShopNavigationUI:Hide()
	gui.Visible = false
end

function ShopNavigationUI:Display()
	print("Display feed:", currentFeed, currentIndex)

	if not currentFeed or #currentFeed.shops == 0 or not currentIndex then
		gui.Visible = false
		return
	end
	local shop = currentFeed.shops[currentIndex]
	if not shop then
		gui.Visible = false
		return
	end

	gui.ShopInfo.ProfileImage.Image = Thumbs.GetAsset(shop.thumbId)

	gui.ShopInfo.Text.ShopName.Text = shop.name

	gui.ShopInfo.Text.CreatorName.Text = ""

	local save = os.clock()
	lastLoaded = save
	Future.Try(Players.GetNameFromUserIdAsync, Players, shop.owner):After(function(success, name)
		if lastLoaded ~= save then
			-- Another future has been started, so cancel this one.
			return
		end

		if success then
			gui.ShopInfo.Text.CreatorName.Text = `By {name}`
		else
			gui.ShopInfo.Text.CreatorName.Text = "failed to load creator name"
			warn("Failed to load creator name for:", shop.owner)
		end
	end)

	if currentIndex <= 1 then
		gui.Back.ImageTransparency = 0
		gui.Back.BackgroundTransparency = 0
		gui.Back.Active = false
	else
		gui.Back.Active = true
		gui.Back.ImageTransparency = 0
		gui.Back.BackgroundTransparency = 0
	end

	if currentIndex == #currentFeed.shops then
		gui.Forward.Active = false
		gui.Forward.ImageTransparency = 0
		gui.Forward.BackgroundTransparency = 0
	else
		gui.Forward.Active = true
		gui.Forward.ImageTransparency = 0
		gui.Forward.BackgroundTransparency = 0
	end

	gui.Visible = true
end

function ShopNavigationUI:RejoinPlace()
	FeedController:BumpIndex(0)
end

function HandleUpdate(feed, index)
	currentFeed = feed
	currentIndex = index
	ShopNavigationUI:Display()
end

function ShopNavigationUI:Initialize()
	gui.Visible = false
	FeedController.Updated:Connect(HandleUpdate)

	gui.Forward.Activated:Connect(function()
		FeedController:BumpIndex(1)
	end)

	gui.Back.Activated:Connect(function()
		FeedController:BumpIndex(-1)
	end)
end

ShopNavigationUI:Initialize()

return ShopNavigationUI

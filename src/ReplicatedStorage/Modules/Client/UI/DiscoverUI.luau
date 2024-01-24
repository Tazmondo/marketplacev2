local DiscoverUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DataEvents = require(ReplicatedStorage.Events.DataEvents)
local ShopController = require(ReplicatedStorage.Modules.Client.Shop.ShopController)
local DiscoverShops = require(ReplicatedStorage.Modules.Shared.DiscoverShops)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetNavigation().Discover

type CollectionFrame = typeof(gui.Frame.Discover.Results.List.Collection)

local function RenderCollectionItems(collectionFrame: CollectionFrame, shareCodes: { number })
	local list = collectionFrame.ListWrapper.List
	local template = list.ShopInfo
	template.Visible = false

	local randomCodes = table.clone(shareCodes)
	Random.new():Shuffle(randomCodes)

	for i, code in randomCodes do
		local shopElement = template:Clone()
		DataEvents.GetShopDetails:Call(code):After(function(success, details)
			if not success or not details then
				return
			end
			local nameSuccess, creatorName = pcall(function()
				return Players:GetNameFromUserIdAsync(details.owner)
			end)

			shopElement.Frame.ProfileImage.Image = Thumbs.GetAsset(details.thumbId)

			shopElement.Frame.Text.CreatorName.Text = if nameSuccess
				then `@{creatorName}`
				else "Failed to fetch username"
			shopElement.Frame.Text.ShopName.Text = details.name

			shopElement.Visible = true
			shopElement.LayoutOrder = i
			shopElement.Parent = list

			shopElement.Activated:Connect(function()
				gui.Visible = false
				ShopController:LoadDynamicShopFromCode(code)
			end)
		end)
	end
end

local function SetupScrollButtons(back: GuiButton, forward: GuiButton, list: ScrollingFrame)
	local function Scroll(forwards: boolean)
		local multiply = if forwards then 1 else -1
		local newPosition = Vector2.new(
			math.clamp(
				list.CanvasPosition.X + (multiply * 0.75 * list.AbsoluteSize.X),
				0,
				list.AbsoluteCanvasSize.X - (list.AbsoluteSize.X * 2)
			),
			0
		)

		TweenService:Create(
			list,
			TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ CanvasPosition = newPosition }
		):Play()
	end

	back.Activated:Connect(function()
		Scroll(false)
	end)

	forward.Activated:Connect(function()
		Scroll(true)
	end)

	local function RenderButtonVisibility()
		(back.Parent :: Frame).Visible = list.CanvasPosition.X > 5;
		(forward.Parent :: Frame).Visible = 5 + list.CanvasPosition.X + (list.AbsoluteSize.X * 2)
			< list.AbsoluteCanvasSize.X
	end

	list:GetPropertyChangedSignal("CanvasPosition"):Connect(RenderButtonVisibility)
	list:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(RenderButtonVisibility)

	RenderButtonVisibility()
end

local function RenderCollections()
	local collectionData = DiscoverShops.codes
	local collections = DiscoverShops.order

	local list = gui.Frame.Discover.Results.List
	local template = list.Collection
	template.Visible = false

	for i, collection in collections do
		local shareCodes = collectionData[collection]

		local element = template:Clone()
		element.Visible = true
		element.Title.TextLabel.Text = collection

		SetupScrollButtons(
			element.ListWrapper.FadeLeft.Left,
			element.ListWrapper.FadeRight.Right,
			element.ListWrapper.List
		)
		RenderCollectionItems(element, shareCodes)

		element.Parent = list
	end
end

function DiscoverUI:Toggle(force: boolean?)
	local visible = if force ~= nil then force else not gui.Visible
	gui.Visible = visible
end

local function Initialize()
	-- gui.Visible = false

	gui.Frame.Discover.Controls.Close.Activated:Connect(function()
		gui.Visible = false
	end)
	RenderCollections()
end

Initialize()

return DiscoverUI

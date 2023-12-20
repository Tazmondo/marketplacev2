local ItemViewUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local UILoader = require(script.Parent.UILoader)

local PurchaseAssetEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.PurchaseAssetEvent):Client()

local gui = UILoader:GetMain().Item
local currentAssetId: number? = nil
local currentItem: Types.Item? = nil

function ItemViewUI:Hide()
	gui.Visible = false
	currentAssetId = nil
	currentItem = nil
end

function Buy()
	if not currentAssetId then
		return
	end
	PurchaseAssetEvent:Fire(currentAssetId)
end

function ItemViewUI:Display(assetId: number)
	print("Viewing: ", assetId)
	gui.Visible = true
	currentAssetId = assetId

	local content = gui.Content
	content.ImageFrame.ItemImage.Image = Thumbs.GetAsset(assetId)
	content.Details.Available.Visible = false
	content.Details.Names.ItemName.Text = ""
	content.Details.Names.Creator.Text = ""
	content.Actions.Buy.TextLabel.Text = ""

	DataFetch.GetItemDetails(assetId):After(function(item)
		if not item or currentAssetId ~= assetId then
			return
		end
		currentItem = item

		content.Details.Names.ItemName.Text = item.name
		content.Details.Names.Creator.Text = item.creator
		if item.price then
			content.Actions.Buy.TextLabel.Text = tostring(item.price)
		end
	end)
end

function ItemViewUI:Initialize()
	gui.Visible = false
	gui.Title.Close.ImageButton.Activated:Connect(ItemViewUI.Hide)
	gui.Content.Actions.Buy.Activated:Connect(Buy)
end

ItemViewUI:Initialize()

return ItemViewUI

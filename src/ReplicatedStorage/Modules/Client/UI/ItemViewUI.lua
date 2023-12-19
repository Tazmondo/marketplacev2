local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)
local UILoader = require(script.Parent.UILoader)
local ItemViewUI = {}

local gui = UILoader:GetMain().Item
local currentItem: Types.Item? = nil

function ItemViewUI:Hide()
	gui.Visible = false
end

function ItemViewUI:Display(assetId: number)
	local content = gui.Content
	content.ImageFrame.ItemImage.Image = Thumbs.GetAsset(assetId)
	content.Details.Available.Amount.Text = ""
	content.Details.Names.ItemName.Text = ""
	content.Details.Names.Creator.Text = ""
	content.Price.Floor.Frame.Amount.Text = ""

	DataFetch.GetItemDetails(assetId):After(function(item) end)
end

function ItemViewUI:Initialize()
	gui.Visible = false
	gui.Topbar.Avatar.ImageButton.Image = Thumbs.GetHeadShot(Players.LocalPlayer.UserId)
end

ItemViewUI:Initialize()

return ItemViewUI

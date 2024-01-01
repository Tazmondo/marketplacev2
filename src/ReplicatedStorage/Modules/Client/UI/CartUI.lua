-- Does not itself handle cart state - it is only updated by the cart controller when the cart state updates

local CartUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UILoader = require(script.Parent.UILoader)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PurchaseAssetEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.PurchaseAssetEvent):Client()

local mainUI = UILoader:GetMain().Avatar

CartUI.Deleted = Signal()

function HandleRemoveItem(id: number)
	CartUI.Deleted:Fire(id)
end

function HandleBuyItem(id: number)
	PurchaseAssetEvent:Fire(id)
end

function CartUI:RenderItems(itemIds: { number })
	for i, child in mainUI.Content.Wearing:GetChildren() do
		if child:IsA("Frame") and child:GetAttribute("Temporary") then
			child:Destroy()
		end
	end

	local template = mainUI.Content.Wearing.Row
	template.Visible = false

	for i, id in itemIds do
		local newRow = template:Clone()

		newRow.ImageFrame.Frame.ItemImage.Image = Thumbs.GetAsset(id)

		newRow.ImageFrame.Close.ImageButton.Activated:Connect(function()
			HandleRemoveItem(id)
		end)
		newRow.Details.Buy.Activated:Connect(function()
			HandleBuyItem(id)
		end)
		newRow.Details.Text.ShopName.Text = "Loading... " .. id
		newRow.Details.Text.CreatorName.Text = "Loading..."
		newRow.Details.Buy.TextLabel.Text = "Loading..."

		newRow.Visible = true
		newRow:SetAttribute("Temporary", true)
		newRow.LayoutOrder = #itemIds - i -- so most recent additions are at the top
		newRow.Parent = template.Parent

		DataFetch.GetItemDetails(id):After(function(details)
			if details and newRow.Parent ~= nil then
				newRow.Details.Text.CreatorName.Text = details.creator
				newRow.Details.Text.ShopName.Text = details.name
				newRow.Details.Buy.TextLabel.Text = `{details.price or "N/A"}`
			end
		end)
	end

	CartUI:Display()
end

function CartUI:Display()
	mainUI.Visible = true
end

function CartUI:Hide()
	mainUI.Visible = false
end

function CartUI:Initialize()
	mainUI.Visible = false

	mainUI.Content.Title.Close.ImageButton.Activated:Connect(function()
		CartUI:Hide()
	end)
end

CartUI:Initialize()

return CartUI

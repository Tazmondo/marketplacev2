-- Does not itself handle cart state - it is only updated by the cart controller when the cart state updates

local CartUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UILoader = require(script.Parent.UILoader)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
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
		newRow.Details.Text.ShopName.Text = "Loading... "
		newRow.Details.Text.CreatorName.Text = "Loading..."
		newRow.Details.Buy.TextLabel.Text = "Loading..."

		newRow.Visible = true
		newRow:SetAttribute("Temporary", true)
		newRow.LayoutOrder = #itemIds - i -- so most recent additions are at the top
		newRow.Parent = template.Parent

		DataFetch.GetItemDetails(id, Players.LocalPlayer):After(function(details)
			if details and newRow.Parent ~= nil then
				newRow.Details.Text.CreatorName.Text = Util.TruncateString(details.creator, 25)
				newRow.Details.Text.ShopName.Text = Util.TruncateString(details.name, 25)

				if details.owned or details.price == nil then
					newRow.Details.Buy.ImageLabel.Visible = false
					newRow.Details.Buy.Active = false
					newRow.Details.Buy.AutoButtonColor = false
					newRow.Details.Buy.BackgroundColor3 = Color3.new(1, 1, 1)
					newRow.Details.Buy.BackgroundTransparency = 0.9

					if details.owned then
						newRow.Details.Buy.TextLabel.Text = "Owned"
					else
						newRow.Details.Buy.TextLabel.Text = "Not Available"
						newRow.Details.Buy.TextLabel.TextColor3 = Color3.new(1, 1, 1)
						newRow.Details.Buy.TextLabel.TextTransparency = 0.5
					end
				else
					if details.price == 0 then
						newRow.Details.Buy.TextLabel.Text = "Get"
						newRow.Details.Buy.ImageLabel.Visible = false
					else
						newRow.Details.Buy.TextLabel.Text = `{details.price or "N/A"}`
					end

					newRow.Details.Buy.Activated:Connect(function()
						HandleBuyItem(id)
					end)
				end
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

function CartUI:Toggle()
	mainUI.Visible = not mainUI.Visible
end

function CartUI:Initialize()
	mainUI.Visible = false

	mainUI.Content.Title.Close.ImageButton.Activated:Connect(function()
		CartUI:Hide()
	end)
end

CartUI:Initialize()

return CartUI

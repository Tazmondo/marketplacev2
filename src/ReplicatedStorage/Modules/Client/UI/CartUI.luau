local CartUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PurchaseEvents = require(ReplicatedStorage.Events.PurchaseEvents)
local CartController = require(ReplicatedStorage.Modules.Client.CartController)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain().Cart

local function HandleCartUpdated(cartItems: { CartController.CartItem })
	local list = gui.Wrapper.Results.ListWrapper.List
	local template = list.ItemWrapper

	local unOwnedItems = TableUtil.Filter(cartItems, function(item)
		if not item.equipped then
			return false
		end

		local details = DataFetch.GetItemDetails(item.id, Players.LocalPlayer):Await()
		return details ~= nil and details.owned ~= true
	end)

	type itemTemplate = typeof(template)

	local function render(i: number, item: itemTemplate, data: CartController.CartItem, destroyed: () -> boolean)
		local assetData = DataFetch.GetItemDetails(data.id, Players.LocalPlayer):Await()
		if destroyed() then
			return
		end

		if not assetData then
			return
		end

		item.ImageFrame.Frame.ItemImage.Image = Thumbs.GetAsset(data.id, "150")
		item.IsLimited.Visible = assetData.limited ~= nil
		item.LayoutOrder = #unOwnedItems - i

		if assetData.price then
			item.Buy.TextLabel.Text = tostring(assetData.price)
			item.Buy.Activated:Connect(function()
				PurchaseEvents.Asset:FireServer(data.id, data.shopOwner)
			end)
		else
			item.Buy.Visible = false
		end

		item.Close.Activated:Connect(function()
			CartController:RemoveFromCart(data.id)
		end)

		item.Visible = true
	end

	Util.RenderList(list, template, unOwnedItems, function(...)
		task.spawn(render, ...)
	end)

	gui.Visible = #unOwnedItems > 0
end

local function Initialize()
	gui.Visible = false

	CartController.CartUpdated:Connect(HandleCartUpdated)

	DataFetch.ItemBought:Connect(function()
		HandleCartUpdated(CartController:GetCartItems())
	end)
end

Initialize()

return CartUI

local CartUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PurchaseEvents = require(ReplicatedStorage.Events.PurchaseEvents)
local CartController = require(ReplicatedStorage.Modules.Client.CartController)
local BundleResolver = require(ReplicatedStorage.Modules.Shared.BundleResolver)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain().Cart

local function HandleCartUpdated()
	local list = gui.Wrapper.Results.ListWrapper.List
	local template = list.ItemWrapper

	type data = {
		id: number,
		shopOwner: number?,
	}

	local cartItems = CartController:GetCartItems()
	local classicClothing = CartController:GetClassicClothing()

	local cartData: { data } = {}

	local function addItem(item)
		if not item.equipped then
			return
		end
		local details = DataFetch.GetItemDetails(item.id, Players.LocalPlayer):Await()
		if details ~= nil and details.owned ~= true then
			table.insert(cartData, {
				id = item.id,
				shopOwner = item.shopOwner,
			})
		end
	end

	for _, item in cartItems do
		addItem(item)
	end

	for _, item in classicClothing do
		addItem(item)
	end

	type itemTemplate = typeof(template)

	local function render(i: number, item: itemTemplate, data: data, destroyed: () -> boolean)
		local assetData = DataFetch.GetItemDetails(data.id, Players.LocalPlayer):Await()
		if destroyed() then
			return
		end

		if not assetData then
			return
		end

		item.ImageFrame.Frame.ItemImage.Image = Thumbs.GetAsset(data.id, "150")
		item.IsLimited.Visible = assetData.limited ~= nil
		item.LayoutOrder = #cartData - i

		if not assetData.price then
			item.LayoutOrder += 1000
		end

		local price: number?

		if BundleResolver.IsAssetBodyPart(assetData.assetType) then
			local bundle = BundleResolver.BundleFromPart.Get(assetData.assetId):Await()
			if bundle and bundle.price then
				price = bundle.price
				item.Buy.Activated:Connect(function()
					PurchaseEvents.Bundle:FireServer(bundle.id, data.shopOwner)
				end)
			end
		else
			price = assetData.price
			item.Buy.Activated:Connect(function()
				PurchaseEvents.Asset:FireServer(data.id, data.shopOwner)
			end)
		end

		if price then
			item.Buy.TextLabel.Text = tostring(price)
		else
			item.Buy.Visible = false
		end

		item.Close.Activated:Connect(function()
			CartController:RemoveFromCart(data.id)
		end)

		item.Visible = true
	end

	Util.RenderList(list, template, cartData, function(...)
		task.spawn(render, ...)
	end)

	gui.Visible = #cartData > 0
end

local function Initialize()
	gui.Visible = false

	CartController.CartUpdated:Connect(HandleCartUpdated)

	DataFetch.ItemBought:Connect(function()
		HandleCartUpdated()
	end)
end

Initialize()

return CartUI

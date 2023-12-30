local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CartUI = require(ReplicatedStorage.Modules.Client.UI.CartUI)
local CartController = {}

local cartItems: { number } = {}

function UpdateUI()
	CartUI:RenderItems(cartItems)
end

function CartController:RemoveFromCart(id: number)
	local index = table.find(cartItems, id)
	if index then
		table.remove(cartItems, index)
	end

	UpdateUI()
end

function CartController:AddToCart(id: number)
	if not table.find(cartItems, id) then
		table.insert(cartItems, id)
	end

	UpdateUI()
end

function CartController:Initialize()
	CartUI.Deleted:Connect(function(id: number)
		CartController:RemoveFromCart(id)
	end)
end

CartController:Initialize()

return CartController

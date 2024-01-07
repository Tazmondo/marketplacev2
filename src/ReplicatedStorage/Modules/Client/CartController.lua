local CartController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Future = require(ReplicatedStorage.Packages.Future)

local DescriptionEvent = require(ReplicatedStorage.Events.DescriptionEvent):Client()

local cartItems: { number } = {}

function UpdateCharacter()
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end

	DescriptionEvent:Fire(cartItems)
end

function CartController:RemoveFromCart(id: number)
	local index = table.find(cartItems, id)
	if index then
		table.remove(cartItems, index)
	end

	UpdateCharacter()
end

function CartController:AddToCart(id: number)
	if not table.find(cartItems, id) then
		table.insert(cartItems, id)
	end

	UpdateCharacter()
end

function CartController:ToggleInCart(id: number)
	local found = table.find(cartItems, id)
	if not found then
		table.insert(cartItems, id)
	else
		table.remove(cartItems, found)
	end

	UpdateCharacter()
end

function CartController:GetCart()
	return table.clone(cartItems)
end

function HandleReset()
	return Future.new(function()
		local success, description =
			pcall(Players.GetHumanoidDescriptionFromUserId, Players, Players.LocalPlayer.UserId)
		if not success then
			warn(description)
			return
		end

		local items = {}
		for i, accessory in description:GetAccessories(true) do
			table.insert(items, accessory.AssetId)
		end

		cartItems = items
		UpdateCharacter()
	end)
end

function HandleCharacterAdded(char: Model)
	UpdateCharacter()
	-- CartUI:Hide()
end

function CartController:Initialize()
	-- CartUI.Deleted:Connect(function(id: number)
	-- 	CartController:RemoveFromCart(id)
	-- end)

	local player = Players.LocalPlayer
	if player.Character then
		HandleCharacterAdded(player.Character)
	end

	player.CharacterAdded:Connect(HandleCharacterAdded)
end

CartController:Initialize()

return CartController

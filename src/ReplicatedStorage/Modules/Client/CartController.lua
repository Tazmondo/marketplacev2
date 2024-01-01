local CartController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CartUI = require(ReplicatedStorage.Modules.Client.UI.CartUI)

local DescriptionEvent = require(ReplicatedStorage.Events.DescriptionEvent):Client()

local cartItems: { number } = {}

function UpdateCharacter()
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end

	DescriptionEvent:Fire(cartItems)
end

function UpdateUI()
	CartUI:RenderItems(cartItems)
end

function Update()
	UpdateUI()
	UpdateCharacter()
end

function CartController:RemoveFromCart(id: number)
	local index = table.find(cartItems, id)
	if index then
		table.remove(cartItems, index)
	end

	Update()
end

function CartController:AddToCart(id: number)
	if not table.find(cartItems, id) then
		table.insert(cartItems, id)
	end

	Update()
end

function CartController:ToggleInCart(id: number)
	local found = table.find(cartItems, id)
	if not found then
		table.insert(cartItems, id)
	else
		table.remove(cartItems, found)
	end

	Update()
end

function HandleCharacterAdded(char: Model)
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	cartItems = {}

	local description = humanoid:GetAppliedDescription()
	for i, accessory in description:GetAccessories(true) do
		table.insert(cartItems, accessory.AssetId)
	end

	Update()
end

function CartController:Initialize()
	CartUI.Deleted:Connect(function(id: number)
		CartController:RemoveFromCart(id)
	end)

	local player = Players.LocalPlayer
	if player.Character then
		HandleCharacterAdded(player.Character)
	end

	player.CharacterAdded:Connect(HandleCharacterAdded)
end

CartController:Initialize()

return CartController

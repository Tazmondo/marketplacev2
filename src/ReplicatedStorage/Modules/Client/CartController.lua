local CartController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- O(1) lookup time but also ordered
local cartItems: { number } = {}
local cartSet: { [number]: true? } = {}

CartController.CartUpdated = Signal()

function UpdateCharacter()
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end

	AvatarEvents.ApplyDescription:FireServer(cartItems)
	CartController.CartUpdated:Fire(cartItems)
end

function CartController:RemoveFromCart(id: number)
	local index = table.find(cartItems, id)
	if index then
		table.remove(cartItems, index)
		cartSet[id] = nil
	end

	UpdateCharacter()
end

function CartController:AddToCart(id: number)
	if not cartSet[id] then
		table.insert(cartItems, id)
		cartSet[id] = true
	end

	UpdateCharacter()
end

function CartController:ToggleInCart(id: number)
	local found = table.find(cartItems, id)
	if not found then
		table.insert(cartItems, id)
		cartSet[id] = true
	else
		table.remove(cartItems, found)
		cartSet[id] = nil
	end

	UpdateCharacter()
end

function CartController:GetCart()
	return table.clone(cartItems)
end

function CartController:Reset()
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
			cartSet[accessory.AssetId] = true
		end

		cartItems = items
		UpdateCharacter()
	end)
end

function CartController:IsInCart(id: number)
	return cartSet[id] == true
end

local function InitialCharacterLoad(char: Model)
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	cartItems = {}

	local description = humanoid:GetAppliedDescription()
	for i, accessory in description:GetAccessories(true) do
		table.insert(cartItems, accessory.AssetId)
		cartSet[accessory.AssetId] = true
	end

	CartController.CartUpdated:Fire(cartItems)
end

function CartController:Initialize()
	local player = Players.LocalPlayer

	task.spawn(function()
		InitialCharacterLoad(player.Character or player.CharacterAdded:Wait())

		player.CharacterAdded:Connect(UpdateCharacter)
	end)
end

CartController:Initialize()

return CartController

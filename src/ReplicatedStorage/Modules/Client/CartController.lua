local CartController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

export type CartItem = {
	id: number,
	equipped: boolean,
}

-- O(1) lookup time but also ordered
local cartItems: { CartItem } = {}
local cartSet: { [number]: true? } = {}

CartController.CartUpdated = Signal()

local function NewCartItem(id: number)
	return {
		id = id,
		equipped = true,
	}
end

function UpdateCharacter()
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end

	AvatarEvents.ApplyDescription:FireServer(CartController:GetEquippedIds())
	CartController.CartUpdated:Fire(cartItems)
end

function CartController:GetEquippedIds(): { number }
	return TableUtil.Map(
		TableUtil.Filter(cartItems, function(item)
			return item.equipped == true
		end),
		function(item)
			return item.id
		end
	)
end

function CartController:RemoveFromCart(id: number)
	local _, index = TableUtil.Find(cartItems, function(item)
		return item.id == id
	end)

	if index then
		table.remove(cartItems, index)
		cartSet[id] = nil
	end

	UpdateCharacter()
end

function CartController:AddToCart(id: number)
	if not cartSet[id] then
		table.insert(cartItems, NewCartItem(id))
		cartSet[id] = true
	end

	UpdateCharacter()
end

function CartController:ToggleInCart(id: number)
	local _, index = TableUtil.Find(cartItems, function(item)
		return item.id == id
	end)

	if not index then
		table.insert(cartItems, NewCartItem(id))
		cartSet[id] = true
	else
		table.remove(cartItems, index)
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

		cartItems = {}

		for i, accessory in description:GetAccessories(true) do
			table.insert(cartItems, NewCartItem(accessory.AssetId))
			cartSet[accessory.AssetId] = true
		end

		UpdateCharacter()
	end)
end

function CartController:IsInCart(id: number)
	return cartSet[id] == true
end

function CartController:ToggleEquipped(id: number, force: boolean?)
	local cartItem = TableUtil.Find(cartItems, function(item)
		return item.id == id
	end)
	if not cartItem then
		return
	end

	cartItem.equipped = if force == nil then not cartItem.equipped else force

	UpdateCharacter()
end

function CartController:ClearUnequippedItems()
	cartSet = {}
	cartItems = TableUtil.Filter(cartItems, function(item)
		if item.equipped then
			cartSet[item.id] = true
		end
		return item.equipped
	end)
end

local function InitialCharacterLoad(char: Model)
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	cartItems = {}

	local description = humanoid:GetAppliedDescription()
	for i, accessory in description:GetAccessories(true) do
		table.insert(cartItems, NewCartItem(accessory.AssetId))
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

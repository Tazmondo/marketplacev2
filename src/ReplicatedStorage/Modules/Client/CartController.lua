local CartController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CartUI = require(ReplicatedStorage.Modules.Client.UI.CartUI)

local DescriptionEvent = require(ReplicatedStorage.Events.DescriptionEvent):Client()

type AccessoriesTable = { [Enum.AccessoryType]: { typeof(Instance.new("HumanoidDescription"):GetAccessories(true)[1]) } }

local function GetEmptyAccessoryTable()
	local newTable: AccessoriesTable = {}
	for i, accessoryEnum in Enum.AccessoryType:GetEnumItems() :: { Enum.AccessoryType } do
		newTable[accessoryEnum] = {}
	end
	return newTable
end

local description: HumanoidDescription? = nil

local cartItems: { number } = {}
local cartAccessories = GetEmptyAccessoryTable()

function DescriptionAsAccessoryTable(description: HumanoidDescription)
	local newTable = GetEmptyAccessoryTable()

	local accessories = description:GetAccessories(true)
	for i, accessory in accessories do
		local accessoryTable = newTable[accessory.AccessoryType]
		table.insert(accessoryTable, accessory)
	end

	return newTable
end

function UpdateCharacter()
	local character = Players.LocalPlayer.Character
	if not character or not description then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local defaultAccessories = DescriptionAsAccessoryTable(description)

	local finalAccessories = {}

	-- If any accessories of a specific type have been added to the cart, only equip those ones
	-- Otherwise, just add the user's own accessories of that type.
	for i, accessoryType in Enum.AccessoryType:GetEnumItems() :: { Enum.AccessoryType } do
		local selectedAccessories = cartAccessories[accessoryType]
		if #selectedAccessories == 0 then
			for i, accessory in defaultAccessories[accessoryType] do
				table.insert(finalAccessories, accessory)
			end
		else
			for i, accessory in selectedAccessories do
				table.insert(finalAccessories, accessory)
			end
		end
	end

	DescriptionEvent:Fire(finalAccessories)
end

function UpdateUI()
	CartUI:RenderItems(cartItems)
end

function CartController:RemoveFromCart(id: number)
	local index = table.find(cartItems, id)
	if index then
		table.remove(cartItems, index)
	end

	UpdateUI()
	UpdateCharacter()
end

function CartController:AddToCart(id: number)
	if not table.find(cartItems, id) then
		table.insert(cartItems, id)
	end

	UpdateUI()
	UpdateCharacter()
end

function HandleCharacterAdded(char: Model)
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	description = humanoid:GetAppliedDescription()
	assert(description)
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

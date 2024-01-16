local CartController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
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
local cachedDescription: Future.Future<HumanoidDescription>? = nil
local bodyParts = table.clone(HumanoidDescription.defaultBodyParts)

local lastEquippedPackage: number? = nil


CartController.CartUpdated = Signal()

local function NewCartItem(id: number)
	return {
		id = id,
		equipped = true,
	}
end

local function GetEquippedAccessories()
	return Future.new(function(): { HumanoidDescription.Accessory }
		local function GetAccessory(id: number): HumanoidDescription.Accessory?
			local details = DataFetch.GetItemDetails(id):Await()
			if not details then
				return nil
			end
			return {
				id = id,
				assetType = details.assetType,
			}
		end

		local function NotNil(item: any)
			return item ~= nil
		end

		local ids = CartController:GetEquippedIds()
		local accessories = TableUtil.Filter(TableUtil.Map(ids, GetAccessory), NotNil)

		return accessories :: { HumanoidDescription.Accessory }
	end)
end

local function GetDescription()
	return Future.new(function(): HumanoidDescription
		local description: HumanoidDescription

		local player = Players.LocalPlayer
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				description = humanoid:GetAppliedDescription()
			end
		end

		if not description then
			description = Players:GetHumanoidDescriptionFromUserId(player.UserId)
		end

		HumanoidDescription.ApplyToDescription(description, GetEquippedAccessories():Await())
		HumanoidDescription.ApplyBodyParts(description, bodyParts)

		return description
	end)
end

function UpdateCharacter()
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end

	local descriptionFuture = GetDescription()
	cachedDescription = descriptionFuture

	descriptionFuture:After(function(description)
		AvatarEvents.ApplyDescription:FireServer(HumanoidDescription.Serialize(description))
	end)
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

function CartController:GetDescription()
	return Future.new(function()
		return if cachedDescription then cachedDescription:Await() else GetDescription():Await()
	end)
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

function CartController:EquipPackage(bundleId: number)
	return Future.new(function()
		lastEquippedPackage = bundleId

		local bundleData = DataFetch.GetBundleBodyParts(bundleId):Await()
		if not bundleData then
			return
		end

		for bodyPart, id in pairs(bundleData) do
			bodyParts[bodyPart] = id
		end

		UpdateCharacter()
	end)
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
		cartSet = {}

		for i, accessory in description:GetAccessories(true) do
			table.insert(cartItems, NewCartItem(accessory.AssetId))
			cartSet[accessory.AssetId] = true
		end

		UpdateCharacter()
	end)
end

function CartController:UseDescription(description: HumanoidDescription)
	cartItems = {}
	cartSet = {}

	for i, accessory in description:GetAccessories(true) do
		table.insert(cartItems, { id = accessory.AssetId, equipped = true })
		cartSet[accessory.AssetId] = true
	end

	bodyParts = HumanoidDescription.ExtractBodyParts(description)
	lastEquippedPackage = nil

	UpdateCharacter()
end

function CartController:IsInCart(id: number)
	return cartSet[id] == true or lastEquippedPackage == id or (table.find(bodyParts, id) ~= nil)
end

function CartController:IsEquipped(id: number): boolean
	return CartController:IsInCart(id)
		and TableUtil.Find(cartItems, function(item)
			return item.id == id and item.equipped
		end) ~= nil
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
	cartSet = {}

	local description = humanoid:GetAppliedDescription()
	for i, accessory in description:GetAccessories(true) do
		table.insert(cartItems, NewCartItem(accessory.AssetId))
		cartSet[accessory.AssetId] = true
	end

	bodyParts = HumanoidDescription.ExtractBodyParts(description)

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

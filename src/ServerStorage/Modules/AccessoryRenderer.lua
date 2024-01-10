-- Only servers to update player characters when the client requests it
-- Honestly this might be a security concern? I think it's a Roblox issue though if someone can exploit by just wearing accessories

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)
local Types = require(ReplicatedStorage.Modules.Shared.Types)

local function ApplyToDescription(description: HumanoidDescription, accessories: { number })
	-- Here, trying to add an accessory that is already equipped but to a different slot will error
	-- So ensure that accessories that already exist are always added to the same slot.
	local existingAccessories = description:GetAccessories(true)
	local existingAccessorySet: { [number]: Types.HumanoidDescriptionAccessory } = {}
	for i, accessory in existingAccessories do
		existingAccessorySet[accessory.AssetId] = accessory
	end

	local newAccessories = {}

	for i, id in accessories do
		local existingAccessory = existingAccessorySet[id]

		if existingAccessory then
			table.insert(newAccessories, existingAccessory)
		else
			table.insert(newAccessories, {
				AssetId = id,
				AccessoryType = Enum.AccessoryType.Face,
				IsLayered = false,
			})
		end
	end

	description:SetAccessories(newAccessories, true)
end

local function HandleUpdateAccessories(player: Player, accessories: { number })
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local description = humanoid:GetAppliedDescription()
	ApplyToDescription(description, accessories)

	humanoid:ApplyDescription(description)
end

local function GenerateModel(player: Player, accessories: { number }): Model?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local baseDescription = humanoid:GetAppliedDescription()
	ApplyToDescription(baseDescription, accessories)

	local newModel = Players:CreateHumanoidModelFromDescription(baseDescription, Enum.HumanoidRigType.R15)
	newModel.Name = "GeneratedViewportModel"
	newModel:PivotTo(CFrame.new(10000, 10000, 0)) -- ensures the nametag is not visible to the player

	-- Use playergui so it is only replicated to the relevant player
	newModel.Parent = player.PlayerGui

	Debris:AddItem(newModel, 30)

	-- It should be replicated through PlayerGui before this remote function return is processed by the client, so this should never be nil
	return newModel
end

AvatarEvents.ApplyDescription:SetServerListener(HandleUpdateAccessories)
AvatarEvents.GenerateModel:SetCallback(GenerateModel)
return {}

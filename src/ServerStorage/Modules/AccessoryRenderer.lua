-- Only servers to update player characters when the client requests it
-- Honestly this might be a security concern? I think it's a Roblox issue though if someone can exploit by just wearing accessories

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local DescriptionEvent = require(ReplicatedStorage.Events.DescriptionEvent):Server()

function HandleUpdateAccessories(player: Player, accessories: { number })
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Here, trying to add an accessory that is already equipped but to a different slot will error
	-- So ensure that accessories that already exist are always added to the same slot.
	local description = humanoid:GetAppliedDescription()

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

	humanoid:ApplyDescription(description)
end

DescriptionEvent:On(HandleUpdateAccessories)

return {}

-- Only servers to update player characters when the client requests it
-- Honestly this might be a security concern? I think it's a Roblox issue though if someone can exploit by just wearing accessories

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local DescriptionEvent = require(ReplicatedStorage.Events.DescriptionEvent):Server()

function HandleUpdateAccessories(player: Player, accessories: { Types.HumanoidDescriptionAccessory })
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local description = humanoid:GetAppliedDescription()
	description:SetAccessories(accessories, true)
	humanoid:ApplyDescription(description)
end

DescriptionEvent:On(HandleUpdateAccessories)

return {}

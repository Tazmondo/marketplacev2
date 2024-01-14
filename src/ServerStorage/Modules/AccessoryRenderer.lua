-- Only servers to update player characters when the client requests it
-- Honestly this might be a security concern? I think it's a Roblox issue though if someone can exploit by just wearing accessories

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Types = require(ReplicatedStorage.Modules.Shared.Types)

local function HandleUpdateAccessories(player: Player, serDescription: Types.SerializedDescription)
	local description = HumanoidDescription.Deserialize(serDescription)

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid:ApplyDescription(description)
end

local function GenerateModel(player: Player, serDescription: Types.SerializedDescription): Model?
	local description = HumanoidDescription.Deserialize(serDescription)

	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local newModel = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
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

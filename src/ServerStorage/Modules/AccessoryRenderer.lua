-- Only servers to update player characters when the client requests it
-- Honestly this might be a security concern? I think it's a Roblox issue though if someone can exploit by just wearing accessories

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)
local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Types = require(ReplicatedStorage.Modules.Shared.Types)

local accessoryCache: { [number]: Model } = {}

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

	if player.Parent == nil then
		return
	end

	newModel.Name = "GeneratedViewportModel"
	newModel:PivotTo(CFrame.new(10000, 10000, 0)) -- ensures the nametag is not visible to the player

	-- Use playergui so it is only replicated to the relevant player
	newModel.Parent = player.PlayerGui

	Debris:AddItem(newModel, 30)

	-- It should be replicated through PlayerGui before this remote function return is processed by the client, so this should never be nil
	return newModel
end

-- Specialmeshes do not support a way to get their size.
-- MeshParts do.
-- When using Players:CreateHumanoidModelFromDescription with R15 rigs, it generates accessories using MeshParts
-- So we can use this to generate a MeshPart and normalize its size.
local function ReplicateAsset(player: Player, assetId: number): Model?
	if accessoryCache[assetId] then
		local model = accessoryCache[assetId]:Clone()
		model.Parent = player.PlayerGui
		Debris:AddItem(model, 30)

		return model
	end

	local description = Instance.new("HumanoidDescription")
	description.FaceAccessory = tostring(assetId)
	local playerModel = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	if player.Parent == nil then
		return
	end

	-- Was already cached while yielding
	if accessoryCache[assetId] then
		local model = accessoryCache[assetId]:Clone()
		model.Parent = player.PlayerGui
		Debris:AddItem(model, 30)

		return model
	end

	local accessory = playerModel:FindFirstChildOfClass("Accessory")
	if not accessory then
		return
	end
	local meshPart = accessory:FindFirstChildOfClass("MeshPart")
	if not meshPart then
		warn(`Accessory generated without meshpart {assetId}`)
		return
	end

	-- Rotation offset of the model from the player
	-- This allows us to set the pivot so the orientation when CFraming is the same as if it was attached to a player
	-- I.e. the front of the model faces forwards.
	-- Need to parent to workspace too otherwise it doesn't return the correct value
	-- Parenting to the camera means they won't get replicated to the client unnecessarily too.
	playerModel.Parent = workspace.CurrentCamera
	local pivot = playerModel:GetPivot():ToObjectSpace(meshPart.CFrame).Rotation:Inverse()
	meshPart.PivotOffset = pivot

	local model = Instance.new("Model")
	meshPart.Parent = model
	model.PrimaryPart = meshPart
	model.Name = tostring(assetId)

	playerModel:Destroy()

	local vectorSize = meshPart.Size
	local maxSize = math.max(vectorSize.X, vectorSize.Y, vectorSize.Z)

	-- Scale meshpart so it fits within a 1x1x1 cube
	local scale = 1 / maxSize

	local wrapLayer = meshPart:FindFirstChildOfClass("WrapLayer")
	if wrapLayer then
		wrapLayer:Destroy()
	end

	model:ScaleTo(scale)
	accessoryCache[assetId] = model:Clone()
	model.Parent = player.PlayerGui
	Debris:AddItem(model, 30)

	return model
end

AvatarEvents.ApplyDescription:SetServerListener(HandleUpdateAccessories)
AvatarEvents.GenerateModel:SetCallback(GenerateModel)
ShopEvents.GetAccessoryModel:SetCallback(ReplicateAsset)

return {}

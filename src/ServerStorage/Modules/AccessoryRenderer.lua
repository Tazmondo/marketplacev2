-- Only servers to update player characters when the client requests it
-- Honestly this might be a security concern? I think it's a Roblox issue though if someone can exploit by just wearing accessories

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)
local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)

type modelCache = { [number]: Future.Future<Model?> }
type cache = {
	[Types.StandType]: modelCache,
	Accessory: modelCache,
}

-- although ids are unique, doing this avoids a cache corruption vulnerability
-- 	an exploiter could request an id with a purposefully incorrect asset type, which would
-- 	corrupt the cache for that id, and cause it to always fail to return the correct model
-- 	having each type have its own table means that sending the incorrect type does not corrupt the cache,
-- 	as sending the correct type will use a different table from the incorrect one.
local cache: cache = {
	Accessory = {},
	TShirt = {},
	Shirt = {},
	Pants = {},
}

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
local function ReplicateAsset(player: Player, assetId: number)
	return Future.new(function(player: Player, assetId: number): Model?
		local model

		if cache.Accessory[assetId] then
			local template = cache.Accessory[assetId]:Await()
			if not template then
				return
			end
			model = template:Clone()
		end

		if not model then
			local modelFuture = Future.new(function(assetId): Model?
				local description = Instance.new("HumanoidDescription")
				description.FaceAccessory = tostring(assetId)
				local playerModel = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)

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

				return model
			end, assetId)

			cache.Accessory[assetId] = modelFuture
			local generatedModel = modelFuture:Await()
			if not generatedModel then
				return
			end

			model = generatedModel:Clone()
		end

		if player.Parent ~= Players then
			return
		end
		model.Parent = player.PlayerGui
		Debris:AddItem(model, 30)
		return model
	end, player, assetId)
end

local function ReplicateClassicClothing(player: Player, data: ShopEvents.GetClothingSettings)
	return Future.new(function(player: Player, data: ShopEvents.GetClothingSettings): Model?
		assert(data.type ~= "Accessory", "Tried to replicate classic clothing for an accessory")

		local templateModel: Model?

		local clothingCache = cache[data.type]
		if clothingCache[data.id] then
			templateModel = clothingCache[data.id]:Await()
		else
			local modelFuture = Future.new(function(): Model?
				local description = Instance.new("HumanoidDescription")
				if data.type == "Shirt" then
					description.Shirt = data.id
				elseif data.type == "Pants" then
					description.Pants = data.id
				elseif data.type == "TShirt" then
					description.GraphicTShirt = data.id
				else
					Util.ExhaustiveMatch(data.type)
				end

				local color = Color3.fromHex("#EAB892")

				description.HeadColor = color
				description.TorsoColor = color
				description.LeftArmColor = color
				description.LeftLegColor = color
				description.RightArmColor = color
				description.RightLegColor = color

				local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R6)
				local humanoid = assert(model:FindFirstChildOfClass("Humanoid"), "Inserted rig had no humanoid")
				local HRP = assert(humanoid.RootPart, "Humanoid had no root part")

				HRP.Anchored = true
				humanoid.EvaluateStateMachine = false
				humanoid.BreakJointsOnDeath = false
				model.Name = tostring(data.id)

				local vectorSize = model:GetExtentsSize()
				local maxSize = math.max(vectorSize.X, vectorSize.Y, vectorSize.Z)

				-- Scale meshpart so it fits within a 1x1x1 cube
				local scale = 1.25 / maxSize

				model:ScaleTo(scale)

				local head = assert(model:FindFirstChild("Head"), "Rig had no head")
				head:Destroy()

				model.PrimaryPart = HRP

				return model
			end)

			clothingCache[data.id] = modelFuture
			templateModel = modelFuture:Await()
		end

		if templateModel and player.Parent == Players then
			local model = templateModel:Clone()
			model.Parent = player.PlayerGui
			Debris:AddItem(model, 30)
			print("returning clothing model")
			return model
		end
		return
	end, player, data)
end

local function HandleReplicateStand(player: Player, data: ShopEvents.GetClothingSettings): Model?
	if data.type == "Accessory" then
		return ReplicateAsset(player, data.id):Await()
	else
		return ReplicateClassicClothing(player, data):Await()
	end
end

AvatarEvents.ApplyDescription:SetServerListener(HandleUpdateAccessories)
AvatarEvents.GenerateModel:SetCallback(GenerateModel)
ShopEvents.GetStandItem:SetCallback(HandleReplicateStand)

return {}

--!nolint LocalShadow
local HumanoidDescription = {}

local AvatarEditorService = game:GetService("AvatarEditorService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(script.Parent.Types)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

export type Accessory = {
	id: number,
	assetType: Enum.AvatarAssetType,
}

HumanoidDescription.defaultBodyParts = {
	Face = 0,
	Head = 0,
	RightArm = 0,
	RightLeg = 0,
	LeftLeg = 0,
	LeftArm = 0,
	Torso = 0,
	HeadColor = Color3.fromRGB(234, 184, 146),
	RightArmColor = Color3.fromRGB(234, 184, 146),
	LeftArmColor = Color3.fromRGB(234, 184, 146),
	LeftLegColor = Color3.fromRGB(234, 184, 146),
	RightLegColor = Color3.fromRGB(234, 184, 146),
	TorsoColor = Color3.fromRGB(234, 184, 146),
	BodyTypeScale = 0.3,
	DepthScale = 1,
	HeadScale = 1,
	HeightScale = 1,
	ProportionScale = 1,
	WidthScale = 1,
	GraphicTShirt = 0,
	Shirt = 0,
	Pants = 0,
}
TableUtil.Lock(HumanoidDescription.defaultBodyParts)

export type BodyParts = typeof(HumanoidDescription.defaultBodyParts)

local function SerializeAccessories(accessories: { Types.HumanoidDescriptionAccessory }): string
	-- BE VERY CAREFUL WHEN CHANGING THIS CODE

	local serializedAccessories = TableUtil.Map(accessories, function(accessory)
		return { accessory.AssetId, accessory.Order or 1, accessory.AccessoryType.Value }
	end)

	return HttpService:JSONEncode(serializedAccessories)
end

local function DeserializeAccessories(accessoryJson: string): { Types.HumanoidDescriptionAccessory }
	-- BE VERY CAREFUL WHEN CHANGING THIS CODE

	local accessories = TableUtil.Map(HttpService:JSONDecode(accessoryJson), function(accessory)
		local enum = TableUtil.Find(Enum.AccessoryType:GetEnumItems() :: { Enum.AccessoryType }, function(enum)
			return enum.Value == accessory[3]
		end)

		if not enum then
			warn("[DeserializeAccessories]: Enum not found, value:", accessory[3])
			enum = Enum.AccessoryType.Face
		end
		assert(enum)

		return {
			AssetId = accessory[1],
			Order = accessory[2],
			AccessoryType = enum,
			IsLayered = true,
			Puffiness = nil, -- type solver wants me to set this for some reason
		}
	end)

	return accessories
end

-- The reason I serialize and deserialize into an array is to save space on all the keys
-- This drastically reduces the data used to store each outfit
function HumanoidDescription.Serialize(description: HumanoidDescription): Types.SerializedDescription
	-- BE VERY CAREFUL WHEN CHANGING THIS CODE!
	local serialized: { any } = {
		SerializeAccessories(description:GetAccessories(true)),
		description.BodyTypeScale,
		description.DepthScale,
		description.Face,
		description.GraphicTShirt,
		description.Head,
		description.HeadColor:ToHex(),
		description.HeadScale,
		description.HeightScale,
		description.LeftArm,
		description.LeftArmColor:ToHex(),
		description.LeftLeg,
		description.LeftLegColor:ToHex(),
		description.Pants,
		description.ProportionScale,
		description.RightArm,
		description.RightArmColor:ToHex(),
		description.RightLeg,
		description.RightLegColor:ToHex(),
		description.Shirt,
		description.Torso,
		description.TorsoColor:ToHex(),
		description.WidthScale,
		description.IdleAnimation,
	}

	return serialized :: any
end

function HumanoidDescription.Deserialize(descriptionInfo: Types.SerializedDescription): HumanoidDescription
	-- BE VERY CAREFUL WHEN CHANGING THIS CODE
	local description = Instance.new("HumanoidDescription")
	local descriptionInfo = descriptionInfo :: any

	description:SetAccessories(DeserializeAccessories(descriptionInfo[1]), true)
	description.BodyTypeScale = descriptionInfo[2]
	description.DepthScale = descriptionInfo[3]
	description.Face = descriptionInfo[4]
	description.GraphicTShirt = descriptionInfo[5]
	description.Head = descriptionInfo[6]
	description.HeadColor = Color3.fromHex(descriptionInfo[7])
	description.HeadScale = descriptionInfo[8]
	description.HeightScale = descriptionInfo[9]
	description.LeftArm = descriptionInfo[10]
	description.LeftArmColor = Color3.fromHex(descriptionInfo[11])
	description.LeftLeg = descriptionInfo[12]
	description.LeftLegColor = Color3.fromHex(descriptionInfo[13])
	description.Pants = descriptionInfo[14]
	description.ProportionScale = descriptionInfo[15]
	description.RightArm = descriptionInfo[16]
	description.RightArmColor = Color3.fromHex(descriptionInfo[17])
	description.RightLeg = descriptionInfo[18]
	description.RightLegColor = Color3.fromHex(descriptionInfo[19])
	description.Shirt = descriptionInfo[20]
	description.Torso = descriptionInfo[21]
	description.TorsoColor = Color3.fromHex(descriptionInfo[22])
	description.WidthScale = descriptionInfo[23]
	description.IdleAnimation = descriptionInfo[24] or 0

	return description
end

local accessoryOrder = {
	[Enum.AccessoryType.LeftShoe] = 1,
	[Enum.AccessoryType.RightShoe] = 1,
	[Enum.AccessoryType.Shorts] = 2,
	[Enum.AccessoryType.Pants] = 2,
	[Enum.AccessoryType.DressSkirt] = 2,
	[Enum.AccessoryType.TShirt] = 3,
	[Enum.AccessoryType.Shirt] = 4,
	[Enum.AccessoryType.Sweater] = 5,
	[Enum.AccessoryType.Jacket] = 6,
	[Enum.AccessoryType.Waist] = 7,
	[Enum.AccessoryType.Back] = 7,
	[Enum.AccessoryType.Front] = 7,
	[Enum.AccessoryType.Neck] = 8,
	[Enum.AccessoryType.Shoulder] = 8,
	[Enum.AccessoryType.Hair] = 9,
	[Enum.AccessoryType.Face] = 9,
	[Enum.AccessoryType.Hat] = 9,
}

function HumanoidDescription.ApplyToDescription(description: HumanoidDescription, accessories: { Accessory })
	-- Here, trying to add an accessory that is already equipped but to a different slot will error
	-- So ensure that accessories that already exist are always added to the same slot.
	local existingAccessories = description:GetAccessories(true)
	local existingAccessorySet: { [number]: Types.HumanoidDescriptionAccessory } = {}
	for i, accessory in existingAccessories do
		existingAccessorySet[accessory.AssetId] = accessory
	end

	local newAccessories = {}
	local currentOrder = 1

	for i, accessory in accessories do
		local existingAccessory = existingAccessorySet[accessory.id]

		if existingAccessory then
			table.insert(newAccessories, {
				AssetId = existingAccessory.AssetId,
				AccessoryType = existingAccessory.AccessoryType,
				IsLayered = true,
				Order = accessoryOrder[existingAccessory.AccessoryType] or 100,
			})
		else
			local accessoryType = AvatarEditorService:GetAccessoryType(accessory.assetType)
			table.insert(newAccessories, {
				AssetId = accessory.id,
				AccessoryType = accessoryType,
				IsLayered = true,
				Order = accessoryOrder[accessoryType] or 100,
			})
		end
		currentOrder += 1
	end

	description:SetAccessories(newAccessories, true)
end

function HumanoidDescription.ApplyBodyParts(description: HumanoidDescription, bodyParts: BodyParts)
	description.Face = bodyParts.Face
	description.Head = bodyParts.Head
	description.RightArm = bodyParts.RightArm
	description.RightLeg = bodyParts.RightLeg
	description.LeftLeg = bodyParts.LeftLeg
	description.LeftArm = bodyParts.LeftArm
	description.Torso = bodyParts.Torso
	description.HeadColor = bodyParts.HeadColor
	description.RightArmColor = bodyParts.RightArmColor
	description.LeftArmColor = bodyParts.LeftArmColor
	description.LeftLegColor = bodyParts.LeftLegColor
	description.RightLegColor = bodyParts.RightLegColor
	description.TorsoColor = bodyParts.TorsoColor

	description.BodyTypeScale = bodyParts.BodyTypeScale
	description.DepthScale = bodyParts.DepthScale
	description.HeadScale = bodyParts.HeadScale
	description.HeightScale = bodyParts.HeightScale
	description.ProportionScale = bodyParts.ProportionScale
	description.WidthScale = bodyParts.WidthScale

	description.GraphicTShirt = bodyParts.GraphicTShirt
	description.Pants = bodyParts.Pants
	description.Shirt = bodyParts.Shirt
end

-- Returns the base humanoid description, with the accessories of the other description
function HumanoidDescription.WithAccessories(
	base: HumanoidDescription,
	accessories: HumanoidDescription
): HumanoidDescription
	local newDescription = base:Clone()
	newDescription:SetAccessories(accessories:GetAccessories(true), true)

	return newDescription
end

function HumanoidDescription.Equal(
	desc1: HumanoidDescription | Types.SerializedDescription | nil,
	desc2: HumanoidDescription | Types.SerializedDescription | nil
)
	if desc1 == nil and desc2 == nil then
		return true
	elseif desc1 == nil or desc2 == nil then
		return false
	end

	local stringDesc1 = HumanoidDescription.Stringify(desc1)
	local stringDesc2 = HumanoidDescription.Stringify(desc2)

	return stringDesc1 == stringDesc2
end

-- Independent of accessory order. For use with outfit comparions, as the cart does not care about order when copying outfits to the cart.
function HumanoidDescription.FuzzyEq(
	desc1: HumanoidDescription | Types.SerializedDescription | nil,
	desc2: HumanoidDescription | Types.SerializedDescription | nil
)
	if desc1 == nil and desc2 == nil then
		return true
	elseif desc1 == nil or desc2 == nil then
		return false
	end

	local ser1 = if typeof(desc1) == "Instance" then HumanoidDescription.Serialize(desc1) else table.clone(desc1)
	local ser2 = if typeof(desc2) == "Instance" then HumanoidDescription.Serialize(desc2) else table.clone(desc2)

	local function normalizeOrder(serDes: Types.SerializedDescription)
		local accessories = DeserializeAccessories(serDes[1] :: string)
		local normalizedAccessories = TableUtil.Map(accessories, function(accessory)
			return {
				AccessoryType = accessory.AccessoryType,
				AssetId = accessory.AssetId,
				IsLayered = accessory.IsLayered,
				Order = 1,
				Puffiness = accessory.Puffiness,
			}
		end)

		serDes[1] = SerializeAccessories(normalizedAccessories)
	end

	normalizeOrder(ser1)
	normalizeOrder(ser2)

	return HumanoidDescription.Equal(ser1, ser2)
end

function HumanoidDescription.ExtractBodyParts(description: HumanoidDescription): BodyParts
	local newParts = {
		Face = description.Face,
		Head = description.Head,
		RightArm = description.RightArm,
		RightLeg = description.RightLeg,
		LeftLeg = description.LeftLeg,
		LeftArm = description.LeftArm,
		Torso = description.Torso,
		HeadColor = description.HeadColor,
		RightArmColor = description.RightArmColor,
		LeftArmColor = description.LeftArmColor,
		LeftLegColor = description.LeftLegColor,
		RightLegColor = description.RightLegColor,
		TorsoColor = description.TorsoColor,

		BodyTypeScale = description.BodyTypeScale,
		DepthScale = description.DepthScale,
		HeadScale = description.HeadScale,
		HeightScale = description.HeightScale,
		ProportionScale = description.ProportionScale,
		WidthScale = description.WidthScale,

		GraphicTShirt = description.GraphicTShirt,
		Pants = description.Pants,
		Shirt = description.Shirt,
	}

	return newParts
end

function HumanoidDescription.Stringify(description: Types.SerializedDescription | HumanoidDescription)
	if typeof(description) == "Instance" then
		return HttpService:JSONEncode(HumanoidDescription.Serialize(description))
	else
		return HttpService:JSONEncode(description)
	end
end

function HumanoidDescription.Guard(info: unknown)
	HumanoidDescription.Deserialize(info :: any)
	return info :: Types.SerializedDescription
end

return HumanoidDescription

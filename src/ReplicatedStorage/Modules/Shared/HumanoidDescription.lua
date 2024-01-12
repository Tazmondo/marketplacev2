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

export type SerializedDescription = { string | number }

local function SerializeAccessories(description: HumanoidDescription): string
	local accessories = TableUtil.Map(description:GetAccessories(true), function(accessory)
		return { accessory.AssetId, accessory.Order or 1, accessory.AccessoryType.Value }
	end)

	return HttpService:JSONEncode(accessories)
end

local function DeserializeAccessories(accessoryJson: string): { Types.HumanoidDescriptionAccessory }
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
function HumanoidDescription.Serialize(description: HumanoidDescription): SerializedDescription
	return {
		SerializeAccessories(description),
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
	}
end

function HumanoidDescription.Deserialize(descriptionInfo: SerializedDescription): HumanoidDescription
	local description = Instance.new("HumanoidDescription")
	local descriptionInfo = descriptionInfo :: { any }

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

function HumanoidDescription.Guard(info: unknown)
	HumanoidDescription.Deserialize(info :: any)
	return info :: SerializedDescription
end

return HumanoidDescription

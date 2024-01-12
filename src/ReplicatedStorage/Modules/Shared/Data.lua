local Data = {}

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Config = require(script.Parent.Config)
local Material = require(script.Parent.Material)
local Types = require(script.Parent.Types)

export type Outfit = {
	name: string,
	description: { number | string }, -- Outfits are serialized as an array of numbers and strings
}

export type VectorTable = {
	x: number,
	y: number,
	z: number,
}

export type Stand = {
	assetId: number,
	roundedPosition: VectorTable,
}
local standTemplate: Stand = {
	assetId = 2041985255,
	roundedPosition = { x = 0, y = 0, z = 0 },
}

export type Showcase = {
	name: string,
	thumbId: number,
	logoId: number?,
	layoutId: string, -- Not using Layouts.LayoutId here because the data could become invalid if layouts change. So we need to verify when loading it.

	-- Colours must be hex strings, Color3 cannot be stored in datastore
	primaryColor: string,
	accentColor: string,
	texture: string,

	GUID: string,
	stands: { Stand },
}
local showcaseTemplate: Showcase = {
	name = "Untitled Shop",
	thumbId = Config.DefaultShopThumbnail,
	layoutId = Layouts:GetDefaultLayoutId(),
	GUID = HttpService:GenerateGUID(false),
	stands = {},
	primaryColor = Config.DefaultPrimaryColor:ToHex(),
	accentColor = Config.DefaultAccentColor:ToHex(),
	texture = Material:GetDefault(),
}

export type Data = {
	showcases: { Showcase },
	outfits: { Outfit },
	version: number,
	firstTime: boolean,
}

local dataTemplate: Data = {
	showcases = {},
	outfits = {},
	version = 8,
	firstTime = true,
}
Data.dataTemplate = dataTemplate

function Data.VectorToTable(vector: Vector3): VectorTable
	return {
		x = vector.X,
		y = vector.Y,
		z = vector.Z,
	}
end

function Data.TableToVector(vector: VectorTable): Vector3
	return Vector3.new(vector.x, vector.y, vector.z)
end

function Data.Migrate(data: Data)
	if data.version == dataTemplate.version then
		-- Data shape hasn't updated, no need to reconcile
		return
	end

	for k, v in pairs(dataTemplate) do
		if not data[k] then
			data[k] = v
		end
	end

	for i, showcase in data.showcases do
		for k, v in pairs(showcaseTemplate) do
			if not showcase[k] then
				showcase[k] = v
			end
		end

		for i, stand in showcase.stands do
			for k, v in pairs(standTemplate) do
				if not stand[k] then
					stand[k] = v
				end
			end
		end
	end

	data.version = dataTemplate.version
end

function Data.ToDataStand(stand: Types.Stand): Stand?
	if stand.assetId then
		return {
			assetId = stand.assetId,
			roundedPosition = Data.VectorToTable(stand.roundedPosition),
		}
	else
		return nil
	end
end

function Data.ToDataShowcase(showcase: Types.Showcase): Showcase
	local stands = table.create(#showcase.stands)

	for i, stand in showcase.stands do
		local dataStand = Data.ToDataStand(stand)
		if dataStand then
			table.insert(stands, dataStand)
		end
	end

	return {
		thumbId = showcase.thumbId,
		layoutId = showcase.layoutId,
		name = showcase.name,
		primaryColor = showcase.primaryColor:ToHex(),
		accentColor = showcase.accentColor:ToHex(),
		texture = showcase.texture,
		GUID = showcase.GUID,
		stands = stands,
		logoId = showcase.logoId,
	}
end

function Data.FromDataStand(stand: Stand): Types.Stand
	return {
		assetId = stand.assetId,
		roundedPosition = Data.TableToVector(stand.roundedPosition),
	}
end

function Data.FromDataShowcase(showcase: Showcase, ownerId: number): Types.Showcase
	local stands = table.create(#showcase.stands)
	for i, stand in showcase.stands do
		table.insert(stands, Data.FromDataStand(stand))
	end

	-- Since these may become invalidated as the game progresses, need to make sure they don't cause cascading errors into the rest of the code.
	local primaryColor = if Config.PrimaryColors[showcase.primaryColor]
		then Color3.fromHex(showcase.primaryColor)
		else Config.DefaultPrimaryColor

	local accentColor = if Config.AccentColors[showcase.accentColor]
		then Color3.fromHex(showcase.accentColor)
		else Config.DefaultAccentColor

	local layoutId: LayoutData.LayoutId = if Layouts:LayoutIdExists(showcase.layoutId)
		then showcase.layoutId :: LayoutData.LayoutId
		else Layouts:GetDefaultLayoutId()

	local texture: string = if Material:TextureExists(showcase.texture) then showcase.texture else Material:GetDefault()

	return {
		GUID = showcase.GUID,
		layoutId = layoutId,
		owner = ownerId,
		stands = stands,
		name = showcase.name,
		thumbId = showcase.thumbId,
		logoId = showcase.logoId,
		primaryColor = primaryColor,
		accentColor = accentColor,
		texture = texture,
	}
end

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
local function SerializeDescription(description: HumanoidDescription): { string | number }
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

local function DeserializeDescription(descriptionInfo: { any }): HumanoidDescription
	local description = Instance.new("HumanoidDescription")

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

function Data.FromDataOutfit(outfit: Outfit): Types.Outfit
	return {
		name = outfit.name,
		description = DeserializeDescription(outfit.description),
	}
end

function Data.ToDataOutfit(outfit: Types.Outfit): Outfit
	return {
		name = outfit.name,
		description = SerializeDescription(outfit.description),
	}
end

-- local function Test()
-- 	local description = Players:GetHumanoidDescriptionFromUserId(68252170)
-- 	description.Parent = ServerStorage
-- 	local serialized = SerializeDescription(description)
-- 	print(serialized, #HttpService:JSONEncode(serialized))
-- 	local deserialized = DeserializeDescription(serialized)
-- 	deserialized.Name = "deser"
-- 	deserialized.Parent = ServerStorage
-- end
-- task.spawn(Test)

return Data

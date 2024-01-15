local Data = {}

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Config = require(script.Parent.Config)
local HumanoidDescription = require(script.Parent.HumanoidDescription)
local Material = require(script.Parent.Material)
local Types = require(script.Parent.Types)

export type Outfit = {
	name: string,
	description: Types.SerializedDescription, -- Outfits are serialized as an array of numbers and strings
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

export type OutfitStand = {
	description: Types.SerializedDescription,
	roundedPosition: VectorTable,
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
	outfitStands: { OutfitStand },
}
local showcaseTemplate: Showcase = {
	name = "Untitled Shop",
	thumbId = Config.DefaultShopThumbnail,
	layoutId = Config.DefaultLayout,
	GUID = HttpService:GenerateGUID(false),
	stands = {},
	outfitStands = {},
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
	version = 9,
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

function Data.ToDataOutfitStand(stand: Types.OutfitStand): OutfitStand?
	if stand.description then
		return {
			description = stand.description,
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

	local outfitStands = table.create(#showcase.outfitStands)
	for i, stand in showcase.outfitStands do
		local dataStand = Data.ToDataOutfitStand(stand)
		if dataStand then
			table.insert(outfitStands, dataStand)
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
		outfitStands = outfitStands,
		logoId = showcase.logoId,
	}
end

function Data.FromDataStand(stand: Stand): Types.Stand
	return {
		assetId = stand.assetId,
		roundedPosition = Data.TableToVector(stand.roundedPosition),
	}
end

function Data.FromDataOutfitStand(stand: OutfitStand): Types.OutfitStand
	return {
		description = stand.description,
		roundedPosition = Data.TableToVector(stand.roundedPosition),
	}
end

function Data.FromDataShowcase(showcase: Showcase, ownerId: number): Types.Showcase
	local stands = TableUtil.Map(showcase.stands, Data.FromDataStand)
	local outfitStands = TableUtil.Map(showcase.outfitStands, Data.FromDataOutfitStand)

	-- Since these may become invalidated as the game progresses, need to make sure they don't cause cascading errors into the rest of the code.
	local primaryColor = if Config.PrimaryColors[showcase.primaryColor]
		then Color3.fromHex(showcase.primaryColor)
		else Config.DefaultPrimaryColor

	local accentColor = if Config.AccentColors[showcase.accentColor]
		then Color3.fromHex(showcase.accentColor)
		else Config.DefaultAccentColor

	local layoutId: LayoutData.LayoutId = if Layouts:LayoutIdExists(showcase.layoutId)
		then showcase.layoutId :: LayoutData.LayoutId
		else Config.DefaultLayout

	local texture: string = if Material:TextureExists(showcase.texture) then showcase.texture else Material:GetDefault()

	return {
		GUID = showcase.GUID,
		layoutId = layoutId,
		owner = ownerId,
		stands = stands,
		outfitStands = outfitStands,
		name = showcase.name,
		thumbId = showcase.thumbId,
		logoId = showcase.logoId,
		primaryColor = primaryColor,
		accentColor = accentColor,
		texture = texture,
	}
end

function Data.FromDataOutfit(outfit: Outfit): Types.Outfit
	return {
		name = outfit.name,
		description = HumanoidDescription.Deserialize(outfit.description),
	}
end

function Data.ToDataOutfit(outfit: Types.Outfit): Outfit
	return {
		name = outfit.name,
		description = HumanoidDescription.Serialize(outfit.description),
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

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
	type: Types.StandType,
	roundedPosition: VectorTable,
}
local standTemplate: Stand = {
	assetId = 2041985255,
	roundedPosition = { x = 0, y = 0, z = 0 },
	type = "Accessory",
}

export type OutfitStand = {
	description: Types.SerializedDescription,
	name: string,
	roundedPosition: VectorTable,
}
local outfitStandTemplate = {
	description = HumanoidDescription.Serialize(Instance.new("HumanoidDescription")),
	name = "Outfit",
	roundedPosition = { x = 0, y = 0, z = 0 },
}

export type Shop = {
	name: string,
	thumbId: number,
	logoId: number?,
	layoutId: string, -- Not using Layouts.LayoutId here because the data could become invalid if layouts change. So we need to verify when loading it.
	storefrontId: string, -- Same as above

	-- Colours must be hex strings, Color3 cannot be stored in datastore
	primaryColor: string,
	accentColor: string,
	texture: string,

	GUID: string,
	shareCode: number?,
	stands: { Stand },
	outfitStands: { OutfitStand },
}

local shopTemplate: Shop = {
	name = "Untitled Shop",
	thumbId = Config.DefaultShopThumbnail,
	layoutId = Config.DefaultLayout,
	storefrontId = Layouts:GetRandomStorefrontId(),
	GUID = HttpService:GenerateGUID(false),
	stands = {},
	outfitStands = {},
	primaryColor = Config.DefaultPrimaryColor:ToHex(),
	accentColor = Config.DefaultAccentColor:ToHex(),
	texture = Material:GetDefault(),
}

export type Data = {
	shops: { Shop },
	outfits: { Outfit },
	version: number,
	firstTime: boolean,
	purchases: number,
	sales: number,
	donationRobux: number, -- total robux received from donations
	donationsReceived: number, -- total number of donations received
	shopbux: number,
	totalShopbux: number, -- lifetime shopbux earned
	ownedLayouts: { [string]: true },
}

local dataTemplate: Data = {
	shops = {},
	outfits = {},
	version = 3,
	firstTime = true,
	purchases = 0,
	sales = 0,
	donationRobux = 0,
	donationsReceived = 0,
	shopbux = 0,
	totalShopbux = 0,
	ownedLayouts = {},
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

function Data.Migrate(data: Data, ownerId: number)
	if data.version == dataTemplate.version then
		-- Data shape hasn't updated, no need to reconcile
		return
	end

	-- DON'T DO GENERAL RECONCILIATIONS
	--	honestly they are a pain to work with when you also want to make specific migrations, as you cannot be sure which fields exist at any point in the migration
	--	not that hard to just manually write migration code

	if data.version < 2 then
		data.ownedLayouts = {}
	end

	if data.version < 3 then
		for _, shop in data.shops do
			for _, stand in shop.outfitStands do
				stand.name = outfitStandTemplate.name
			end
		end
	end

	data.version = dataTemplate.version
end

function Data.ToDataStand(stand: Types.Stand): Stand?
	if stand.item then
		return {
			assetId = stand.item.id,
			roundedPosition = Data.VectorToTable(stand.roundedPosition),
			type = stand.item.type,
		}
	else
		return nil
	end
end

function Data.ToDataOutfitStand(stand: Types.OutfitStand): OutfitStand?
	if stand.details then
		return {
			description = stand.details.description,
			roundedPosition = Data.VectorToTable(stand.roundedPosition),
			name = stand.details.name,
		}
	else
		return nil
	end
end

function Data.ToDataShop(shop: Types.Shop): Shop
	local stands = table.create(#shop.stands)

	for i, stand in shop.stands do
		local dataStand = Data.ToDataStand(stand)
		if dataStand then
			table.insert(stands, dataStand)
		end
	end

	local outfitStands = table.create(#shop.outfitStands)
	for i, stand in shop.outfitStands do
		local dataStand = Data.ToDataOutfitStand(stand)
		if dataStand then
			table.insert(outfitStands, dataStand)
		end
	end

	return {
		thumbId = shop.thumbId,
		layoutId = shop.layoutId,
		storefrontId = shop.storefrontId,
		name = shop.name,
		primaryColor = shop.primaryColor:ToHex(),
		accentColor = shop.accentColor:ToHex(),
		texture = shop.texture,
		GUID = shop.GUID,
		shareCode = shop.shareCode,
		stands = stands,
		outfitStands = outfitStands,
		logoId = shop.logoId,
	}
end

function Data.FromDataStand(stand: Stand): Types.Stand
	return {
		roundedPosition = Data.TableToVector(stand.roundedPosition),
		item = {
			id = stand.assetId,
			type = stand.type,
		},
	}
end

function Data.FromDataOutfitStand(stand: OutfitStand): Types.OutfitStand
	return {
		details = {
			description = stand.description,
			name = stand.name,
		},
		roundedPosition = Data.TableToVector(stand.roundedPosition),
	}
end

function Data.FromDataShop(shop: Shop, ownerId: number): Types.Shop
	local stands = TableUtil.Map(shop.stands, Data.FromDataStand)
	local outfitStands = TableUtil.Map(shop.outfitStands, Data.FromDataOutfitStand)

	-- Since these may become invalidated as the game progresses, need to make sure they don't cause cascading errors into the rest of the code.
	local primaryColor = if Config.PrimaryColors[shop.primaryColor]
		then Color3.fromHex(shop.primaryColor)
		else Config.DefaultPrimaryColor

	local accentColor = if Config.AccentColors[shop.accentColor]
		then Color3.fromHex(shop.accentColor)
		else Config.DefaultAccentColor

	local layoutId: LayoutData.LayoutId = if Layouts:LayoutIdExists(shop.layoutId)
		then shop.layoutId :: LayoutData.LayoutId
		else Config.DefaultLayout

	local storefrontId: LayoutData.StorefrontId = if Layouts:StorefrontIdExists(shop.storefrontId)
		then shop.storefrontId :: LayoutData.StorefrontId
		else Layouts:GetRandomStorefrontId()

	local texture: string = if Material:TextureExists(shop.texture) then shop.texture else Material:GetDefault()

	return {
		GUID = shop.GUID,
		shareCode = shop.shareCode,
		layoutId = layoutId,
		storefrontId = storefrontId,
		owner = ownerId,
		stands = stands,
		outfitStands = outfitStands,
		name = shop.name,
		thumbId = shop.thumbId,
		logoId = shop.logoId,
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

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
local outfitStandTemplate = {
	description = HumanoidDescription.Serialize(Instance.new("HumanoidDescription")),
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
}

local dataTemplate: Data = {
	shops = {},
	outfits = {},
	version = 13,
	firstTime = true,
	purchases = 0,
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

	-- Specific migrations
	if data.version < 10 then
		-- Renamed showcases to shops
		data.shops = (data :: any).showcases or {};
		(data :: any).showcases = nil
	end

	-- General migration
	for k, v in pairs(dataTemplate) do
		if not data[k] then
			data[k] = v
		end
	end

	for i, shop in data.shops do
		for k, v in pairs(shopTemplate) do
			if not shop[k] then
				shop[k] = v
			end
		end

		for i, stand in shop.stands do
			for k, v in pairs(standTemplate) do
				if not stand[k] then
					stand[k] = v
				end
			end
		end

		for i, stand in shop.outfitStands do
			for k, v in pairs(outfitStandTemplate) do
				if not stand[k] then
					stand[k] = v
				end
			end
		end
	end

	if data.version < 11 then
		-- Greedy fill new layouts with old layout data
		for _, shop in data.shops do
			if not Layouts:LayoutIdExists(shop.layoutId) then
				shop.layoutId = "Shop 1" :: LayoutData.LayoutId
			end
			local newLayout = Layouts:GetLayout(shop.layoutId :: LayoutData.LayoutId)

			local validStandPositions = newLayout.getValidStandPositions()
			local validOutfitStandPositions = newLayout.getValidOutfitStandPositions()

			local migratedStands: { Stand } = {}
			local migratedOutfits: { OutfitStand } = {}
			local oldStands = table.clone(shop.stands or {})
			local oldOutfits = table.clone(shop.outfitStands or {})

			for position, _ in validStandPositions do
				local oldStand = table.remove(oldStands, #oldStands)
				if not oldStand then
					break
				end
				table.insert(migratedStands, {
					assetId = oldStand.assetId,
					roundedPosition = Data.VectorToTable(position),
				})
			end

			for position, _ in validOutfitStandPositions do
				local oldStand = table.remove(oldOutfits, #oldOutfits)
				if not oldStand then
					break
				end
				table.insert(migratedOutfits, {
					description = oldStand.description,
					roundedPosition = Data.VectorToTable(position),
				})
			end

			shop.stands = migratedStands
			shop.outfitStands = migratedOutfits
		end
	end

	if data.version < 12 then
		-- added storefronts
		for i, shop in data.shops do
			local seed = i + ownerId
			local randomStorefront = Layouts:GetRandomStorefrontId(seed)
			shop.storefrontId = randomStorefront
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

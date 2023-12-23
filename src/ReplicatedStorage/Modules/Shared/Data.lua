local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local Config = require(script.Parent.Config)

local Material = require(script.Parent.Material)
local Types = require(script.Parent.Types)
local Data = {}

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
	version: number,
	firstTime: boolean,
}

local dataTemplate: Data = {
	showcases = {},
	version = 7,
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
	print(`Migrating data from {data.version} to {dataTemplate.version}`)

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

return Data

local HttpService = game:GetService("HttpService")
local Config = require(script.Parent.Config)
local Layouts = require(script.Parent.Layouts)
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
	layoutId: Layouts.LayoutId,

	-- Colours must be hex strings, Color3 cannot be stored in datastore
	primaryColor: string,
	accentColor: string,

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
}

export type Data = {
	showcases: { Showcase },
	version: number,
}

local dataTemplate: Data = {
	showcases = {},
	version = 5,
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
		GUID = showcase.GUID,
		stands = stands,
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

	-- Since the color configs may change, ensure an invalid color is never loaded.
	local primaryColor = if Config.PrimaryColors[showcase.primaryColor]
		then Color3.fromHex(showcase.primaryColor)
		else Config.DefaultPrimaryColor

	local accentColor = if Config.AccentColors[showcase.accentColor]
		then Color3.fromHex(showcase.accentColor)
		else Config.DefaultAccentColor

	return {
		GUID = showcase.GUID,
		layoutId = showcase.layoutId,
		owner = ownerId,
		stands = stands,
		name = showcase.name,
		thumbId = showcase.thumbId,
		primaryColor = primaryColor,
		accentColor = accentColor,
	}
end

return Data

local Config = require(script.Parent.Config)
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

export type Showcase = {
	name: string,

	-- Colours must be hex strings, Color3 cannot be stored in datastore
	primaryColor: string,
	accentColor: string,

	GUID: string,
	stands: { Stand },
}

export type Data = {
	showcases: { Showcase },
	version: number,
}

local dataTemplate: Data = {
	showcases = {},
	version = 2,
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

function Data.Migrate(data: Data) end

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
		owner = ownerId,
		stands = stands,
		name = showcase.name,
		primaryColor = primaryColor,
		accentColor = accentColor,
	}
end

return Data

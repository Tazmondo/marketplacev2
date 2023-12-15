local Types = require(script.Parent.Types)
local Data = {}

export type VectorTable = {
	x: number,
	y: number,
	z: number,
}

export type Stand = {
	item: number,
	roundedPosition: VectorTable,
}

export type Showcase = {
	stands: { Stand },
	name: string,
	GUID: string,
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
	if stand.item then
		return {
			item = stand.item,
			roundedPosition = Data.VectorToTable(stand.roundedPosition),
		}
	else
		return nil
	end
end

function Data.ToDataShowcase(showcase: Types.Showcase): Showcase
	local stands = {}
	for i, stand in showcase.stands do
		local dataStand = Data.ToDataStand(stand)
		if dataStand then
			table.insert(stands, dataStand)
		end
	end

	return {
		name = showcase.name,
		GUID = showcase.GUID,
		stands = stands,
	}
end

return Data

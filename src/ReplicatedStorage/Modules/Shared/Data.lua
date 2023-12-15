local HttpService = game:GetService("HttpService")
local Data = {}

export type VectorTable = {
	x: number,
	y: number,
	z: number,
}

export type Stand = {
	asset: number,
	position: VectorTable,
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

return Data

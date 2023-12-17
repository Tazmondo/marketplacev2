export type Item = {
	creator: string,
	name: string,
	assetId: number,
	price: number?,
}

export type NetworkStand = {
	part: BasePart,
	assetId: number?,
}
export type Stand = {
	assetId: number?,
	roundedPosition: Vector3,
}

export type Showcase = {
	owner: number, -- UserId
	name: string,
	thumbId: number,
	primaryColor: Color3,
	accentColor: Color3,
	GUID: string,
	stands: { Stand },
}

export type ShowcaseMode = "View" | "Edit"

export type NetworkShowcase = {
	owner: number,
	name: string,
	thumbId: number,
	primaryColor: Color3,
	accentColor: Color3,
	GUID: string,

	-- This would be a table with basepart keys but instance keys can't be sent across network boundaries
	stands: { NetworkStand },
	model: Model,
	mode: ShowcaseMode,
}

return {}

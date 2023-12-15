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
	name: string,
	owner: number, -- UserId
	stands: { Stand },
	GUID: string,
}

export type ShowcaseMode = "View" | "Edit"

export type NetworkShowcase = {
	name: string,
	owner: number,

	-- This would be a table with basepart keys but instance keys can't be sent across network boundaries
	stands: { NetworkStand },
	GUID: string,
	mode: ShowcaseMode,
}

return {}

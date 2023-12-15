export type Item = {
	creator: string,
	name: string,
	assetId: number,
	price: number?,
}

export type NetworkStand = {
	part: BasePart,
	item: Item?,
}
export type Stand = {
	item: number?,
	roundedPosition: Vector3,
}

export type Showcase = {
	name: string,
	owner: number, -- UserId
	stands: { Stand },
	GUID: string,
}

return {}

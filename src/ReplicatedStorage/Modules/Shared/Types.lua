local Layouts = require(script.Parent.Layouts)
export type Item = {
	creator: string,
	name: string,
	assetId: number,
	price: number?,
}

export type Stand = {
	assetId: number?,
	roundedPosition: Vector3,
}

export type Showcase = {
	owner: number, -- UserId
	layoutId: Layouts.LayoutId,
	name: string,
	thumbId: number,
	primaryColor: Color3,
	accentColor: Color3,
	texture: string,
	GUID: string,
	stands: { Stand },
}

export type ShowcaseMode = "View" | "Edit"
export type NetworkShowcase = {
	owner: number,
	layoutId: Layouts.LayoutId,
	name: string,
	thumbId: number,
	primaryColor: Color3,
	accentColor: Color3,
	texture: string,
	GUID: string,

	-- This would be a table with basepart keys but instance keys can't be sent across network boundaries
	stands: { Stand },
	mode: ShowcaseMode,
}

export type LaunchData = {
	ownerId: number,
	GUID: string,
}

return {}

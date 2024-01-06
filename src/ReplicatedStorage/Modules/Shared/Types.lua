--!nolint LocalShadow
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Guard = require(ReplicatedStorage.Packages.Guard)
export type Item = {
	creator: string,
	name: string,
	assetId: number,
	price: number?,
	owned: boolean?,
}

export type Stand = {
	assetId: number?,
	roundedPosition: Vector3,
}

export type Showcase = {
	owner: number, -- UserId
	layoutId: LayoutData.LayoutId,
	name: string,
	thumbId: number,
	logoId: number?,
	primaryColor: Color3,
	accentColor: Color3,
	texture: string,
	GUID: string,
	stands: { Stand },
}

export type ShowcaseMode = "View" | "Edit"

export type NetworkShowcase = {
	owner: number,
	layoutId: LayoutData.LayoutId,
	name: string,
	thumbId: number,
	logoId: number?,
	primaryColor: Color3,
	accentColor: Color3,
	texture: string,
	GUID: string,

	-- This would be a table with vector3 keys but instance keys can't be sent across network boundaries
	stands: { Stand },
	mode: ShowcaseMode,
}

export type LaunchData = {
	ownerId: number,
	GUID: string,
}

export type FeedType = "Editor" | "Popular" | "Random"
function GuardFeed(value: unknown): FeedType
	local value: any = value

	assert(value == "Editor" or value == "Random" or value == "Popular")
	return value
end

export type FeedData = {
	showcases: { Showcase },
	type: FeedType,
	viewedUser: number?, -- When nil, user is on a feed. When set, user is viewing
}

export type CreatorMode = "All" | "User" | "Group"

export type SearchParams = {
	SearchKeyword: string?,
	CreatorName: string?,
	MinPrice: number?,
	MaxPrice: number?,
	IncludeOffSale: boolean?,
	SortType: number?, -- Enum.CatalogSortType
	CreatorMode: CreatorMode,
}
function GuardSearchParams(value: unknown): SearchParams
	local data: any = value
	assert(data.CreatorMode == "All" or data.CreatorMode == "User" or data.CreatorMode == "Group")
	assert(typeof(data.SortType) == "number" and Enum.CatalogSortType:GetEnumItems()[data.SortType])

	return {
		SearchKeyword = Guard.Optional(Guard.String)(data.SearchKeyword),
		CreatorName = Guard.Optional(Guard.String)(data.CreatorName),
		MinPrice = Guard.Optional(Guard.Number)(data.MinPrice),
		MaxPrice = Guard.Optional(Guard.Number)(data.MaxPrice),
		IncludeOffSale = Guard.Optional(Guard.Boolean)(data.IncludeOffSale),
		SortType = data.SortType,
		CreatorMode = data.CreatorMode,
	}
end

export type HumanoidDescriptionAccessory = typeof(Instance.new("HumanoidDescription"):GetAccessories(true)[1])
function GuardHumanoidDescriptionAccessory(accessory: unknown): HumanoidDescriptionAccessory
	local data: any = accessory

	return {
		AccessoryType = data.AccessoryType,
		AssetId = Guard.Number(data.AssetId),
		IsLayered = Guard.Boolean(data.IsLayered),
		Order = Guard.Optional(Guard.Number)(data.Order),
		Puffiness = Guard.Optional(Guard.Number)(data.Puffiness),
	}
end

return {
	GuardFeed = GuardFeed,
	GuardSearchParams = GuardSearchParams,
	GuardHumanoidDescriptionAccessory = GuardHumanoidDescriptionAccessory,
}

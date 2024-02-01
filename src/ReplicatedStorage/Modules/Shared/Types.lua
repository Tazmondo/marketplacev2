--!nolint LocalShadow
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Guard = require(ReplicatedStorage.Packages.Guard)

-- Classic clothing
export type StandType = "Accessory" | "TShirt" | "Shirt" | "Pants"
local function GuardStandType(value: unknown): StandType
	local value: any = value

	assert(value == "Accessory" or value == "TShirt" or value == "Shirt" or value == "Pants")
	return value
end
export type Stand = {
	item: {
		id: number,
		type: StandType,
	}?,
	roundedPosition: Vector3,
	[string]: never,
}

export type SerializedDescription = { string | number }

export type OutfitStand = {
	description: SerializedDescription?,
	roundedPosition: Vector3,
	[string]: never,
}

export type Shop = {
	owner: number, -- UserId
	layoutId: LayoutData.LayoutId,
	storefrontId: LayoutData.StorefrontId,
	name: string,
	thumbId: number,
	logoId: number?,
	primaryColor: Color3,
	accentColor: Color3,
	texture: string,
	GUID: string,
	shareCode: number?,
	stands: { Stand },
	outfitStands: { OutfitStand },
	[string]: never,
}

export type SpawnMode = "Server" | "Player"

-- For displaying in UI
export type NetworkShopDetails = {
	owner: number,
	name: string,
	thumbId: number,
	logoId: number?,
	primaryColor: Color3,
	accentColor: Color3,
	GUID: string,
	shareCode: number?,
	[string]: never,
}

export type Outfit = {
	name: string,
	description: HumanoidDescription,
	[string]: never,
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
	shops: { Shop },
	type: FeedType,
	viewedUser: number?, -- When nil, user is on a feed. When set, user is viewing
}

export type CreatorMode = "All" | "User" | "Group"

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
	GuardHumanoidDescriptionAccessory = GuardHumanoidDescriptionAccessory,
	GuardStandType = GuardStandType,
}

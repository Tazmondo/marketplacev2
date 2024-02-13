--!nolint LocalShadow
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

export type UpdateSettings = {
	name: string,
	primaryColor: Color3,
	accentColor: Color3,
	thumbId: number,
	logoId: number?,
	texture: string,
}

export type LoadShopSettings = { shop: Types.Shop, spawnMode: Types.SpawnMode }?

export type GetClothingSettings = {
	id: number,
	type: Types.StandType,
}

local function GuardUpdateSettings(settings: unknown)
	local value: any = settings
	return {
		name = Guard.String(value.name),
		primaryColor = Guard.Color3(value.primaryColor),
		accentColor = Guard.Color3(value.accentColor),
		thumbId = Guard.Number(value.thumbId),
		texture = Guard.String(value.texture),
		logoId = Guard.Optional(Guard.Number)(value.logoId),
	}
end

return {
	CreateShop = Red.Function("Shop_CreateShop", function()
		return
	end, function(guid)
		return Guard.Optional(Guard.String)(guid)
	end),

	DeleteShop = Red.SharedEvent("Shop_DeleteShop", function(guid)
		return Guard.String(guid)
	end),

	ClaimShop = Red.SharedEvent("Shop_Claim", function(shopCFrame, guid)
		return Guard.CFrame(shopCFrame), Guard.String(guid)
	end),

	UpdateStand = Red.SharedEvent("Shop_UpdateStand", function(roundedPosition, assetId)
		return Guard.Vector3(roundedPosition), Guard.Optional(Guard.Number)(assetId)
	end),

	UpdateOutfitStand = Red.SharedEvent("Shop_UpdateOutfitStand", function(roundedPosition, description)
		return Guard.Vector3(roundedPosition), Guard.Optional(HumanoidDescription.Guard)(description)
	end),

	UpdateSettings = Red.SharedEvent("Shop_UpdateSettings", function(settings)
		return GuardUpdateSettings(settings)
	end),

	UpdateLayout = Red.SharedEvent("Shop_UpdateLayout", function(layoutId)
		return Layouts:GuardLayoutId(layoutId)
	end),

	UpdateStorefront = Red.SharedEvent("Shop_UpdateStorefront", function(storefrontId)
		return Layouts:GuardStorefrontId(storefrontId)
	end),

	GetStandItem = Red.Function("Shop_GetClothingModel", function(data)
		local data: any = data
		return {
			id = Guard.Number(data.id),
			type = Types.GuardStandType(data.type),
		} :: GetClothingSettings
	end, function(model)
		return model :: Model?
	end),

	-- Server-Fired, no need to type check.
	-- If nil then unload shop
	LoadShop = Red.SharedEvent("Shop_LoadShop", function(cframe, options)
		return Guard.CFrame(cframe), options :: LoadShopSettings
	end),

	SetRandomShopTimer = Red.SharedEvent("Shop_StartRandomShopTimer", function(cframe, paused)
		return Guard.CFrame(cframe), Guard.Boolean(paused)
	end),

	GetOwnerPasses = Red.Function("Shop_OwnerPasses", function(owner)
		return Guard.Number(owner)
	end, function(passes)
		return passes :: { Types.Pass }
	end),
}

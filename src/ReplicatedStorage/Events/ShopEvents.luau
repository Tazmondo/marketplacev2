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
	CreateShop = Red.SharedEvent("Shop_CreateShop", function()
		return
	end),

	DeleteShop = Red.SharedEvent("Shop_DeleteShop", function(guid)
		return Guard.String(guid)
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

	GetAccessoryModel = Red.Function("Shop_GetAccessory", function(id)
		return Guard.Number(id)
	end, function(model)
		return model :: Model?
	end),

	-- Server-Fired, no need to type check.
	-- If nil then unload shop
	LoadShop = Red.SharedEvent("Shop_LoadShop", function(cframe, options)
		return Guard.CFrame(cframe), options :: LoadShopSettings
	end),
}

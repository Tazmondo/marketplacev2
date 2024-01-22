local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
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
	UpdateStand = Red.SharedEvent("Showcase_UpdateStnad", function(roundedPosition, assetId)
		return Guard.Vector3(roundedPosition), Guard.Optional(Guard.Number)(assetId)
	end),

	UpdateOutfitStand = Red.SharedEvent("Showcase_UpdateOutfitStand", function(roundedPosition, description)
		return Guard.Vector3(roundedPosition), Guard.Optional(HumanoidDescription.Guard)(description)
	end),

	UpdateSettings = Red.SharedEvent("Showcase_UpdateSettings", function(settings)
		return GuardUpdateSettings(settings)
	end),

	UpdateLayout = Red.SharedEvent("Showcase_UpdateLayout", function(layoutId)
		return Layouts:GuardLayoutId(layoutId)
	end),
}

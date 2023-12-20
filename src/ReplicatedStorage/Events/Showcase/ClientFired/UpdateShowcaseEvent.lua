local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

export type UpdateStand = {
	type: "UpdateStand",
	roundedPosition: Vector3,
	assetId: number?,
}

export type UpdateSettings = {
	type: "UpdateSettings",
	name: string,
	primaryColor: Color3,
	accentColor: Color3,
	thumbId: number,
	texture: string,
}

export type UpdateLayout = {
	type: "UpdateLayout",
	layoutId: Layouts.LayoutId,
}

export type Update = UpdateStand | UpdateSettings | UpdateLayout

function GuardUpdate(update: unknown): Update
	assert(typeof(update) == "table")

	local value: any = update
	if value.type == "UpdateStand" then
		return {
			type = "UpdateStand",
			roundedPosition = Guard.Vector3(value.roundedPosition),
			assetId = Guard.Optional(Guard.Number)(value.assetId),
		}
	elseif value.type == "UpdateSettings" then
		return {
			type = "UpdateSettings",
			name = Guard.String(value.name),
			primaryColor = Guard.Color3(value.primaryColor),
			accentColor = Guard.Color3(value.accentColor),
			thumbId = Guard.Number(value.thumbId),
			texture = Guard.String(value.texture),
		}
	elseif value.type == "UpdateLayout" then
		return {
			type = "UpdateLayout",
			layoutId = Layouts:GuardLayoutId(value.layoutId),
		}
	else
		error("Unexpected update type")
	end
end

return Red.Event("Showcase_UpdateShowcase", function(update)
	print(update)
	return GuardUpdate(update)
end)

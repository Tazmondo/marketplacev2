local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
}

export type Update = UpdateStand | UpdateSettings

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
		}
	else
		error("Unexpected update type")
	end
end

return Red.Event("Showcase_UpdateShowcase", function(update)
	print(update)
	return GuardUpdate(update)
end)

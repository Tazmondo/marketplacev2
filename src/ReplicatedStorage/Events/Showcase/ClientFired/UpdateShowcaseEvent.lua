local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InstanceGuard = require(ReplicatedStorage.Modules.Shared.InstanceGuard)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

export type UpdateStand = {
	type: "UpdateStand",
	part: BasePart,
	assetId: number?,
}

export type UpdateSettings = {
	-- TODO
	type: "UpdateSettings",
}

export type Update = UpdateStand | UpdateSettings

function GuardUpdate(update: unknown): Update
	assert(typeof(update) == "table")

	local value: any = update
	if value.type == "UpdateStand" then
		return {
			type = "UpdateStand",
			part = InstanceGuard.BasePart(value.part),
			assetId = Guard.Optional(Guard.Number)(value.assetId),
		}
	elseif value.type == "UpdateSettings" then
		return {
			type = "UpdateSettings",
		}
	else
		error("Unexpected update type")
	end
end

return Red.Event("Showcase_UpdateShowcase", function(update)
	return GuardUpdate(update)
end)

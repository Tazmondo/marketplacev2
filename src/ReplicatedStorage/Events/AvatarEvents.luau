local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InstanceGuard = require(ReplicatedStorage.Modules.Shared.InstanceGuard)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

export type Accessory = {
	id: number,
	assetType: Enum.AvatarAssetType,
}

local function GuardNetworkedAccessory(accessory: unknown): Accessory
	local value: any = accessory
	assert(typeof(value.assetType) == "EnumItem")
	return {
		id = Guard.Number(value.id),
		assetType = value.assetType :: Enum.AvatarAssetType,
	}
end

return {
	ApplyDescription = Red.SharedEvent("Avatar_ApplyDescription", function(accessories)
		return Guard.List(GuardNetworkedAccessory)(accessories)
	end),

	GenerateModel = Red.Function("Avatar_GenerateModel", function(accessories)
		return Guard.List(GuardNetworkedAccessory)(accessories)
	end, function(model)
		return Guard.Optional(InstanceGuard.Model)(model)
	end),
}

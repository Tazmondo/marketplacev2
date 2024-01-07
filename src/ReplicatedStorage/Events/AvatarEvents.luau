local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InstanceGuard = require(ReplicatedStorage.Modules.Shared.InstanceGuard)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

return {
	ApplyDescription = Red.SharedEvent("Avatar_ApplyDescription", function(accessories)
		return Guard.List(Guard.Number)(accessories)
	end),

	GenerateModel = Red.Function("Avatar_GenerateModel", function(accessories)
		return Guard.List(Guard.Number)(accessories)
	end, function(model)
		return Guard.Optional(InstanceGuard.Model)(model)
	end),
}

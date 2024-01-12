local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local InstanceGuard = require(ReplicatedStorage.Modules.Shared.InstanceGuard)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

return {
	ApplyDescription = Red.SharedEvent("Avatar_ApplyDescription", function(description)
		return HumanoidDescription.Guard(description)
	end),

	GenerateModel = Red.Function("Avatar_GenerateModel", function(description)
		return HumanoidDescription.Guard(description)
	end, function(model)
		return Guard.Optional(InstanceGuard.Model)(model)
	end),
}

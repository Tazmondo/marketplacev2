local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

return Red.Event("ApplyDescription", function(accessories)
	return Guard.List(Types.GuardHumanoidDescriptionAccessory)(accessories)
end)

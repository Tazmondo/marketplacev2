local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

return Red.Event("ApplyDescription", function(accessories)
	return Guard.List(Guard.Number)(accessories)
end)

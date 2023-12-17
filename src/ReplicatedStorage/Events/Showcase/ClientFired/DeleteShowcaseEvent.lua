local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)
return Red.Event("Showcase_DeleteShowcase", function(guid)
	return Guard.String(guid)
end)

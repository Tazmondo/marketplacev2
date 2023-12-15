local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Red = require(ReplicatedStorage.Packages.Red)
return Red.Event("Showcase_EnterShowcase", function(showcase)
	return showcase :: Types.NetworkShowcase?
end)

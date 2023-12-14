local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Types)
local Red = require(ReplicatedStorage.Packages.Red)

-- This is a server -> client operation so no need for runtime type checking
return Red.Event("Place_UpdateStands", function(stands)
	return stands :: { Types.NetworkStand }
end)

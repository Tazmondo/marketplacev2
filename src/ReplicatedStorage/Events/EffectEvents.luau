local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

return {
	Purchase = Red.SharedEvent("Effect_Purchaser", function(position)
		return Guard.Vector3(position)
	end),
}

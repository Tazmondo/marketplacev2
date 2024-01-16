local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)
return {
	Asset = Red.SharedEvent("Purchase_Asset", function(id)
		return Guard.Number(id)
	end),
}

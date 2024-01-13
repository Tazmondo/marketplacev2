local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

return {
	ReplicateData = Red.SharedEvent("Data_ReplicateData", function(data)
		return data :: Data.Data
	end),

	CreateOutfit = Red.SharedEvent("Data_CreateOutfit", function(name, serDescription)
		return Guard.String(name), HumanoidDescription.Guard(serDescription)
	end),
}

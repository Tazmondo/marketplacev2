local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

return {
	ReplicateData = Red.SharedEvent("Data_ReplicateData", function(data)
		return data :: Data.Data
	end),

	CreateOutfit = Red.SharedEvent("Data_CreateOutfit", function(name, serDescription)
		return Guard.String(name), HumanoidDescription.Guard(serDescription)
	end),

	DeleteOutfit = Red.SharedEvent("Data_DeleteOutfit", function(name, serDescription)
		return Guard.String(name), HumanoidDescription.Guard(serDescription)
	end),

	GetShowcaseDetails = Red.Function("Data_ShowcaseDetails", function(shareCode)
		return Guard.Number(shareCode)
	end, function(details)
		return details :: Types.NetworkShowcaseDetails?
	end),
}

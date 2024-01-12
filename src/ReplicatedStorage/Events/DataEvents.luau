local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Red = require(ReplicatedStorage.Packages.Red)
return {
	ReplicateData = Red.SharedEvent("Data_ReplicateData", function(data)
		return data :: Data.Data
	end),
}

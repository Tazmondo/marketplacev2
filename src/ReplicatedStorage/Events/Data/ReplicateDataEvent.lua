local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Red = require(ReplicatedStorage.Packages.Red)
return Red.Event("Data_ReplicateData", function(data)
	return data :: Data.Data
end)

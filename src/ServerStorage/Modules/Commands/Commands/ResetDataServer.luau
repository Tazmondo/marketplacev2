local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Data = require(ReplicatedStorage.Modules.Shared.Data)
local DataService = require(ServerStorage.Modules.Data.DataService)
return function(context, players)
	for _, player in players do
		DataService:WriteData(player, function(data)
			for key, value in pairs(Data.dataTemplate) do
				data[key] = value
			end
		end)
	end
end

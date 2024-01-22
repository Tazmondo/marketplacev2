local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Red = require(ReplicatedStorage.Packages.Red)

return Red.SharedEvent("PlayerVisibility", function(players)
	return players :: { Player }
end)

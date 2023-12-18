local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Red = require(ReplicatedStorage.Packages.Red)
return Red.Event("Showcase_UpdateVisiblePlayers", function(players)
	return players :: { Player }
end)

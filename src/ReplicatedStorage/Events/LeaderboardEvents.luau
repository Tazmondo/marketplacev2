local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Red = require(ReplicatedStorage.Packages.Red)

export type LeaderboardUpdateData = {
	id: number,
	data: number,
}

export type LeaderboardName = "Raised" | "Purchases"

return {
	Update = Red.SharedEvent("Leaderboard", function(name, data)
		return name :: LeaderboardName, data :: { LeaderboardUpdateData }
	end),
}

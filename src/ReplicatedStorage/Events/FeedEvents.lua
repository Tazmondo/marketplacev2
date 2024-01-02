local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

return {
	Move = Red.SharedEvent("Feed_MoveFeed", function(index)
		return Guard.Number(index)
	end),

	Switch = Red.SharedEvent("Feed_SwitchFeed", function(feed)
		return Types.GuardFeed(feed)
	end),

	Update = Red.SharedEvent("Feed_UpdateFeed", function(feed)
		return feed :: Types.FeedData
	end),
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Red = require(ReplicatedStorage.Packages.Red)
return Red.Event("Feed_UpdateFeed", function(feed)
	return feed :: Types.FeedData
end)

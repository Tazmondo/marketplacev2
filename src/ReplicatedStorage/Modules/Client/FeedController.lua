local FeedController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FeedEvents = require(ReplicatedStorage.Events.FeedEvents)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)

FeedController.Updated = Signal()

local currentFeed: Types.FeedData?
local currentIndex: number?

function FeedController:BumpIndex(bumpAmount: number)
	if not currentFeed or not currentIndex then
		return
	end

	local newIndex = math.clamp(currentIndex + bumpAmount, 0, #currentFeed.shops)
	currentIndex = newIndex

	FeedEvents.Move:FireServer(newIndex)

	FeedController.Updated:Fire(currentFeed, newIndex)
end

function HandleUpdateFeed(feed: Types.FeedData)
	local newIndex = 1

	-- Preserve the index so it still matches up with the current shop if the feed has changed in some way
	if currentFeed and currentIndex and currentFeed.viewedUser == feed.viewedUser and currentFeed.type == feed.type then
		local difference = #feed.shops - #currentFeed.shops
		if
			difference >= 0
			and feed.shops[currentIndex]
			and feed.shops[currentIndex].GUID == currentFeed.shops[currentIndex].GUID
		then
			-- List has only grown so keep index the same
			newIndex = currentIndex
		end
	end

	currentIndex = newIndex
	currentFeed = feed

	FeedController.Updated:Fire(feed, newIndex)
end

function FeedController:Initialize()
	FeedEvents.Update:SetClientListener(HandleUpdateFeed)
end

FeedController:Initialize()

return FeedController

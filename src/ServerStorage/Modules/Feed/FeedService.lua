local FeedService = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local FeedEvents = require(ReplicatedStorage.Events.FeedEvents)
local RandomFeed = require(script.Parent.RandomFeed)
local DataService = require(ServerStorage.Modules.Data.DataService)
local ShowcaseService = require(ServerStorage.Modules.ShowcaseService)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Material = require(ReplicatedStorage.Modules.Shared.Material)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Base64 = require(ReplicatedStorage.Packages.Base64)
local Future = require(ReplicatedStorage.Packages.Future)
local Guard = require(ReplicatedStorage.Packages.Guard)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

function GuardJoinData(data: unknown): Types.LaunchData
	local value: any = data

	return {
		ownerId = Guard.Number(value.ownerId),
		GUID = Guard.String(value.GUID),
	}
end

-- Only used if no other feeds can be fetched
local DefaultShowcase: Types.Showcase = {
	name = "Untitled Shop",
	owner = 68252170,
	layoutId = Config.DefaultLayout,
	stands = {},
	outfitStands = {},
	GUID = HttpService:GenerateGUID(false),
	primaryColor = Config.DefaultPrimaryColor,
	accentColor = Config.DefaultAccentColor,
	thumbId = Config.DefaultShopThumbnail,
	texture = Material:GetDefault(),
}
TableUtil.Lock(DefaultShowcase)

local feedData: { [Player]: Types.FeedData? } = {}

local cachedEditorPicks: { Types.Showcase }? = nil

function GetEditorsPicks()
	return Future.new(function(): { Types.Showcase }?
		if cachedEditorPicks then
			return cachedEditorPicks
		end

		local editorId = 2294598404
		local editorData = DataService:ReadOfflineData(editorId):Await()
		if not editorData then
			warn("Could not fetch editor data")
			return nil
		end

		local editorPicks = {}

		for i, showcase in editorData.showcases do
			editorPicks[i] = Data.FromDataShowcase(showcase, editorId)
		end

		cachedEditorPicks = editorPicks
		return editorPicks
	end)
end

function GetShowcase(ownerId: number, showcaseGUID: string)
	return Future.new(function()
		local ownerData = DataService:ReadOfflineData(ownerId):Await()
		if not ownerData then
			return nil :: Types.Showcase?
		end

		local showcase = TableUtil.Find(ownerData.showcases, function(showcase)
			return showcase.GUID == showcaseGUID
		end)
		if showcase then
			return Data.FromDataShowcase(showcase, ownerId)
		end
		return nil
	end)
end

function PlayerAdded(player: Player)
	local joinData = player:GetJoinData()
	local encodedLaunchData: string? = joinData.LaunchData

	local launchData: Types.LaunchData?

	if encodedLaunchData then
		local success, data = pcall(function()
			local json = Base64.decode(encodedLaunchData)
			local data = GuardJoinData(HttpService:JSONDecode(json))
			print("User had join data:")
			Util.PrettyPrint(data)
			return data
		end)

		if not success then
			print("Join Data failed: ", data)
		else
			launchData = data
		end
	end

	local targetedShowcase = if launchData then GetShowcase(launchData.ownerId, launchData.GUID):Await() else nil
	local showcases

	if targetedShowcase then
		showcases = { targetedShowcase }
	else
		if Config.DefaultFeed == "Editor" then
			local editorPicks = GetEditorsPicks():Await()

			if editorPicks then
				showcases = editorPicks
			else
				showcases = { TableUtil.Copy(DefaultShowcase, true) }
			end
		elseif Config.DefaultFeed == "Random" then
			showcases = RandomFeed.GetFeed(1):Await() or { TableUtil.Copy(DefaultShowcase, true) }
		end
	end

	local data = {
		showcases = showcases,
		type = Config.DefaultFeed,
	}

	feedData[player] = data

	FeedEvents.Update:FireClient(player, data)

	local showcase = showcases[1]

	local place = ShowcaseService:GetShowcase(showcase, "View")

	player:LoadCharacter()
	ShowcaseService:EnterPlayerShowcase(player, place)
end

function PlayerRemoving(player: Player)
	feedData[player] = nil
end

function HandleMoveFeed(player: Player, newIndex: number)
	local playerFeedData = feedData[player]
	if not playerFeedData then
		return
	end

	local showcase = playerFeedData.showcases[newIndex]
	if not showcase then
		return
	end

	if playerFeedData.type == "Random" then
		-- Always try and load 10 showcases ahead
		-- Don't need to use the returned value because it's already handled in the signal connection
		RandomFeed.GetFeed(newIndex + 10)
	end

	local place = ShowcaseService:GetShowcase(showcase, "View")
	ShowcaseService:EnterPlayerShowcase(player, place)
end

function HandleSwitchFeed(player: Player, type: Types.FeedType)
	local data = feedData[player]
	if not data then
		return
	end

	data.showcases = {}

	if data.type == type and not data.viewedUser then
		return
	end

	local feed
	if type == "Editor" then
		feed = GetEditorsPicks():Await()
	elseif type == "Random" then
		feed = RandomFeed.GetFeed(3):Await()
	elseif type == "Popular" then
		feed = { TableUtil.Copy(DefaultShowcase, true) }
	end

	if not feed or #feed <= 0 then
		return
	end

	data.showcases = feed
	data.type = type
	data.viewedUser = nil

	FeedEvents.Update:FireClient(player, data)

	local firstShowcase = ShowcaseService:GetShowcase(feed[1], "View")
	ShowcaseService:EnterPlayerShowcase(player, firstShowcase)
end

local userSearchRateLimit = Util.RateLimit(1, 6)
function HandleUserFeed(player: Player, userId: number)
	if not userSearchRateLimit(player) then
		return false
	end

	local feed = feedData[player]
	if not feed then
		return false
	end

	local targetData = DataService:ReadOfflineData(userId):Await()
	if not targetData then
		return false
	end

	local showcases = {}
	for i, showcase in targetData.showcases do
		table.insert(showcases, Data.FromDataShowcase(showcase, userId))
	end

	if #showcases == 0 then
		return false
	end

	feed.viewedUser = userId
	feed.showcases = showcases

	FeedEvents.Update:FireClient(player, feed)

	local firstShowcase = ShowcaseService:GetShowcase(feed.showcases[1], "View")
	ShowcaseService:EnterPlayerShowcase(player, firstShowcase)

	return true
end

function HandleRandomFeedUpdated(feed: { Types.Showcase })
	for player, data in feedData do
		assert(data)

		if data.type == "Random" then
			data.showcases = feed
			FeedEvents.Update:FireClient(player, data)
		end
	end
end

function FeedService:Initialize()
	Players.CharacterAutoLoads = false

	Players.PlayerAdded:Connect(PlayerAdded)
	for i, player in Players:GetPlayers() do
		PlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(PlayerRemoving)

	FeedEvents.Move:SetServerListener(HandleMoveFeed)
	FeedEvents.Switch:SetServerListener(function(player, type)
		HandleSwitchFeed(player, type :: Types.FeedType)
	end)
	FeedEvents.User:SetCallback(HandleUserFeed)

	-- TODO: Remove me
	local rateLimit = Util.RateLimit(2, 6)
	FeedEvents.LoadShowcaseWithId:SetServerListener(function(player, shareCode)
		if not rateLimit(player) then
			return
		end

		local owner, guid = DataService:GetShareCodeData(shareCode):Await()
		if not owner or not guid then
			return
		end

		local ownerData = DataService:ReadOfflineData(owner):Await()
		if not ownerData then
			return nil
		end

		local dataShowcase = TableUtil.Find(ownerData.showcases, function(showcase)
			return showcase.GUID == guid
		end)

		if not dataShowcase then
			return nil
		end

		local showcase = Data.FromDataShowcase(dataShowcase, owner)

		local feed = feedData[player]
		if not feed then
			return false
		end

		feed.viewedUser = owner
		feed.showcases = { showcase }

		FeedEvents.Update:FireClient(player, feed)

		local activeShowcase = ShowcaseService:GetShowcase(showcase, "View")
		ShowcaseService:EnterPlayerShowcase(player, activeShowcase)
	end)

	RandomFeed.Extended:Connect(HandleRandomFeedUpdated)
end

FeedService:Initialize()

return FeedService

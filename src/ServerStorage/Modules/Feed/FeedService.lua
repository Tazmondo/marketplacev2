local FeedService = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local FeedEvents = require(ReplicatedStorage.Events.FeedEvents)
local RandomFeed = require(script.Parent.RandomFeed)
local DataService = require(ServerStorage.Modules.Data.DataService)
local ShopService = require(ServerStorage.Modules.ShopService)
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
local DefaultShop: Types.Shop = {
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
TableUtil.Lock(DefaultShop)

local feedData: { [Player]: Types.FeedData? } = {}

local cachedEditorPicks: { Types.Shop }? = nil

function GetEditorsPicks()
	return Future.new(function(): { Types.Shop }?
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

		for i, shop in editorData.shops do
			editorPicks[i] = Data.FromDataShop(shop, editorId)
		end

		cachedEditorPicks = editorPicks
		return editorPicks
	end)
end

function GetShop(ownerId: number, shopGUID: string)
	return Future.new(function()
		local ownerData = DataService:ReadOfflineData(ownerId):Await()
		if not ownerData then
			return nil :: Types.Shop?
		end

		local shop = TableUtil.Find(ownerData.shops, function(shop)
			return shop.GUID == shopGUID
		end)
		if shop then
			return Data.FromDataShop(shop, ownerId)
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

	local targetedShop = if launchData then GetShop(launchData.ownerId, launchData.GUID):Await() else nil
	local shops

	if targetedShop then
		shops = { targetedShop }
	else
		if Config.DefaultFeed == "Editor" then
			local editorPicks = GetEditorsPicks():Await()

			if editorPicks then
				shops = editorPicks
			else
				shops = { TableUtil.Copy(DefaultShop, true) }
			end
		elseif Config.DefaultFeed == "Random" then
			shops = RandomFeed.GetFeed(1):Await() or { TableUtil.Copy(DefaultShop, true) }
		end
	end

	local data = {
		shops = shops,
		type = Config.DefaultFeed,
	}

	feedData[player] = data

	FeedEvents.Update:FireClient(player, data)

	local shop = shops[1]

	local place = ShopService:GetShop(shop, "View")

	player:LoadCharacter()
	ShopService:EnterPlayerShop(player, place)
end

function PlayerRemoving(player: Player)
	feedData[player] = nil
end

function HandleMoveFeed(player: Player, newIndex: number)
	local playerFeedData = feedData[player]
	if not playerFeedData then
		return
	end

	local shop = playerFeedData.shops[newIndex]
	if not shop then
		return
	end

	if playerFeedData.type == "Random" then
		-- Always try and load 10 shops ahead
		-- Don't need to use the returned value because it's already handled in the signal connection
		RandomFeed.GetFeed(newIndex + 10)
	end

	local place = ShopService:GetShop(shop, "View")
	ShopService:EnterPlayerShop(player, place)
end

function HandleSwitchFeed(player: Player, type: Types.FeedType)
	local data = feedData[player]
	if not data then
		return
	end

	data.shops = {}

	if data.type == type and not data.viewedUser then
		return
	end

	local feed
	if type == "Editor" then
		feed = GetEditorsPicks():Await()
	elseif type == "Random" then
		feed = RandomFeed.GetFeed(3):Await()
	elseif type == "Popular" then
		feed = { TableUtil.Copy(DefaultShop, true) }
	end

	if not feed or #feed <= 0 then
		return
	end

	data.shops = feed
	data.type = type
	data.viewedUser = nil

	FeedEvents.Update:FireClient(player, data)

	local firstShop = ShopService:GetShop(feed[1], "View")
	ShopService:EnterPlayerShop(player, firstShop)
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

	local shops = {}
	for i, shop in targetData.shops do
		table.insert(shops, Data.FromDataShop(shop, userId))
	end

	if #shops == 0 then
		return false
	end

	feed.viewedUser = userId
	feed.shops = shops

	FeedEvents.Update:FireClient(player, feed)

	local firstShop = ShopService:GetShop(feed.shops[1], "View")
	ShopService:EnterPlayerShop(player, firstShop)

	return true
end

function HandleRandomFeedUpdated(feed: { Types.Shop })
	for player, data in feedData do
		assert(data)

		if data.type == "Random" then
			data.shops = feed
			FeedEvents.Update:FireClient(player, data)
		end
	end
end

function FeedService:Initialize()
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
	FeedEvents.LoadShopWithId:SetServerListener(function(player, shareCode)
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

		local dataShop = TableUtil.Find(ownerData.shops, function(shop)
			return shop.GUID == guid
		end)

		if not dataShop then
			return nil
		end

		local shop = Data.FromDataShop(dataShop, owner)

		local feed = feedData[player]
		if not feed then
			return false
		end

		feed.viewedUser = owner
		feed.shops = { shop }

		FeedEvents.Update:FireClient(player, feed)

		local activeShop = ShopService:GetShop(shop, "View")
		ShopService:EnterPlayerShop(player, activeShop)
	end)

	RandomFeed.Extended:Connect(HandleRandomFeedUpdated)
end

-- FeedService:Initialize()

return FeedService

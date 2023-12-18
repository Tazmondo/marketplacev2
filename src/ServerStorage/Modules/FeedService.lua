local FeedService = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.DataService)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Base64 = require(ReplicatedStorage.Packages.Base64)
local Future = require(ReplicatedStorage.Packages.Future)
local Guard = require(ReplicatedStorage.Packages.Guard)
local ShowcaseService = require(script.Parent.ShowcaseService)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local MoveFeedEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.MoveFeedEvent):Server()
local UpdateFeedEvent = require(ReplicatedStorage.Events.Showcase.ServerFired.UpdateFeedEvent):Server()

function GuardJoinData(data: unknown): Types.LaunchData
	local value: any = data

	return {
		ownerId = Guard.Number(value.ownerId),
		GUID = Guard.String(value.GUID),
	}
end

type FeedData = { Types.Showcase }

local DefaultShowcase: Types.Showcase = {
	name = "Untitled Shop",
	owner = 68252170,
	stands = {},
	GUID = HttpService:GenerateGUID(false),
	primaryColor = Config.DefaultPrimaryColor,
	accentColor = Config.DefaultAccentColor,
	thumbId = Config.DefaultShopThumbnail,
}
TableUtil.Lock(DefaultShowcase)

local feedData: { [Player]: FeedData } = {}

local cachedEditorPicks: { Types.Showcase }? = nil

function GetEditorsPicks()
	return Future.new(function()
		if cachedEditorPicks then
			return cachedEditorPicks :: { Types.Showcase }?
		end

		local elijahId = 2294598404
		local editorData = DataService:ReadOfflineData(elijahId):Await()
		if not editorData then
			warn("Could not fetch editor data")
			return nil
		end

		local editorPicks = {}

		for i, showcase in editorData.showcases do
			editorPicks[i] = Data.FromDataShowcase(showcase, elijahId)
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

	if targetedShowcase then
		feedData[player] = { targetedShowcase }
	else
		local editorPicks = GetEditorsPicks():Await()

		if editorPicks then
			feedData[player] = editorPicks
		else
			feedData[player] = { TableUtil.Copy(DefaultShowcase, true) }
		end
	end

	UpdateFeedEvent:Fire(player, feedData[player])

	local showcase = feedData[player][1]

	-- Yields
	local place = ShowcaseService:GetShowcase(showcase, "View"):Await()

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

	local showcase = playerFeedData[newIndex]
	if not showcase then
		return
	end

	local place = ShowcaseService:GetShowcase(showcase, "View"):Await()
	ShowcaseService:EnterPlayerShowcase(player, place)
end

function FeedService:Initialize()
	Players.CharacterAutoLoads = false

	Players.PlayerAdded:Connect(PlayerAdded)
	for i, player in Players:GetPlayers() do
		PlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(PlayerRemoving)

	MoveFeedEvent:On(HandleMoveFeed)
end

FeedService:Initialize()

return FeedService

local FeedService = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.DataService)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)
local ShowcaseService = require(script.Parent.ShowcaseService)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local MoveFeedEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.MoveFeedEvent):Server()
local UpdateFeedEvent = require(ReplicatedStorage.Events.Showcase.ServerFired.UpdateFeedEvent):Server()

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

function PlayerAdded(player: Player)
	-- TODO: get actual feed
	local editorPicks = GetEditorsPicks():Await()

	if editorPicks then
		feedData[player] = editorPicks
	else
		feedData[player] = { TableUtil.Copy(DefaultShowcase, true) }
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

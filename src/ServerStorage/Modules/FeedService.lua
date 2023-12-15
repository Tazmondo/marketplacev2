local FeedService = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local ShowcaseService = require(script.Parent.ShowcaseService)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

type FeedData = { Types.Showcase }

local DefaultShowcase: Types.Showcase = {
	name = "N/A",
	owner = 68252170,
	stands = {},
	GUID = HttpService:GenerateGUID(false),
}
TableUtil.Lock(DefaultShowcase)

local feedData: { [Player]: FeedData } = {}

function PlayerAdded(player: Player)
	-- TODO: get actual feed
	local showcase = TableUtil.Copy(DefaultShowcase, true)
	feedData[player] = { showcase }

	-- Yields
	local place = ShowcaseService:GetShowcase(showcase, "View"):Await()

	player:LoadCharacter()
	ShowcaseService:EnterPlayerShowcase(player, place)
end

function PlayerRemoving(player: Player)
	feedData[player] = nil
end

function FeedService:Initialize()
	Players.CharacterAutoLoads = false

	Players.PlayerAdded:Connect(PlayerAdded)
	for i, player in Players:GetPlayers() do
		PlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(PlayerRemoving)
end

FeedService:Initialize()

return FeedService

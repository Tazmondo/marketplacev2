local LoadedService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Future = require(ReplicatedStorage.Packages.Future)
local Loaded = require(ReplicatedStorage.Events.LoadedEvent):Server()

local loadedAttribute = "LoadedService_Loaded"

function HandleLoaded(player: Player)
	player:SetAttribute(loadedAttribute, true)
end

function LoadedService:GetLoadedFuture(player: Player)
	return Future.new(function(player: Player)
		while player.Parent ~= nil and not player:GetAttribute(loadedAttribute) do
			task.wait()
		end

		return player.Parent ~= nil
	end, player)
end

function LoadedService:HasPlayerLoaded(player: Player)
	return player:GetAttribute(loadedAttribute) == true
end

function LoadedService:Initialize()
	Loaded:On(HandleLoaded)
end

LoadedService:Initialize()

return LoadedService

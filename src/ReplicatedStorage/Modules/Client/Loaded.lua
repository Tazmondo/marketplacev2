local Loaded = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LoadedEvent = require(ReplicatedStorage.Events.LoadedEvent):Client()
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)

local hasLoaded = false
local characterLoaded = false

local loadedSignal = Signal()
local characterLoadedSignal = Signal()

function Loaded:RegisterLoaded()
	if hasLoaded then
		return
	end
	hasLoaded = true
	loadedSignal:Fire()
	LoadedEvent:Fire()
end

function Loaded:HasLoaded()
	return hasLoaded
end

function Loaded:HasCharacterLoaded()
	return characterLoaded
end

function Loaded:LoadedFuture()
	return Future.new(function()
		if not hasLoaded then
			loadedSignal:Wait()
		end
	end)
end

function Loaded:CharacterLoadedFuture()
	return Future.new(function()
		if not characterLoaded then
			characterLoadedSignal:Wait()
		end
	end)
end

task.spawn(function()
	Loaded:LoadedFuture():Await()

	if not Players.LocalPlayer.Character then
		Players.LocalPlayer.CharacterAdded:Wait()
	end

	characterLoaded = true
	characterLoadedSignal:Fire()
end)

return Loaded

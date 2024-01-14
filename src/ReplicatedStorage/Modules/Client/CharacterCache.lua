-- Exists so outfits can be fetched instantly after the first time, rather than making a new request to the server every time
local CharacterCache = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)

local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)

local cache: { [string]: Model } = {}

function CharacterCache:LoadWithDescription(description: HumanoidDescription | Types.SerializedDescription)
	return Future.new(function(): Model?
		local serialized = if typeof(description) == "Instance"
			then HumanoidDescription.Serialize(description)
			else description

		local stringDescription = HumanoidDescription.Stringify(serialized)
		local cachedModel = cache[stringDescription]
		if cachedModel then
			return cachedModel:Clone()
		end

		local success, model = AvatarEvents.GenerateModel:Call(serialized):Await()
		if success and model then
			cache[stringDescription] = model:Clone()
			return model:Clone()
		else
			return nil
		end
	end)
end

return CharacterCache

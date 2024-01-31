-- Exists so outfits can be fetched instantly after the first time, rather than making a new request to the server every time
local CharacterCache = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)

local AvatarEvents = require(ReplicatedStorage.Events.AvatarEvents)

local cache: { [string]: Future.Future<Model?> } = {}

function CharacterCache:LoadWithDescription(description: HumanoidDescription | Types.SerializedDescription)
	return Future.new(function()
		local serialized = if typeof(description) == "Instance"
			then HumanoidDescription.Serialize(description)
			else description

		local stringDescription = HumanoidDescription.Stringify(serialized)
		local cachedModel = cache[stringDescription]
		if cachedModel then
			local model = cachedModel:Await()
			return if model then model:Clone() else nil
		end

		local future = Future.new(function(): Model?
			local success, model = AvatarEvents.GenerateModel:Call(serialized):Await()
			if success and model then
				local cloned = model:Clone()
				model:Destroy()

				return cloned
			else
				return nil
			end
		end)

		cache[stringDescription] = future
		local model = future:Await()
		return if model then model:Clone() else nil
	end)
end

return CharacterCache

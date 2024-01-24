local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local Future = require(ReplicatedStorage.Packages.Future)
local AccessoryCache = {}

local cache: { [number]: Model } = {}

function AccessoryCache:Get(id: number)
	return Future.new(function(id): Model?
		if cache[id] then
			return cache[id]:Clone()
		end

		-- The model is parented to playergui so it can be sent to the client
		local success, model = ShopEvents.GetAccessoryModel:Call(id):Await()

		-- If the cache was updated while we were fetching
		if cache[id] then
			return cache[id]:Clone()
		end

		if not success then
			warn(model)
			return nil
		end
		if not model then
			return nil
		end

		local cloned = model:Clone()

		for i, descendant in cloned:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end

		cache[id] = cloned
		model:Destroy()

		return cloned:Clone()
	end, id)
end

return AccessoryCache

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Future = require(ReplicatedStorage.Packages.Future)
local AccessoryCache = {}

local cache: { [number]: Future.Future<Model?> } = {}

function AccessoryCache:Get(id: number)
	return Future.new(function()
		local cached = cache[id]
		if cached then
			local model = cached:Await()
			return if model then model:Clone() else nil
		end

		local future = Future.new(function(id): Model?
			-- The model is parented to playergui so it can be sent to the client
			local success, model = ShopEvents.GetAccessoryModel:Call(id):Await()

			if not success then
				warn(model)
				return nil
			end
			if not model then
				return nil
			end

			model:AddTag(Config.RenderedAccessoryTag)

			local cloned = model:Clone()

			for i, descendant in cloned:GetDescendants() do
				if descendant:IsA("BasePart") then
					descendant.Anchored = true
				end
			end

			model:Destroy()

			return cloned:Clone()
		end, id)

		cache[id] = future
		local model = future:Await()
		return if model then model:Clone() else nil
	end)
end

return AccessoryCache

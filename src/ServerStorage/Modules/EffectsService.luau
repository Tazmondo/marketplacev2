local EffectsService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectEvents = require(ReplicatedStorage.Events.EffectEvents)

function EffectsService.PurchaseEffect(position: Vector3)
	print("dispatching purchase")
	EffectEvents.Purchase:FireAllClients(position)
end

return EffectsService

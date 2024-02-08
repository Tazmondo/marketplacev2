local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectEvents = require(ReplicatedStorage.Events.EffectEvents)
local Effects = require(ReplicatedStorage.Modules.Shared.Effects)
local EffectController = {}

local function HandlePurchase(position: Vector3)
	print("doing purchase vfx")
	local purchase = Effects.Purchase

	local newPart = purchase.VFX()
	local newSound = purchase.Sound()
	newSound.Parent = newPart

	local emitter = newPart.Attachment.ParticleEmitter
	emitter.Enabled = false

	newPart.Position = position
	newPart.Parent = workspace
	emitter:Emit(emitter:GetAttribute("EmitCount") or 1)
	newSound:Play()

	Debris:AddItem(newPart, emitter.Lifetime.Max + 1)
end

local function Initialize()
	EffectEvents.Purchase:SetClientListener(HandlePurchase)
end

Initialize()

return EffectController

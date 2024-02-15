local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assets = ReplicatedStorage.Assets
local soundFolder = assets.Sounds
local effectFolder = assets.Effects

type EffectPart = BasePart & {
	Attachment: Attachment & {
		ParticleEmitter: ParticleEmitter,
	},
}
local sounds = {
	ShopPurchase = soundFolder.ShopPurchase :: Sound,
}

local effects = {
	ShopPurchase = effectFolder.ShopPurchase :: EffectPart,
}

return {
	ShopPurchase = {
		Sound = function()
			return sounds.ShopPurchase:Clone()
		end,
		VFX = function()
			return effects.ShopPurchase:Clone()
		end,
	},
}

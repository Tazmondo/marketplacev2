local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assets = ReplicatedStorage.Assets :: Folder

type EffectPart = BasePart & {
	Attachment: Attachment & {
		ParticleEmitter: ParticleEmitter,
	},
}

return {
	Purchase = {
		Sound = function()
			return (assets:FindFirstChild("PurchaseSound") :: Sound):Clone()
		end,
		VFX = function()
			return (assets:FindFirstChild("PurchaseVFX") :: EffectPart):Clone()
		end,
	},
}

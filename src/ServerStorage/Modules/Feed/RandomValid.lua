local RandomValid = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)

function RandomValid.IsValid(shop: Data.Shop): boolean
	-- We don't want empty shops clogging up the feed

	if Layouts:LayoutIdExists(shop.layoutId) then
		local layoutId: LayoutData.LayoutId = Layouts:GuardLayoutId(shop.layoutId)
		local layout = Layouts:GetLayout(layoutId)
		local totalStands = layout.getNumberOfStands()

		local usedStands = #shop.stands
		local proportion = usedStands / totalStands

		return proportion >= Config.RequiredProportionForRandom
	end

	return false
end

function RandomValid.AnyValid(shops: { Data.Shop }): boolean
	local valid = false
	for i, shop in shops do
		if RandomValid.IsValid(shop) then
			valid = true
			break
		end
	end

	return valid
end

function RandomValid.AllValid(shops: { Data.Shop }): boolean
	local valid = true
	for i, shop in shops do
		if not RandomValid.IsValid(shop) then
			valid = false
			break
		end
	end

	return valid
end

return RandomValid

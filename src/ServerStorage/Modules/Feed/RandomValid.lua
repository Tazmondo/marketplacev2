local RandomValid = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)

function RandomValid.IsValid(showcase: Data.Showcase): boolean
	-- We don't want empty showcases clogging up the feed

	if Layouts:LayoutIdExists(showcase.layoutId) then
		local layoutId: LayoutData.LayoutId = Layouts:GuardLayoutId(showcase.layoutId)
		local layout = Layouts:GetLayout(layoutId)
		local totalStands = layout.getNumberOfStands()

		local usedStands = #showcase.stands
		local proportion = usedStands / totalStands

		return proportion >= Config.RequiredProportionForRandom
	end

	return false
end

function RandomValid.AnyValid(showcases: { Data.Showcase }): boolean
	local valid = false
	for i, showcase in showcases do
		if RandomValid.IsValid(showcase) then
			valid = true
			break
		end
	end

	return valid
end

function RandomValid.AllValid(showcases: { Data.Showcase }): boolean
	local valid = true
	for i, showcase in showcases do
		if not RandomValid.IsValid(showcase) then
			valid = false
			break
		end
	end

	return valid
end

return RandomValid

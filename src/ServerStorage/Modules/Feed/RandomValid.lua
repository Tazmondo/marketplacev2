local RandomValid = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)

function RandomValid.IsValid(showcase: Data.Showcase): boolean
	-- We don't want empty showcases clogging up the feed
	return #showcase.stands >= Config.MinimumStandsForRandom
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

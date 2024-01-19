local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataService = require(ServerStorage.Modules.Data.DataService)
local Base36 = require(ReplicatedStorage.Modules.Shared.Base36)
local ShowcaseService = require(ServerStorage.Modules.ShowcaseService)

return function(context, recipientPlayers, bucks)
	local player = context.Executor
	local showcase = ShowcaseService:GetShowcaseOfPlayer(player)
	if not showcase then
		return "Not in a shop."
	end

	if showcase.shareCode then
		return `Code: {Base36.Encode(showcase.shareCode)}`
	end

	local code = DataService:GenerateNextShareCode(player, showcase.owner, showcase.GUID):Await()
	if not code then
		return `Failed to generate share code.`
	end

	return `Code: {Base36.Encode(code)}`
end

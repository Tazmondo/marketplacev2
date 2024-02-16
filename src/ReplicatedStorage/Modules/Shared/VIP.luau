local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)
local VIP = {}

local VIP_PASS = 699920227

local resultCache: { [number]: boolean } = {}

-- on client, will only fire with the localplayer
VIP.GainedVIP = Signal()

function VIP.IsPlayerVIP(id: number)
	return Future.new(function()
		-- if id == 68252170 then
		-- 	return true
		-- end

		if resultCache[id] ~= nil then
			return resultCache[id]
		end

		local success, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(id, VIP_PASS)
		end)

		if success then
			resultCache[id] = result
			return result
		end

		warn(result)
		return false
	end)
end

function VIP.PromptPurchase(player: Player)
	MarketplaceService:PromptGamePassPurchase(player, VIP_PASS)
end

local function HandleGamePassFinished(player: Player, passId: number, purchased: boolean)
	if not purchased or passId ~= VIP_PASS then
		return
	end

	resultCache[player.UserId] = true
	VIP.GainedVIP:Fire(player)
end

local function PlayerRemoving(player: Player)
	resultCache[player.UserId] = nil
end

Players.PlayerRemoving:Connect(PlayerRemoving)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(HandleGamePassFinished)

-- Pre-cache gamepass status on load, to eliminate a potential delay in checking later on
if RunService:IsClient() then
	VIP.IsPlayerVIP(Players.LocalPlayer.UserId)
end

return VIP

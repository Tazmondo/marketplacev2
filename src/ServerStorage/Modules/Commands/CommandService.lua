local CommandService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Cmdr = require(ReplicatedStorage.Packages.Cmdr)

local CmdrFolder = ReplicatedStorage.Cmdr

local function IsAdmin(player: Player)
	return player.UserId == 2294598404 or player.UserId == 68252170
end

local function PlayerAdded(player: Player)
	if IsAdmin(player) or RunService:IsStudio() then
		player:SetAttribute("Cmdr_Admin", true)
	else
		player:SetAttribute("Cmdr_Admin", false)
	end
end

function CommandService.Initialize()
	print("Initialize command service")

	Players.PlayerAdded:Connect(PlayerAdded)
	for i, player in ipairs(Players:GetPlayers()) do
		PlayerAdded(player)
	end

	Cmdr:RegisterDefaultCommands()
	Cmdr:RegisterHooksIn(CmdrFolder.Hooks)
	Cmdr:RegisterCommandsIn(script.Parent.Commands)
end

CommandService.Initialize()

return CommandService

local PlayerVisibilityController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisibilityEvent = require(ReplicatedStorage.Events.VisibilityEvent)

type PlayerData = {
	visible: boolean,
	character: Model?,
}

local playerData: { [Player]: PlayerData } = {}

function HandleUpdateVisiblePlayers(players: { Player })
	print("Received visibility:", players, playerData)
	local visiblePlayers = {}
	for i, player in players do
		visiblePlayers[player] = true
	end

	for player, data in playerData do
		if visiblePlayers[player] then
			data.visible = true
			if data.character then
				data.character.Parent = workspace
			end
		else
			data.visible = false
			if data.character then
				data.character.Parent = nil
			end
		end
	end
end

function CharacterAdded(player: Player, character: Model)
	-- Defer this so it runs after character gets parented to workspace
	-- May not be necessary since the new deferred signal update but it doesn't hurt to have it
	task.defer(function()
		local data = playerData[player]
		data.character = character
		if not data.visible then
			character.Parent = nil
		else
			character.Parent = workspace
		end
	end)
end

function PlayerAdded(player: Player)
	if player == Players.LocalPlayer then
		return
	end

	local data: PlayerData = {
		visible = false,
		character = nil,
	}

	playerData[player] = data
	if player.Character then
		CharacterAdded(player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		CharacterAdded(player, character)
	end)
end

function PlayerRemoving(player: Player)
	if not playerData[player] then
		return
	end

	local character = playerData[player].character
	if character then
		character:Destroy()
	end
	playerData[player] = nil
end

function PlayerVisibilityController:Initialize()
	VisibilityEvent:SetClientListener(HandleUpdateVisiblePlayers)

	Players.PlayerAdded:Connect(PlayerAdded)
	for i, player in Players:GetPlayers() do
		PlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(PlayerRemoving)
end

PlayerVisibilityController:Initialize()

return PlayerVisibilityController

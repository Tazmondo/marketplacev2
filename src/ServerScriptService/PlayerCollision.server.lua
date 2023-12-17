local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- Probably won't collide with any potential future code
local TAG = "TAZ_Players"

PhysicsService:RegisterCollisionGroup(TAG)
PhysicsService:CollisionGroupSetCollidable(TAG, TAG, false)

function CharacterAdded(char: Model)
	task.defer(function()
		for i, part in char:GetDescendants() do
			if part:IsA("BasePart") then
				part.CollisionGroup = TAG
			end
		end
	end)
end

function PlayerAdded(player: Player)
	player.CharacterAdded:Connect(CharacterAdded)
	if player.Character then
		CharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(PlayerAdded)
for i, player in Players:GetPlayers() do
	PlayerAdded(player)
end

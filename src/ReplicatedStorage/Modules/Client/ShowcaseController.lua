local ShowcaseController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Accessory replication folder did not exist.")

return ShowcaseController

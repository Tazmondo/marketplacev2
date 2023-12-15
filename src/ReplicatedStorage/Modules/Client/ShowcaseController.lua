local ShowcaseController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShowcaseEditUI = require(ReplicatedStorage.Modules.Client.UI.ShowcaseEditUI)
local Types = require(ReplicatedStorage.Modules.Shared.Types)

local EnterShowcaseEvent = require(ReplicatedStorage.Events.Showcase.EnterShowcaseEvent):Client()

local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Accessory replication folder did not exist.")

local currentShowcase: Types.NetworkShowcase?

function HandleEnterShowcase(showcase: Types.NetworkShowcase?)
	currentShowcase = showcase
	ShowcaseEditUI:Hide()

	if showcase and showcase.mode == "Edit" then
		ShowcaseEditUI:Display()
	end
end

function ShowcaseController:Initialize()
	EnterShowcaseEvent:On(HandleEnterShowcase)
end

ShowcaseController:Initialize()

return ShowcaseController

local NavigationUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CatalogUI = require(script.Parent.CatalogUI)
local DiscoverUI = require(script.Parent.DiscoverUI)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetNavigation()
local nav = gui.Nav

local function ShopsClicked()
	DiscoverUI:Toggle()
end
local function CatalogClicked()
	CatalogUI:Display("Marketplace", "Wear")
end

local function InventoryClicked()
	CatalogUI:Display("Inventory", "Wear")
end

function NavigationUI:Initialize()
	nav.Profile.Frame.ImageLabel.Image = Thumbs.GetHeadShot(Players.LocalPlayer.UserId)
	nav.Profile.ImageButton.Activated:Connect(ShopsClicked)
	nav.Catalog.ImageButton.Activated:Connect(CatalogClicked)
	nav.Inventory.ImageButton.Activated:Connect(InventoryClicked)
end

NavigationUI:Initialize()

return NavigationUI

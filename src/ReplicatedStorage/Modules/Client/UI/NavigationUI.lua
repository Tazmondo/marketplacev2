local NavigationUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ShopController = require(ReplicatedStorage.Modules.Client.Shop.ShopController)
local MallCFrames = require(ReplicatedStorage.Modules.Shared.MallCFrames)
local VIP = require(ReplicatedStorage.Modules.Shared.VIP)
local CatalogUI = require(script.Parent.CatalogUI)
local DiscoverUI = require(script.Parent.DiscoverUI)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetNavigation()
local nav = gui.Nav

local closeToDynamic = false
local insideDynamic = false
local highlighted = false

local function ShopsClicked()
	DiscoverUI:Toggle()
end
local function CatalogClicked()
	CatalogUI:Display("Marketplace", "Wear")
end

local function InventoryClicked()
	CatalogUI:Display("Inventory", "Wear")
end

local function VIPClicked()
	VIP.PromptPurchase(Players.LocalPlayer)
end

local function RenderVIP()
	local vip = gui.Nav.VIP
	VIP.IsPlayerVIP(Players.LocalPlayer.UserId):After(function(isVip)
		vip.Visible = not isVip
	end)
end

local function RenderShopsButton()
	local newHighlighted = closeToDynamic or insideDynamic
	if newHighlighted == highlighted then
		return
	end
	highlighted = newHighlighted

	local unhighlightedColor = Color3.fromRGB(28, 28, 30)
	local highlightedColor = Color3.fromHex("0A84FF")

	local targetColor = if highlighted then highlightedColor else unhighlightedColor
	local scale = if highlighted then 1.15 else 1

	TweenService
		:Create(nav.Profile.ImageButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { BackgroundColor3 = targetColor })
		:Play()
	TweenService
		:Create(nav.Profile.ImageButton.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Color = targetColor })
		:Play()
	TweenService:Create(nav.Profile.UIScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Scale = scale }):Play()
end

local function PostSimulation()
	local char = Players.LocalPlayer.Character
	if not char then
		return
	end

	local isClose = (char:GetPivot().Position - MallCFrames.dynamicShop.cframe.Position).Magnitude < 30
	if isClose ~= closeToDynamic then
		closeToDynamic = isClose
		RenderShopsButton()
	end
end

function NavigationUI:Initialize()
	nav.Profile.ImageButton.Activated:Connect(ShopsClicked)
	nav.Catalog.ImageButton.Activated:Connect(CatalogClicked)
	nav.Inventory.ImageButton.Activated:Connect(InventoryClicked)

	RunService.PostSimulation:Connect(PostSimulation)

	ShopController.ShopEntered:Connect(function(shop)
		if shop == nil then
			insideDynamic = false
		else
			local mallShop = MallCFrames.GetShop(shop.cframe)
			insideDynamic = mallShop ~= nil and mallShop.type == "Dynamic"
		end

		RenderShopsButton()
	end)

	RenderVIP()
	VIP.GainedVIP:Connect(RenderVIP)
	gui.Nav.VIP.ImageButton.Activated:Connect(VIPClicked)
end

NavigationUI:Initialize()

return NavigationUI

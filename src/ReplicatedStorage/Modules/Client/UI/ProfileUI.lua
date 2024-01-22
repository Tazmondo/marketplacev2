local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileUI = {}

local DataController = require(ReplicatedStorage.Modules.Client.DataController)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local UILoader = require(script.Parent.UILoader)

local DeleteShopEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.DeleteShowcaseEvent):Client()
local EditShopEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.EditShowcaseEvent):Client()
local CreateShopEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.CreateShowcaseEvent):Client()

local gui = UILoader:GetMain()
local profile = gui.Profile
local shopList = profile.Frame.List
local shopTemplate = shopList.Row

local create = gui.CreateShop

function EditShop(shop: Data.Shop)
	EditShopEvent:Fire(shop.GUID)
	ProfileUI:Hide()
end

function Populate(shops: { Data.Shop })
	for i, child in shopList:GetChildren() do
		if child:GetAttribute("Temporary") then
			child:Destroy()
		end
	end

	for i, shop in shops do
		local newRow = shopTemplate:Clone()

		newRow.Details.NameLabel.Text = shop.name
		newRow.Details.Frame.Price.Text = "0" -- number of likes

		newRow.Thumb.Image = Thumbs.GetAsset(shop.thumbId)

		newRow.Activated:Connect(function()
			EditShop(shop)
		end)

		-- Delete button
		newRow.Price.Select.Activated:Connect(function()
			DeleteShopEvent:Fire(shop.GUID)
		end)

		newRow.Visible = true
		newRow:SetAttribute("Temporary", true)
		newRow.Parent = shopTemplate.Parent
	end
end

function ShowCreateShop()
	create.Visible = true
	profile.Visible = false
end

function HideCreateShop()
	create.Visible = false
	profile.Visible = true
end

function CreateShop()
	print("Create shop")
	CreateShopEvent:Fire()
	HideCreateShop()
end

function ProfileUI:Toggle()
	if profile.Visible or create.Visible then
		ProfileUI:Hide()
	else
		ProfileUI:Show()
	end
end

function ProfileUI:Show()
	profile.Visible = true
end

function ProfileUI:Hide()
	profile.Visible = false
	create.Visible = false
end

function ProfileUI:Initialize()
	profile.Visible = false
	create.Visible = false

	shopTemplate.Visible = false

	profile.Title.Title.TextLabel.Text = `@{Players.LocalPlayer.Name}`
	profile.Title.Avatar.ImageButton.Image = Thumbs.GetHeadShot(Players.LocalPlayer.UserId)

	profile.Title.Close.ImageButton.Activated:Connect(ProfileUI.Hide)

	shopList.CreateShop.Activated:Connect(ShowCreateShop)
	create.Frame.Actions.TertiaryButton.Activated:Connect(HideCreateShop)

	create.Frame.Actions.PrimaryButton.Activated:Connect(CreateShop)

	DataController:GetData():After(function(data)
		Populate(data.shops)
		DataController.Updated:Connect(function(data)
			Populate(data.shops)
		end)
	end)
end

ProfileUI:Initialize()

return ProfileUI

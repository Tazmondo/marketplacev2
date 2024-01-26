local ShopSettingsUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain().ShopSettings

local activeShop: Types.Shop? = nil

function Save()
	if not activeShop then
		return
	end
	local name = Util.LimitString(gui.Frame.ShopName.TextBox.Text, Config.MaxPlaceNameLength)
	if #name == 0 then
		name = activeShop.name
	end

	gui.Frame.ShopName.TextBox.Text = name

	local cleanedThumbString = gui.Frame.Thumbnail.TextBox.Text:gsub("rbxassetid://", "")
	local thumbId = tonumber(cleanedThumbString)

	local logoId = tonumber(gui.Frame.Logo.TextBox.Text)

	ShopEvents.UpdateSettings:FireServer({
		name = name,
		primaryColor = activeShop.primaryColor,
		accentColor = activeShop.accentColor,
		texture = activeShop.texture,
		thumbId = thumbId or activeShop.thumbId,
		logoId = logoId or activeShop.logoId,
	})

	ShopSettingsUI:Close()
end

function ShopSettingsUI:Close()
	activeShop = nil
	gui.Visible = false
end

function ShopSettingsUI:Display(shop: Types.Shop)
	gui.Visible = true
	activeShop = shop

	gui.Frame.ShopName.TextBox.Text = shop.name
	gui.Frame.Thumbnail.TextBox.Text = tostring(shop.thumbId)
	gui.Frame.ShopThumbnail.Image = Thumbs.GetAsset(shop.thumbId)
end

function ShopSettingsUI:IsOpen()
	return gui.Visible
end

function ShopSettingsUI:Initialize()
	gui.Visible = false

	gui.Title.Close.Activated:Connect(ShopSettingsUI.Close)

	gui.Frame.Actions.Save.Activated:Connect(Save)
end

ShopSettingsUI:Initialize()

return ShopSettingsUI

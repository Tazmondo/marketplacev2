local ShopSettingsUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local UILoader = require(script.Parent.UILoader)

local UpdateShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.UpdateShowcaseEvent):Client()

local gui = UILoader:GetMain().ShopSettings

local activeShowcase: Types.NetworkShowcase? = nil

function Save()
	if not activeShowcase then
		return
	end
	local name = Util.LimitString(gui.Frame.ShopName.TextBox.Text, Config.MaxPlaceNameLength)
	if #name == 0 then
		name = activeShowcase.name
	end

	gui.Frame.ShopName.TextBox.Text = name

	local cleanedThumbString = gui.Frame.Thumbnail.TextBox.Text:gsub("rbxassetid://", "")
	local thumbId = tonumber(cleanedThumbString)

	local logoId = tonumber(gui.Frame.Logo.TextBox.Text)

	UpdateShowcaseEvent:Fire({
		type = "UpdateSettings",
		name = name,
		primaryColor = activeShowcase.primaryColor,
		accentColor = activeShowcase.accentColor,
		texture = activeShowcase.texture,
		thumbId = thumbId or activeShowcase.thumbId,
		logoId = logoId or activeShowcase.logoId,
	})

	ShopSettingsUI:Close()
end

function ShopSettingsUI:Close()
	activeShowcase = nil
	gui.Visible = false
end

function ShopSettingsUI:Display(showcase: Types.NetworkShowcase)
	gui.Visible = true
	activeShowcase = showcase

	gui.Frame.ShopName.TextBox.Text = showcase.name
	gui.Frame.Thumbnail.TextBox.Text = tostring(showcase.thumbId)
	gui.Frame.ShopThumbnail.Image = Thumbs.GetAsset(showcase.thumbId)
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

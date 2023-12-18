local ShopSettingsUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Shared.Config)
local StringUtil = require(ReplicatedStorage.Modules.Shared.StringUtil)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local UILoader = require(script.Parent.UILoader)

local UpdateShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.UpdateShowcaseEvent):Client()

local gui = UILoader:GetMain().ShopSettings

local activeShowcase: Types.NetworkShowcase? = nil

function Save()
	if not activeShowcase then
		return
	end
	local name = StringUtil.LimitString(gui.Frame.ShopName.TextBox.Text, Config.MaxPlaceNameLength)
	if #name == 0 then
		name = activeShowcase.name
	end

	gui.Frame.ShopName.TextBox.Text = name

	local cleanedString = gui.Frame.Thumbnail.TextBox.Text:gsub("rbxassetid://", "")
	local thumbId = tonumber(cleanedString)

	UpdateShowcaseEvent:Fire({
		type = "UpdateSettings",
		name = name,
		primaryColor = activeShowcase.primaryColor,
		accentColor = activeShowcase.accentColor,
		thumbId = thumbId or activeShowcase.thumbId,
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
	gui.Frame.ShopThumbnail.Image = `rbxthumb://type=Asset&id={showcase.thumbId}&w=420&h=420`
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

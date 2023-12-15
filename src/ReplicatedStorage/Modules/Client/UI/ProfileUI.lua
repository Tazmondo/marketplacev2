local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileUI = {}

local DataController = require(ReplicatedStorage.Modules.Client.DataController)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain()
local profile = gui.Profile
local showcaseList = profile.Frame.List
local showcaseTemplate = showcaseList.Row

local create = gui.CreateShop

function Populate(showcases: { Data.Showcase })
	for i, child in showcaseList:GetChildren() do
		if child:GetAttribute("Temporary") then
			child:Destroy()
		end
	end

	for i, showcase in showcases do
		local newRow = showcaseTemplate:Clone()

		newRow.Details.NameLabel.Text = showcase.name
		newRow.Details.Frame.Price.Text = "0" -- number of likes

		newRow.Activated:Connect(function()
			-- TODO: Select showcase
		end)

		-- Delete button
		newRow.Price.Select.Activated:Connect(function()
			-- TODO: Delete showcase
		end)
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

function CreateShop() end

function ProfileUI:Show()
	profile.Visible = true
end

function ProfileUI:Hide()
	profile.Visible = false
end

function ProfileUI:Initialize()
	profile.Visible = false
	create.Visible = false

	showcaseTemplate.Visible = false

	profile.Title.Close.ImageButton.Activated:Connect(ProfileUI.Hide)

	showcaseList.CreateShop.Activated:Connect(ShowCreateShop)
	create.Frame.Actions.TertiaryButton.Activated:Connect(HideCreateShop)

	create.Frame.Actions.PrimaryButton.Activated:Connect(CreateShop)

	DataController:GetData():After(function(data)
		Populate(data.showcases)
	end)
end

ProfileUI:Initialize()

return ProfileUI

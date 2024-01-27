local ProfileUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local DataController = require(ReplicatedStorage.Modules.Client.DataController)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain()
local profile = gui.Profile
local shopList = profile.Frame.List
local shopTemplate = shopList.Row

local create = gui.CreateShop

local ShopSelected: Signal.Signal<Data.Shop> = Signal()

local function SelectShop(shop: Data.Shop)
	ShopSelected:Fire(shop)
	ProfileUI:Hide()
end

local function Populate(shops: { Data.Shop })
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
			SelectShop(shop)
		end)

		-- Delete button
		newRow.Price.Select.Activated:Connect(function()
			ShopEvents.DeleteShop:FireServer(shop.GUID)
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
	ShopEvents.CreateShop:FireServer()
	HideCreateShop()
end

function ProfileUI:SelectShop()
	return Future.new(function(): Data.Shop?
		ProfileUI:Show()

		local selectedFuture = Future.new(function(): Data.Shop?
			return ShopSelected:Wait()
		end)

		local closedFuture = Future.new(function(): Data.Shop?
			while profile.Visible or create.Visible do
				profile:GetPropertyChangedSignal("Visible"):Wait()
			end
			return
		end)

		local selectedShop = Future.Any({ selectedFuture, closedFuture }):Await()
		return selectedShop
	end)
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

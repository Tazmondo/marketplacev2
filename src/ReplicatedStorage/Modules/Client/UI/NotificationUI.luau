local NotificationUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local NotificationEvents = require(ReplicatedStorage.Events.NotificationEvents)
local Future = require(ReplicatedStorage.Packages.Future)
local UILoader = require(script.Parent.UILoader)

local gui = UILoader:GetMain().Notification

local visiblePosition = gui.Position
local invisiblePosition = gui.Position + UDim2.fromScale(0, 1 - gui.Position.Y.Scale + gui.Size.Y.Scale)

local LayoutPurchaseSound = ReplicatedStorage.Assets.Sounds.LayoutPurchase :: Sound

type Notification = {
	text: string,
}

local eventQueue: { Notification } = {}
local displayingNotification = false

local function GetName(id: number)
	return Future.new(function(): string?
		local player = Players:GetPlayerByUserId(id)
		if player then
			return player.Name
		end

		local success, name = pcall(function()
			return Players:GetNameFromUserIdAsync(id)
		end)

		if success then
			return name
		else
			warn(name)
			return nil
		end
	end)
end

local function DisplayNotification(notification: Notification)
	return Future.new(function()
		gui.Position = invisiblePosition
		gui.Frame.TextLabel.Text = notification.text
		gui.Visible = true

		local tweenTime = 0.3

		gui:TweenPosition(visiblePosition, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime)

		-- wait for tween to finish
		task.wait(tweenTime)

		-- display for 2 seconds
		task.wait(4)

		gui:TweenPosition(invisiblePosition, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime)

		-- wait for tween to finish
		task.wait(tweenTime)

		-- allow some down-time inbetween notification displays
		task.wait(0.5)
		gui.Visible = false
	end)
end

local function QueueAdd(notification: Notification)
	table.insert(eventQueue, notification)
end

local function CreateNotification(text: string)
	local notification = {
		text = text,
	}

	QueueAdd(notification)
end

local function Heartbeat()
	if displayingNotification or #eventQueue == 0 then
		return
	end

	local nextNotification = assert(table.remove(eventQueue, 1))

	displayingNotification = true
	DisplayNotification(nextNotification):Await()
	displayingNotification = false
end

function NotificationUI.PurchaseLayout()
	CreateNotification(`You purchased a new shop!`)
	SoundService:PlayLocalSound(LayoutPurchaseSound)
end

local function Initialize()
	NotificationEvents.Donated:SetClientListener(function(robux, receiver)
		local name = GetName(receiver):Await()
		CreateNotification(`You donated {robux} to @{name or "Not Found"}`)
	end)

	NotificationEvents.EarnedShopbux:SetClientListener(function(shopbux)
		CreateNotification(`You earned ${shopbux} Shopbux!`)
	end)

	NotificationEvents.ReceiveDonation:SetClientListener(function(amount, giver)
		local name = GetName(giver):Await()
		CreateNotification(`@{name or "Not Found"} gave you a {amount} donation!`)
	end)

	NotificationEvents.ReceiveSale:SetClientListener(function(amount, buyer)
		local name = GetName(buyer):Await()
		CreateNotification(`@{name or "Not Found"} made a {amount} purchase in your shop!`)
	end)

	RunService.Heartbeat:Connect(Heartbeat)
end

Initialize()

return NotificationUI

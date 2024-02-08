local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NotificationEvents = require(ReplicatedStorage.Events.NotificationEvents)
local Future = require(ReplicatedStorage.Packages.Future)
local UILoader = require(script.Parent.UILoader)
local NotificationUI = {}

local gui = UILoader:GetMain().Notification

local visiblePosition = gui.Position
local invisiblePosition = gui.Position + UDim2.fromScale(0, 1 - gui.Position.Y.Scale + gui.Size.Y.Scale)

type Notification = {
	text: string,
}

local eventQueue: { Notification } = {}
local displayingNotification = false

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

local function ShowEarned(amount: number)
	local notification = {
		text = `You earned {amount}!`,
	}

	QueueAdd(notification)
end

local function ShowRaised(amount: number, owner: number)
	local name = Players:GetNameFromUserIdAsync(owner)

	local notification = {
		text = `You raised {amount} for @{name}!`,
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

local function Initialize()
	NotificationEvents.Earned:SetClientListener(ShowEarned)
	NotificationEvents.Raised:SetClientListener(ShowRaised)

	RunService.Heartbeat:Connect(Heartbeat)
end

Initialize()

return NotificationUI

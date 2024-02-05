--!nolint LocalShadow
local LeaderboardController = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LeaderboardEvents = require(ReplicatedStorage.Events.LeaderboardEvents)
local UITypes = require(ReplicatedStorage.Modules.Client.UI.UITypes)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)

local updated = Signal()

type LeaderboardName = LeaderboardEvents.LeaderboardName

local leaderboardText: { [LeaderboardName]: string } = {
	Earned = "%s Robux Earned",
	Purchases = "%s Items Purchased",
}

local function FetchName(id: number)
	return Future.new(function(id): string?
		local success, name = pcall(function()
			return Players:GetNameFromUserIdAsync(id)
		end)

		if success then
			return name
		end
		return
	end, id)
end

local function SetupSideSwitcher(part: BasePart, gui: SurfaceGui)
	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end

		local partCF = part.CFrame
		local lookVector = partCF.LookVector
		local difference = (cam.CFrame.Position - partCF.Position).Unit
		if lookVector:Dot(difference) >= 0 then
			gui.Face = Enum.NormalId.Front
		else
			gui.Face = Enum.NormalId.Back
		end
	end)
end

local function RegisterLeaderboard(name: LeaderboardName)
	local leaderboardPart = CollectionService:GetTagged(`{name} Leaderboard`)[1]
	assert(leaderboardPart, `{name} leaderboard had no tagged leaderboard part.`)

	local gui: UITypes.Leaderboard = leaderboardPart:FindFirstChildOfClass("SurfaceGui")
	assert(gui, `{leaderboardPart:GetFullName()} had no surfacegui`)

	local subText = leaderboardText[name]
	assert(subText, `{name} leaderboard has no defined subtext`)

	SetupSideSwitcher(leaderboardPart, gui)

	local list = gui.Profile.Frame.List
	local template = list.Row

	updated:Connect(function(signalledName, data)
		if name ~= signalledName then
			return
		end
		Util.RenderList(list, template, data, function(i, row, data, destroyed)
			if data.data <= 0 then
				-- We dont want to display users that have 0
				return
			end

			row.Visible = true
			row.LayoutOrder = i

			row.Thumb.Image = Thumbs.GetHeadShot(data.id)
			row.Rank.TextLabel.Text = `#{i}`
			row.Details.Frame.Details.Text = string.format(subText, FormatNumber.Simple.FormatCompact(data.data))

			row.Details.NameLabel.Text = "Loading..."
			FetchName(data.id):After(function(name)
				if not name or destroyed() then
					return
				end

				row.Details.NameLabel.Text = `@{name}`
			end)
		end)
	end)
end

local function Initialize()
	RegisterLeaderboard("Earned")
	RegisterLeaderboard("Purchases")

	LeaderboardEvents.Update:SetClientListener(function(name, data)
		local name = name :: LeaderboardName
		updated:Fire(name, data)
	end)
end

Initialize()

return LeaderboardController

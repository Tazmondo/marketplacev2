local ShowcaseController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ShowcaseEditUI = require(ReplicatedStorage.Modules.Client.UI.ShowcaseEditUI)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)

local EnterShowcaseEvent = require(ReplicatedStorage.Events.Showcase.EnterShowcaseEvent):Client()

local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Accessory replication folder did not exist.")

local renderedAccessoryFolder = Instance.new("Folder", workspace)
renderedAccessoryFolder.Name = "Rendered Accessories"

type RenderedStand = {
	standPart: BasePart,
	assetId: number?,
	prompt: ProximityPrompt,

	hoverPosition: number,
	rotation: number,

	shouldBob: boolean,
	shouldSpin: boolean,

	renderModel: Model?,

	-- Since fetching the model is asynchronous, we need this in case a stand is destroyed
	-- Before the model is fetched, so the code knows not to parent the model
	destroyed: boolean,
}

local renderedStands: { [BasePart]: RenderedStand } = {}
local currentShowcase: Types.NetworkShowcase?

function GetAccessory(assetId: number, scale: number?)
	return Future.new(function(assetId: number, scale: number?)
		local accessoryTemplate = accessoryReplication:WaitForChild(tostring(assetId), 5) :: Model?
		if not accessoryTemplate then
			return nil :: Model?
		end

		local accessory = accessoryTemplate:Clone()

		for i, descendant in accessory:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end

		accessory:ScaleTo(Config.DefaultScale * (scale or 1))

		return accessory
	end, assetId, scale)
end

function DestroyStand(stand: RenderedStand)
	stand.destroyed = true
	if stand.renderModel then
		stand.renderModel:Destroy()
	end

	stand.prompt:Destroy()
	if renderedStands[stand.standPart] == stand then
		renderedStands[stand.standPart] = nil
	end
end

function UserRemovedItem(stand: RenderedStand) end

function CreateStands(showcase: Types.NetworkShowcase)
	for part, stand in showcase.stands do
		local existingStand = renderedStands[part]
		if existingStand then
			if existingStand.assetId == stand.assetId then
				continue
			else
				DestroyStand(existingStand)
			end
		end

		local shouldBob = part:GetAttribute(Config.NoBobTag) ~= true
		local shouldSpin = part:GetAttribute(Config.NoSpinTag) ~= true
		local standScale: number = part:GetAttribute(Config.ScaleTag) or 1

		local prompt = Instance.new("ProximityPrompt")
		prompt.RequiresLineOfSight = false

		local _, rotY, _ = part.CFrame:ToEulerAnglesYXZ()

		local renderedStand: RenderedStand = {
			assetId = stand.assetId,
			standPart = part,
			prompt = prompt,

			shouldBob = shouldBob,
			hoverPosition = if shouldBob then math.random() else 0.25,

			shouldSpin = shouldSpin,
			rotation = if shouldSpin then math.random() * math.rad(360) else rotY,

			destroyed = false,
		}

		if stand.assetId then
			GetAccessory(stand.assetId, standScale):After(function(model)
				if not model then
					return
				end

				if renderedStand.destroyed then
					model:Destroy()
				else
					model.Parent = renderedAccessoryFolder
					renderedStand.renderModel = model
				end
			end)
		end

		if showcase.mode == "Edit" then
			if stand.assetId then
				prompt.ActionText = "Remove Item"
				prompt.ObjectText = "Stand"
				prompt.Parent = stand.part
				prompt.Triggered:Connect(function()
					UserRemovedItem(renderedStand)
				end)
			else
				prompt.ActionText = "Add Item"
				prompt.ObjectText = "Stand"
				prompt.Parent = stand.part
				prompt.Triggered:Connect(function()
					print("Todo: add items")
				end)
			end
		else
			if stand.assetId then
				prompt.ActionText = "View Item"
				prompt.ObjectText = "Stand"
				prompt.Parent = stand.part
				prompt.Triggered:Connect(function()
					print("Todo: view item")
				end)
			end
		end

		renderedStands[part] = renderedStand
		part.Destroying:Connect(function()
			DestroyStand(renderedStand)
		end)
	end
end

function HandleEnterShowcase(showcase: Types.NetworkShowcase?)
	currentShowcase = showcase
	ShowcaseEditUI:Hide()

	if showcase then
		CreateStands(showcase)

		if showcase.mode == "Edit" then
			ShowcaseEditUI:Display()
		end
	end
end

function GetTweenedStandAlpha(alpha: number)
	if alpha >= 0.5 then
		return 1 - TweenService:GetValue((2 * (alpha - 0.5)), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	else
		return TweenService:GetValue((2 * alpha), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	end
end

function RenderStepped(dt: number)
	if not currentShowcase then
		return
	end

	for part, stand in renderedStands do
		local model = stand.renderModel
		if not model then
			continue
		end

		if stand.shouldSpin then
			stand.rotation += dt * Config.StandRotationSpeed
			if stand.rotation > math.rad(360) then
				stand.rotation -= math.rad(360)
			end
		end

		if stand.shouldBob then
			stand.hoverPosition += dt * Config.StandBobSpeed
			if stand.hoverPosition > 1 then
				stand.hoverPosition -= 1
			end
		end

		local hoverAlpha = GetTweenedStandAlpha(stand.hoverPosition)
		local position = part.Position + Vector3.new(0, 4 + 2 * hoverAlpha, 0)
		model:PivotTo(CFrame.new(position) * CFrame.Angles(0, stand.rotation, 0))
	end
end

function ShowcaseController:Initialize()
	EnterShowcaseEvent:On(HandleEnterShowcase)

	RunService.RenderStepped:Connect(RenderStepped)
end

ShowcaseController:Initialize()

return ShowcaseController

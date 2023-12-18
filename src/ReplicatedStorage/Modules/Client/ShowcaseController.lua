local ShowcaseController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AddItemUI = require(ReplicatedStorage.Modules.Client.UI.AddItemUI)
local ShowcaseEditUI = require(ReplicatedStorage.Modules.Client.UI.ShowcaseEditUI)
local ShowcaseNavigationUI = require(ReplicatedStorage.Modules.Client.UI.ShowcaseNavigationUI)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)

local UpdateShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.UpdateShowcaseEvent):Client()
local LoadShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ServerFired.LoadShowcaseEvent):Client()

local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Accessory replication folder did not exist.")

local renderedAccessoryFolder = Instance.new("Folder", workspace)
renderedAccessoryFolder.Name = "Rendered Accessories"

type DisplayPart = BasePart & {
	PointLight: PointLight,
	Attachment: Attachment & {
		Shine: ParticleEmitter,
	},
}

type RenderedStand = {
	standPart: DisplayPart,
	standId: number,
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

local renderedStands: { [DisplayPart]: RenderedStand } = {}
local currentShowcase: Types.NetworkShowcase?

-- Allows for comparison between stand objects.
-- I would do this by comparing the tables are the same but luau type system doesn't like that?
local standId = 0
function GetNextStandId()
	standId += 1
	return standId
end

function SetDisplayVisibility(display: DisplayPart, isVisible: boolean)
	if isVisible then
		display.Transparency = 0.8
		display.PointLight.Enabled = true
		display.Attachment.Shine.Enabled = true
	else
		display.Transparency = 1
		display.PointLight.Enabled = false
		display.Attachment.Shine.Enabled = false
	end
end

function GetAccessory(assetId: number, scale: number?)
	return Future.new(function(assetId: number, scale: number?)
		local accessoryTemplate = accessoryReplication:WaitForChild(tostring(assetId), 5) :: Model?
		if not accessoryTemplate then
			warn("Failed to load accessory: ", assetId)
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

	if renderedStands[stand.standPart].standId == stand.standId then
		renderedStands[stand.standPart] = nil
	end
end

function UserRemovedItem(stand: RenderedStand)
	HandleItemAdded(stand.standPart, nil)
end

function CreateStands(showcase: Types.NetworkShowcase)
	for i, stand in showcase.stands do
		local part = stand.part :: DisplayPart

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
			standId = GetNextStandId(),

			shouldBob = shouldBob,
			hoverPosition = if shouldBob then math.random() else 0.5,

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

					-- Set this here, so that the placeholder is still there until the model has loaded
					SetDisplayVisibility(part, false)
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
				SetDisplayVisibility(part, true)
				prompt.ActionText = "Add Item"
				prompt.ObjectText = "Stand"
				prompt.Parent = stand.part
				prompt.Triggered:Connect(function()
					AddItemUI:Display(part)
				end)
			end
		else
			SetDisplayVisibility(part, false)
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

function LoadShowcaseAppearance(showcase: Types.NetworkShowcase)
	if not currentShowcase then
		return
	end

	local model = currentShowcase.model

	debug.profilebegin("LoadShowcaseAppearance")

	-- Go through descendants here rather than using collectionservice, as there will be many places in the workspace.
	for i, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			if descendant:HasTag(Config.PrimaryColorTag) then
				if descendant:IsA("PartOperation") then
					descendant.UsePartColor = true
				end
				descendant.Color = currentShowcase.primaryColor
			elseif descendant:HasTag(Config.AccentColorTag) then
				if descendant:IsA("PartOperation") then
					descendant.UsePartColor = true
				end
				descendant.Color = currentShowcase.accentColor
			end
			-- TODO: Apply texture
		end
	end

	debug.profileend()
end

function HandleLoadShowcase(showcase: Types.NetworkShowcase?)
	if showcase and showcase.model.Parent == nil then
		-- When switching quickly, showcase parents can arrive as nil
		return
	end
	currentShowcase = showcase
	ShowcaseEditUI:Hide()
	ShowcaseNavigationUI:Hide()

	if showcase then
		LoadShowcaseAppearance(showcase)
		CreateStands(showcase)

		if showcase.mode == "Edit" then
			ShowcaseEditUI:Display(showcase)
		else
			ShowcaseNavigationUI:Display()
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
	debug.profilebegin("RenderStands")

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
		local position = part.Position + Vector3.new(0, 0.5 + 0.5 * hoverAlpha, 0)
		model:PivotTo(CFrame.new(position) * CFrame.Angles(0, stand.rotation, 0))
	end
	debug.profileend()
end

function HandleItemAdded(part: BasePart, assetId: number?)
	UpdateShowcaseEvent:Fire({
		type = "UpdateStand",
		part = part,
		assetId = assetId,
	})
end

function ShowcaseController:Initialize()
	LoadShowcaseEvent:On(HandleLoadShowcase)

	RunService.RenderStepped:Connect(RenderStepped)

	AddItemUI.Added:Connect(HandleItemAdded)
end

ShowcaseController:Initialize()

return ShowcaseController

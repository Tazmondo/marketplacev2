local ShowcaseController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AddItemUI = require(ReplicatedStorage.Modules.Client.UI.AddItemUI)
local ShowcaseEditUI = require(ReplicatedStorage.Modules.Client.UI.ShowcaseEditUI)
local ShowcaseNavigationUI = require(ReplicatedStorage.Modules.Client.UI.ShowcaseNavigationUI)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)

local UpdateShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.UpdateShowcaseEvent):Client()
local LoadShowcaseEvent = require(ReplicatedStorage.Events.Showcase.ServerFired.LoadShowcaseEvent):Client()

local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Accessory replication folder did not exist.")

local renderedAccessoryFolder = Instance.new("Folder", workspace)
renderedAccessoryFolder.Name = "Rendered Accessories"

type RenderedStand = {
	standPart: BasePart,
	roundedPosition: Vector3,
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

local renderedStands: { [Vector3]: RenderedStand } = {}
local currentModel: Model? = nil
local currentShowcase: Types.NetworkShowcase?

-- Allows for comparison between stand objects.
-- I would do this by comparing the tables are the same but luau type system doesn't like that?
local standId = 0
function GetNextStandId()
	standId += 1
	return standId
end

function SetDisplayVisibility(display: BasePart, isVisible: boolean)
	local light = display:FindFirstChild("PointLight") :: PointLight?
	local attachment = display:FindFirstChild("Attachment")
	local shine = if attachment then attachment:FindFirstChild("Shine") :: ParticleEmitter? else nil

	if isVisible then
		display.Transparency = 0.8
		if light then
			light.Enabled = true
		end
		if shine then
			shine.Enabled = true
		end
	else
		display.Transparency = 1
		if light then
			light.Enabled = false
		end
		if shine then
			shine.Enabled = false
		end
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

	if renderedStands[stand.roundedPosition].standId == stand.standId then
		renderedStands[stand.roundedPosition] = nil
	else
		warn("Destroyed old stand at a position", renderedStands[stand.roundedPosition].standId, stand.standId)
	end
end

function ClearStands()
	for position, stand in renderedStands do
		DestroyStand(stand)
	end
end

function UserRemovedItem(roundedPosition: Vector3)
	HandleItemAdded(roundedPosition, nil)
end

function CreateStands(showcase: Types.NetworkShowcase, positionMap: { [Vector3]: BasePart })
	local standMap: { [Vector3]: Types.Stand? } = {}
	for i, stand in showcase.stands do
		standMap[stand.roundedPosition] = stand
	end

	for roundedPosition, part in positionMap do
		local stand = standMap[roundedPosition]

		local existingStand = renderedStands[roundedPosition]
		if existingStand then
			if existingStand.assetId == (if stand then stand.assetId else nil) then
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
			assetId = if stand then stand.assetId else nil,
			standPart = part,
			roundedPosition = roundedPosition,
			prompt = prompt,
			standId = GetNextStandId(),

			shouldBob = shouldBob,
			hoverPosition = if shouldBob then math.random() else 0.5,

			shouldSpin = shouldSpin,
			rotation = if shouldSpin then math.random() * math.rad(360) else rotY,

			destroyed = false,
		}

		if stand and stand.assetId then
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
			if stand and stand.assetId then
				prompt.ActionText = "Remove Item"
				prompt.ObjectText = "Stand"
				prompt.Parent = part
				prompt.Triggered:Connect(function()
					UserRemovedItem(roundedPosition)
				end)
			else
				SetDisplayVisibility(part, true)
				prompt.ActionText = "Add Item"
				prompt.ObjectText = "Stand"
				prompt.Parent = part
				prompt.Triggered:Connect(function()
					AddItemUI:Display(roundedPosition)
				end)
			end
		else
			SetDisplayVisibility(part, false)
			if stand and stand.assetId then
				prompt.ActionText = "View Item"
				prompt.ObjectText = "Stand"
				prompt.Parent = part
				prompt.Triggered:Connect(function()
					print("Todo: view item")
				end)
			end
		end

		renderedStands[roundedPosition] = renderedStand
	end
end

function LoadShowcaseAppearance(showcase: Types.NetworkShowcase)
	if not currentShowcase or not currentModel then
		return
	end

	debug.profilebegin("LoadShowcaseAppearance")

	-- Go through descendants here rather than using collectionservice, as there will be many places in the workspace.
	for i, descendant in currentModel:GetDescendants() do
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

function HandleLoadShowcase(showcase: Types.NetworkShowcase)
	print("Loading showcase", showcase)

	if
		not currentShowcase
		or currentShowcase.GUID ~= showcase.GUID
		or currentShowcase.layoutId ~= showcase.layoutId
	then
		if currentModel then
			currentModel:Destroy()
		end
		ClearStands()

		currentModel = Layouts:GetLayout(showcase.layoutId).modelTemplate:Clone()
		assert(currentModel)

		currentModel:PivotTo(CFrame.new())
		currentModel.Parent = workspace

		local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
		character:PivotTo(currentModel:GetPivot())
	end
	assert(currentModel)

	currentShowcase = showcase
	ShowcaseEditUI:Hide()
	ShowcaseNavigationUI:Hide()

	if showcase then
		LoadShowcaseAppearance(showcase)

		local positionMap: { [Vector3]: BasePart } = {}
		for i, descendant in currentModel:GetDescendants() do
			if descendant:IsA("BasePart") and descendant:HasTag(Config.StandTag) then
				local position = Util.RoundedVector(currentModel:GetPivot():PointToObjectSpace(descendant.Position))
				positionMap[position] = descendant
			end
		end
		CreateStands(showcase, positionMap)

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

	for roundedPosition, stand in renderedStands do
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
		local position = stand.standPart.Position + Vector3.new(0, 0.5 + 0.5 * hoverAlpha, 0)
		model:PivotTo(CFrame.new(position) * CFrame.Angles(0, stand.rotation, 0))
	end
	debug.profileend()
end

function HandleItemAdded(roundedPosition: Vector3, assetId: number?)
	print("Adding item", roundedPosition, assetId)
	UpdateShowcaseEvent:Fire({
		type = "UpdateStand",
		roundedPosition = roundedPosition,
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

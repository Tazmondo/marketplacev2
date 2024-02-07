local ShopController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local DataEvents = require(ReplicatedStorage.Events.DataEvents)
local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local AccessoryCache = require(ReplicatedStorage.Modules.Client.AccessoryCache)
local CatalogUI = require(ReplicatedStorage.Modules.Client.UI.CatalogUI)
local CartController = require(ReplicatedStorage.Modules.Client.CartController)
local CharacterCache = require(ReplicatedStorage.Modules.Client.CharacterCache)
local ProfileUI = require(ReplicatedStorage.Modules.Client.UI.ProfileUI)
local ShopEditUI = require(ReplicatedStorage.Modules.Client.UI.ShopEditUI)
local UITypes = require(ReplicatedStorage.Modules.Client.UI.UITypes)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local MallCFrames = require(ReplicatedStorage.Modules.Shared.MallCFrames)
local Material = require(ReplicatedStorage.Modules.Shared.Material)
local Thumbs = require(ReplicatedStorage.Modules.Shared.Thumbs)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Accessory replication folder did not exist.")

local renderedAccessoryFolder = assert(
	workspace:FindFirstChild("Rendered Accessories"),
	"Workspace did not have rendered accessories folder."
) :: Folder

local placeholderFolder = ReplicatedStorage.Assets["Shop Placeholders"] :: Folder
local dynamicPlaceholder = placeholderFolder:FindFirstChild("DynamicPlaceholder")
local shopPlaceholder = placeholderFolder:FindFirstChild("ShopPlaceholder")

local shopSignTemplate = ReplicatedStorage.Assets:FindFirstChild("ShopInfo") :: Model
assert(shopSignTemplate, "No shopsign model found in RS assets folder.")

local randomTimerTemplate = ReplicatedStorage.Assets.UI.Timer :: UITypes.RandomTimer

assert(dynamicPlaceholder and dynamicPlaceholder:IsA("Model"), "No dynamic shop placeholder found")
assert(shopPlaceholder and shopPlaceholder:IsA("Model"), "No shop placeholder found")

local assetsFolder = assert(ReplicatedStorage:FindFirstChild("Assets")) :: Folder
local highlightTemplate = assert(assetsFolder:FindFirstChild("ItemHighlight")) :: Highlight

ShopController.ShopEntered = Signal() :: Signal.Signal<RenderedShop?>

type RenderedStand = {
	standPart: BasePart,
	roundedPosition: Vector3,
	standId: number,
	item: {
		id: number,
		type: Types.StandType,
	}?,
	prompt: ProximityPrompt,

	hoverPosition: number,
	rotation: number,

	shouldBob: boolean,
	shouldSpin: boolean,

	renderModel: Model?,

	-- Since fetching the model is asynchronous, we need this in case a stand is destroyed
	-- Before the model is fetched, so the code knows not to parent the model
	destroyed: boolean,
	[string]: never,
}

type RenderedOutfit = {
	standId: number,
	CFrame: CFrame,
	placeholderModel: Model,
	prompt: ProximityPrompt,
	roundedPosition: Vector3,

	description: Types.SerializedDescription?,
	outfitModel: Model?,

	-- Since fetching the model is asynchronous, we need this in case a stand is destroyed
	-- Before the model is fetched, so the code knows not to parent the model
	destroyed: boolean,
	[string]: never,
}

type ShopMode = "View" | "Edit" | "Random"

type BaseRenderedShop = {
	renderedStands: { [Vector3]: RenderedStand },
	renderedOutfitStands: { [Vector3]: RenderedOutfit },
	cframe: CFrame, -- Not the pivot, but the mall cframe it is attached to.
	currentModel: Model,
	details: Types.Shop,
	destroyed: boolean,
}

type RegularShop = BaseRenderedShop & {
	mode: "View" | "Edit",
}

type RandomShop = BaseRenderedShop & {
	mode: "Random",
	gui: UITypes.RandomTimer,
	countdown: number,
	paused: boolean,
}

type RenderedShop = RegularShop | RandomShop

type PlaceholderShop = {
	model: Model,
	cframe: CFrame,
	[string]: never,
}

-- Subtract from the placeholder pivot to get the ground position
local OUTFIT_VERTICAL_OFFSET = 3.7162

local renderedShops: { RenderedShop } = {}
local placeholderShops: { PlaceholderShop } = {}
local dynamicShop: RenderedShop? = nil
local currentEnteredShop: RenderedShop? = nil

-- Allows for comparison between stand objects.
-- I would do this by comparing the tables are the same but luau type system doesn't like that?
local standId = 0
local function GetNextStandId()
	standId += 1
	return standId
end

local function GetTeleportCFrame(shopCFrame: CFrame): CFrame
	return shopCFrame * CFrame.new(0, 5, -10) * CFrame.Angles(0, math.pi, 0)
end

local function ClaimShop(cframe: CFrame, guid: string)
	ShopEvents.ClaimShop:FireServer(cframe, guid)
end

local function RenderPlaceholderShop(cframe: CFrame)
	local shop = MallCFrames.GetShop(cframe)
	if not shop then
		return
	end

	local placeholder
	if shop.type == "Dynamic" then
		placeholder = dynamicPlaceholder:Clone()
	else
		placeholder = shopPlaceholder:Clone()
	end

	local frontAttachment = placeholder:FindFirstChild("FrontAttachment") :: BasePart?
	assert(frontAttachment, "Placeholder did not have a front attachment")

	frontAttachment.Transparency = 1

	local pivotFromFront = frontAttachment.CFrame:ToObjectSpace(placeholder:GetPivot())
	placeholder:PivotTo(cframe:ToWorldSpace(pivotFromFront))

	if shop.type ~= "Dynamic" then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Claim"
		prompt.ObjectText = "Shop"
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 30

		prompt.Parent = frontAttachment

		prompt.Triggered:Connect(function()
			local selectedShop = ProfileUI:SelectShop():Await()
			if selectedShop then
				ClaimShop(cframe, selectedShop.GUID)
			end
		end)
	end

	placeholder.Parent = workspace

	table.insert(placeholderShops, {
		model = placeholder,
		cframe = cframe,
	})
end

local function DestroyPlaceholder(cframe: CFrame)
	local existingPlaceholder, index = TableUtil.Find(placeholderShops, function(shop)
		return (shop.cframe.Position - cframe.Position).Magnitude < 5
	end)
	if not existingPlaceholder or not index then
		return
	end

	existingPlaceholder.model:Destroy()
	table.remove(placeholderShops, index)
end

local function SetDisplayVisibility(display: BasePart | Model, isVisible: boolean)
	if display:IsA("BasePart") then
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
	else
		-- display is a model
		local TRANSPARENCY_ATTRIBUTE = "SHOP_DEFAULT_TRANSPARENCY"
		for i, part in display:GetDescendants() do
			if part:IsA("BasePart") then
				local defaultTransparency = part:GetAttribute(TRANSPARENCY_ATTRIBUTE)
				if not defaultTransparency then
					defaultTransparency = part.Transparency
					part:SetAttribute(TRANSPARENCY_ATTRIBUTE, defaultTransparency)
				end
				part.Transparency = if isVisible then defaultTransparency else 1
			end
		end
	end
end

local function GetStandItemModel(assetId: number, type: Types.StandType, scale: number?)
	return Future.new(function(assetId: number, type: Types.StandType, scale: number?): Model?
		local accessory = AccessoryCache:Get(assetId, type):Await()
		if not accessory then
			return nil
		end

		local insertedScale = accessory:GetScale()
		accessory:ScaleTo(insertedScale * Config.DefaultScale * (scale or 1))

		return accessory
	end, assetId, type, scale)
end

local function DestroyStand(shop: RenderedShop, stand: RenderedStand)
	stand.destroyed = true
	if stand.renderModel then
		stand.renderModel:Destroy()
	end

	stand.prompt:Destroy()

	if shop.renderedStands[stand.roundedPosition].standId == stand.standId then
		shop.renderedStands[stand.roundedPosition] = nil
	else
		warn("Destroyed old stand at a position")
	end
end

local function DestroyOutfitStand(shop: RenderedShop, stand: RenderedOutfit)
	stand.destroyed = true
	if stand.outfitModel then
		stand.outfitModel:Destroy()
	end

	stand.prompt:Destroy()
	if shop.renderedOutfitStands[stand.roundedPosition].standId == stand.standId then
		shop.renderedOutfitStands[stand.roundedPosition] = nil
	else
		warn("Destroyed old outfit stand at a position")
	end
end

local function DestroyShop(shop: RenderedShop)
	if shop.destroyed then
		warn(debug.traceback("Destroyed an already destroyed shop"))
		return
	end

	local index = assert(table.find(renderedShops, shop), "Destroyed shop without index.")
	table.remove(renderedShops, index);
	(shop :: BaseRenderedShop).destroyed = true
	shop.currentModel:Destroy()

	for _, stand in shop.renderedStands do
		DestroyStand(shop, stand)
	end

	for _, stand in shop.renderedOutfitStands do
		DestroyOutfitStand(shop, stand)
	end

	RenderPlaceholderShop(shop.cframe)
end

local function CreateOutfitStands(shop: RenderedShop, positionMap: { [Vector3]: Model })
	local standMap: { [Vector3]: Types.OutfitStand? } = {}
	for i, stand in shop.details.outfitStands do
		standMap[stand.roundedPosition] = stand
	end

	for roundedPosition, model in positionMap do
		local modelPart = model:FindFirstChild("LowerTorso")
		assert(modelPart, "Outfit placeholder did not have a lowertorso (for the prompt to go in)")

		local standScale = model:GetScale()
		local halvedScale = ((standScale - 1) * 0.5) + 1

		local stand = standMap[roundedPosition]
		local existingStand = shop.renderedOutfitStands[roundedPosition]
		if existingStand then
			local existingDescription = existingStand.description
			local newDescription = if stand then stand.description else nil

			if HumanoidDescription.Equal(existingDescription, newDescription) then
				continue
			else
				DestroyOutfitStand(shop, existingStand)
			end
		end

		local prompt = Instance.new("ProximityPrompt")
		prompt.RequiresLineOfSight = false
		prompt.UIOffset = Config.StandProximityOffset

		local renderedStand: RenderedOutfit = {
			CFrame = model:GetPivot(),
			standId = GetNextStandId(),
			placeholderModel = model,
			prompt = prompt,
			roundedPosition = roundedPosition,

			description = if stand then stand.description else nil,

			destroyed = false,
		}
		shop.renderedOutfitStands[roundedPosition] = renderedStand

		if stand and stand.description then
			CharacterCache:LoadWithDescription(stand.description):After(function(outfit)
				if not outfit then
					return
				end

				if renderedStand.destroyed then
					outfit:Destroy()
					return
				end

				outfit.Name = ""
				outfit:AddTag(Config.RenderedOutfitTag)
				SetDisplayVisibility(model, false)

				local humanoid = outfit:FindFirstChildOfClass("Humanoid") :: Humanoid
				local HRP = humanoid.RootPart :: BasePart
				HRP.Anchored = true

				outfit:ScaleTo(standScale)

				-- Silences "exception while signaling: Must be a LuaSourceContainer" error
				local animateScript = model:FindFirstChild("Animate") :: LocalScript?
				if animateScript then
					animateScript.Enabled = false -- just destroying didn't work, need to disable first.
					animateScript:Destroy()
				end

				-- Subtract the offset to get to ground level, then add hipheight and HRP size to position so feet are touching the ground
				local targetCFrame = renderedStand.CFrame
					+ Vector3.new(0, humanoid.HipHeight + (HRP.Size.Y / 2) - (OUTFIT_VERTICAL_OFFSET * halvedScale), 0)

				outfit:PivotTo(targetCFrame)
				renderedStand.outfitModel = outfit

				outfit.Parent = renderedAccessoryFolder
			end)
		end

		if shop.mode == "Edit" then
			if stand and stand.description then
				prompt.ActionText = "Remove Outfit"
				prompt.ObjectText = "Stand"
				prompt.Parent = modelPart

				prompt.Triggered:Connect(function()
					ShopEvents.UpdateOutfitStand:FireServer(roundedPosition, nil)
				end)
			else
				SetDisplayVisibility(model, true)
				prompt.ActionText = "Add Outfit"
				prompt.ObjectText = "Stand"
				prompt.Parent = modelPart

				prompt.Triggered:Connect(function()
					local outfit = CatalogUI:SelectOutfit():Await()
					if outfit then
						ShopEvents.UpdateOutfitStand:FireServer(roundedPosition, HumanoidDescription.Serialize(outfit))
					end
				end)
			end
		else
			SetDisplayVisibility(model, false)
			if stand and stand.description then
				prompt.ActionText = ""
				prompt.ObjectText = ""
				prompt.Parent = modelPart

				prompt.Triggered:Connect(function()
					CatalogUI:DisplayOutfit(HumanoidDescription.Deserialize(stand.description))
				end)
			end
		end
	end
end

local function CreateStands(shop: RenderedShop, positionMap: { [Vector3]: BasePart })
	local standMap: { [Vector3]: Types.Stand? } = {}
	for i, stand in shop.details.stands do
		standMap[stand.roundedPosition] = stand
	end

	for roundedPosition, part in positionMap do
		local stand = standMap[roundedPosition]

		local existingStand = shop.renderedStands[roundedPosition]
		if existingStand then
			if
				(if existingStand.item then existingStand.item.id else nil)
				== (if stand and stand.item then stand.item.id else nil)
			then
				continue
			else
				DestroyStand(shop, existingStand)
			end
		end

		local shouldBob = part:GetAttribute(Config.NoBobTag) ~= true
		local shouldSpin = part:GetAttribute(Config.NoSpinTag) ~= true
		local standScale: number = part:GetAttribute(Config.ScaleTag) or 1

		local prompt = Instance.new("ProximityPrompt")
		prompt.RequiresLineOfSight = false
		prompt.UIOffset = Config.StandProximityOffset

		local _, rotY, _ = part.CFrame:ToEulerAnglesYXZ()

		local renderedStand: RenderedStand = {
			item = if stand then stand.item else nil,
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
		shop.renderedStands[roundedPosition] = renderedStand

		if stand and stand.item then
			GetStandItemModel(stand.item.id, stand.item.type, standScale):After(function(model)
				if not model then
					return
				end

				if renderedStand.destroyed then
					model:Destroy()
				else
					model.Parent = renderedAccessoryFolder
					renderedStand.renderModel = model
					model:SetAttribute("OwnerId", shop.details.owner)

					-- Set this here, so that the placeholder is still there until the model has loaded
					SetDisplayVisibility(part, false)
					local promptParentPart = model:FindFirstChild("HumanoidRootPart")
						or model:FindFirstChildOfClass("MeshPart")
					if not promptParentPart then
						warn(`Model inserted without valid prompt parent: {stand.item.id}`)
						return
					end

					prompt.PromptShown:Connect(function()
						highlightTemplate:Clone().Parent = promptParentPart
					end)

					prompt.PromptHidden:Connect(function()
						local highlight = promptParentPart:FindFirstChild(highlightTemplate.Name)
						if highlight then
							highlight:Destroy()
						end
					end)
				end
			end)
		end

		if shop.mode == "Edit" then
			if stand and stand.item then
				prompt.ActionText = "Remove Item"
				prompt.ObjectText = "Stand"
				prompt.Parent = part
				prompt.Triggered:Connect(function()
					ShopEvents.UpdateStand:FireServer(roundedPosition, nil)
				end)
			else
				SetDisplayVisibility(part, true)
				prompt.ActionText = "Add Item"
				prompt.ObjectText = "Stand"
				prompt.Parent = part
				prompt.Triggered:Connect(function()
					local selectedItem = CatalogUI:SelectItem():Await()
					if selectedItem then
						ShopEvents.UpdateStand:FireServer(roundedPosition, selectedItem.id)
					end
				end)
			end
		else
			SetDisplayVisibility(part, false)
			if stand and stand.item then
				prompt.ActionText = ""
				prompt.ObjectText = ""
				prompt.Parent = part
				prompt.Triggered:Connect(function()
					if stand.item.type == "Accessory" then
						CartController:ToggleInCart(stand.item.id, shop.details.owner)
					else
						CartController:ToggleClassicClothing(stand.item.id, stand.item.type, shop.details.owner)
					end
				end)
				-- prompt.Enabled = false
			end
		end
	end
end

local function LoadShopAppearance(shop: RenderedShop)
	debug.profilebegin("LoadShopAppearance")

	local materialSet = Material:GetMaterialSet(shop.details.texture)
	if not materialSet then
		materialSet = Material:GetMaterialSet(Material:GetDefault())
		warn("Invalid texture found, should never be reached.", shop.details.texture)
	end
	assert(materialSet)

	-- Go through descendants here rather than using collectionservice, as there will be many places in the workspace.
	for i, descendant in shop.currentModel:GetDescendants() do
		if descendant:IsA("BasePart") then
			if descendant:HasTag(Config.PrimaryColorTag) then
				if descendant:IsA("PartOperation") then
					descendant.UsePartColor = true
				end
				descendant.Color = shop.details.primaryColor
			elseif descendant:HasTag(Config.AccentColorTag) then
				if descendant:IsA("PartOperation") then
					descendant.UsePartColor = true
				end
				descendant.Color = shop.details.accentColor
			end

			if descendant:HasTag(Config.TextureTag) then
				descendant.Material = materialSet.material
				descendant.MaterialVariant = materialSet.variant or ""
			end
		end
	end

	local layout = Layouts:GetLayout(shop.details.layoutId)
	if layout.hasLogo then
		local logo = shop.currentModel:FindFirstChild("ShopLogo") :: BasePart
		local gui = logo:FindFirstChild("SurfaceGui") :: SurfaceGui
		local image = gui:FindFirstChild("ImageLabel") :: ImageLabel
		image.Image = if shop.details.logoId then Thumbs.GetAsset(shop.details.logoId) else ""
	end

	debug.profileend()
end

local function CreateShopSign(shop: Types.Shop)
	local shopSign = shopSignTemplate:Clone()
	local gui = shopSign:FindFirstChild("SurfaceGui", true) :: UITypes.ShopInfoGui
	local guiDetails = gui.Profile.Frame.Profile
	guiDetails.Details.NameLabel.Text = "Loading..."
	guiDetails.Details.Details.Text = "Loading..."
	guiDetails.Thumb.Image = Thumbs.GetHeadShot(shop.owner)

	task.spawn(function()
		local name = Players:GetNameFromUserIdAsync(shop.owner)
		if shopSign.Parent ~= nil then
			guiDetails.Details.NameLabel.Text = `@{name}`
		end
	end)

	DataEvents.FetchEarned:Call(shop.owner):After(function(success, earned)
		if not success or not earned or shopSign.Parent == nil then
			guiDetails.Details.Details.Text = "Failed to fetch!"
			return
		end

		guiDetails.Details.Details.Text = `R${FormatNumber.Simple.FormatCompact(earned)} Earned`
	end)

	return shopSign
end

local function NewShop(shopCFrame: CFrame, shopDetails: Types.Shop, mode: ShopMode): RenderedShop
	DestroyPlaceholder(shopCFrame)

	local layout = Layouts:GetLayout(shopDetails.layoutId)
	local model = layout.modelTemplate:Clone()

	local storefront = Layouts:GetStorefront(shopDetails.storefrontId)
	local storefrontModel = storefront.modelTemplate:Clone()

	local shopSign = CreateShopSign(shopDetails)

	local label = storefront.getNameLabel(storefrontModel)
	label.Text = shopDetails.name

	model:PivotTo(shopCFrame * layout.attachment)
	storefrontModel:PivotTo(shopCFrame * storefront.attachment)
	storefrontModel.Parent = model

	shopSign:PivotTo(shopCFrame) -- the pivot offset is already correctly set
	shopSign.Parent = model

	model.Parent = workspace

	local shop: RenderedShop

	if mode == "Random" then
		local gui = randomTimerTemplate:Clone()
		gui.Parent = model

		local newShop: RandomShop = {
			cframe = shopCFrame,
			currentModel = model,
			details = shopDetails,
			renderedStands = {},
			renderedOutfitStands = {},
			mode = mode,
			destroyed = false,
			gui = gui,
			countdown = Config.RandomShopTimeout,
			paused = false,
		}
		shop = newShop
	else
		local newShop: RegularShop = {
			cframe = shopCFrame,
			currentModel = model,
			details = shopDetails,
			renderedStands = {},
			renderedOutfitStands = {},
			mode = mode,
			destroyed = false,
		}
		shop = newShop
	end
	LoadShopAppearance(shop)

	local positionMap = {}
	local outfitPositionMap = {}

	for i, descendant in model:GetDescendants() do
		if descendant:HasTag(Config.StandTag) then
			assert(descendant:IsA("BasePart"), "Non-part tagged as stand.")
			local position = Util.RoundedVector(model:GetPivot():PointToObjectSpace(descendant.Position))
			positionMap[position] = descendant
		elseif descendant:HasTag(Config.OutfitStandTag) then
			assert(descendant:IsA("Model"), "Non-model tagged as outfit stand.")
			local position = Util.RoundedVector(model:GetPivot():PointToObjectSpace(descendant:GetPivot().Position))
			outfitPositionMap[position] = descendant
		end
	end
	CreateStands(shop, positionMap)
	CreateOutfitStands(shop, outfitPositionMap)

	return shop
end

local function LoadDynamicShop(shopDetails: Types.Shop)
	if dynamicShop then
		DestroyShop(dynamicShop)
	end

	local mallShop = MallCFrames.dynamicShop
	local shop = NewShop(mallShop.cframe, shopDetails, "View")
	dynamicShop = shop
	table.insert(renderedShops, shop)
end

local function HandleLoadShop(shopCFrame: CFrame, options: ShopEvents.LoadShopSettings)
	local existingShop = TableUtil.Find(renderedShops, function(shop)
		return (shop.cframe.Position - shopCFrame.Position).Magnitude < 5
	end)
	if existingShop then
		DestroyShop(existingShop)
	end

	if not options then
		return
	end

	local mode: ShopMode = if options.shop.owner == Players.LocalPlayer.UserId
			and options.spawnMode == "Player"
		then "Edit"
		elseif options.spawnMode == "Random" then "Random"
		else "View"

	local shop = NewShop(shopCFrame, options.shop, mode)
	table.insert(renderedShops, shop)
end

local function GetTweenedStandAlpha(alpha: number)
	if alpha >= 0.5 then
		return 1 - TweenService:GetValue((2 * (alpha - 0.5)), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	else
		return TweenService:GetValue((2 * alpha), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	end
end

local function RenderStands(dt: number)
	debug.profilebegin("RenderStands")
	for _, shop in renderedShops do
		for roundedPosition, stand in shop.renderedStands do
			local model = stand.renderModel

			if not model or not stand.item then
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
			local positionOffset = if stand.item.type == "Accessory" then 0 else 0.8
			local position = stand.standPart.Position
				+ Vector3.new(0, 0.5 + 0.5 * hoverAlpha, 0)
				+ Vector3.new(0, positionOffset, 0)
			model:PivotTo(CFrame.new(position) * CFrame.Angles(0, stand.rotation, 0))
		end
	end

	debug.profileend()
end

local function CheckCurrentShop()
	local char = Players.LocalPlayer.Character
	if not char then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local charPos = char:GetPivot().Position

	local enteredShop
	for _, shop in renderedShops do
		local origin, size = shop.currentModel:GetBoundingBox()

		-- idk why u need to do it like this ngl, but it is what it is
		-- makes it easier to edit storefronts as you can still edit while standing outside the shop
		local extraLength = if shop.mode == "Edit"
			then Util.AbsoluteVector(
				origin:VectorToObjectSpace(Util.AbsoluteVector(shop.cframe:VectorToObjectSpace(Vector3.new(0, 0, 30))))
			)
			else Vector3.zero

		if Util.PointInBounds(charPos, origin, size + extraLength) then
			enteredShop = shop
			break
		end
	end
	if not enteredShop then
		for _, shop in placeholderShops do
			local origin, size = shop.model:GetBoundingBox()
			if Util.PointInBounds(charPos, origin, size) then
				char:PivotTo(GetTeleportCFrame(shop.cframe))
				break
			end
		end
	end

	if enteredShop == currentEnteredShop then
		return
	end
	currentEnteredShop = enteredShop
	ShopController.ShopEntered:Fire(enteredShop)

	-- move faster outside of shops
	local targetWalkspeed = if enteredShop == nil then Config.MallSpeed else Config.ShopSpeed
	TweenService:Create(humanoid, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { WalkSpeed = targetWalkspeed }):Play()

	if enteredShop and enteredShop.mode == "Edit" then
		ShopEditUI:Display(enteredShop.details)
	else
		ShopEditUI:Hide()
	end
end

local function TickRandomShops(dt: number)
	for _, shop in renderedShops do
		if shop.mode ~= "Random" then
			continue
		end

		if not shop.paused then
			shop.countdown = math.max(shop.countdown - dt, 0)
		end
		shop.gui.Frame.Timer.Progress.Size = UDim2.fromScale(shop.countdown / Config.RandomShopTimeout, 1)
	end
end

local function HandleRandomShopTimer(cframe: CFrame, paused: boolean)
	local existingShop = TableUtil.Find(renderedShops, function(shop)
		return (shop.cframe.Position - cframe.Position).Magnitude < 5 and shop.mode == "Random"
	end) :: RandomShop?

	if existingShop then
		existingShop.paused = paused
		existingShop.countdown = Config.RandomShopTimeout
	end
end

local function PreRender(dt: number)
	RenderStands(dt)
	TickRandomShops(dt)
end

local function PostSimulation()
	CheckCurrentShop()
end

function ShopController:LoadDynamicShopFromCode(code: number)
	return Future.new(function(code)
		local success, details = DataEvents.GetShop:Call(code):Await()
		if not success then
			warn(details)
			return
		end
		if not details then
			warn("details not found")
			return
		end
		LoadDynamicShop(details)
		local char = Players.LocalPlayer.Character
		if char and dynamicShop then
			char:PivotTo(GetTeleportCFrame(dynamicShop.cframe))
		end
	end, code)
end

function ShopController:Initialize()
	RunService.PreRender:Connect(PreRender)
	RunService.PostSimulation:Connect(PostSimulation)

	ShopEvents.LoadShop:SetClientListener(HandleLoadShop)
	ShopEvents.SetRandomShopTimer:SetClientListener(HandleRandomShopTimer)

	ShopEditUI.ShopSelected:Connect(function(shop)
		if not currentEnteredShop or currentEnteredShop.mode ~= "Edit" or not shop then
			return
		end
		ClaimShop(currentEnteredShop.cframe, shop.GUID)
	end)

	for _, shopCFrame in MallCFrames.shops do
		RenderPlaceholderShop(shopCFrame.cframe)
	end
	RenderPlaceholderShop(MallCFrames.dynamicShop.cframe)

	Players.LocalPlayer.CharacterAdded:Once(function(char)
		-- since the walk speed setter doesn't work on the first pass
		local humanoid = char:WaitForChild("Humanoid") :: Humanoid
		humanoid.WalkSpeed = Config.MallSpeed
	end)
end

ShopController:Initialize()

return ShopController

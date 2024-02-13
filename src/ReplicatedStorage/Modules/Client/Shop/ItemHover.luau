local ItemHover = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local PurchaseEvents = require(ReplicatedStorage.Events.PurchaseEvents)
local CartController = require(ReplicatedStorage.Modules.Client.CartController)
local CatalogUI = require(ReplicatedStorage.Modules.Client.UI.CatalogUI)
local UILoader = require(ReplicatedStorage.Modules.Client.UI.UILoader)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

local assets = ReplicatedStorage.Assets :: Folder
local highlightTemplate = assert(assets:FindFirstChild("ItemHighlight"), "No item highlight found") :: Highlight

local renderedAccessoryFolder = assert(
	workspace:FindFirstChild("Rendered Accessories"),
	"Workspace did not have rendered accessories folder."
) :: Folder

local gui = UILoader:GetMain().Hover

type ItemType = "Item" | "Outfit"

type State = {
	hovered: {
		type: ItemType,
		part: BasePart,
		model: Model,
		highlight: Highlight,
	}?,
	selected: {
		id: number,
		shopOwner: number,
		part: BasePart,
		model: Model,
		movedConnection: RBXScriptConnection,
		highlight: Highlight,
	}?,
}

local HOVERSCALE = 1.15
local state: State = {}

local function SetHover(part: BasePart?, model: Model?)
	if state.hovered then
		if part and state.hovered.part == part then
			return
		else
			state.hovered.highlight:Destroy()
			if state.hovered.type == "Item" and (not state.selected or state.selected.part ~= state.hovered.part) then
				state.hovered.model:ScaleTo(state.hovered.model:GetScale() / HOVERSCALE)
			end
			state.hovered = nil
		end
	end

	if part and model then
		local highlight = highlightTemplate:Clone()

		local type: ItemType = if model:HasTag(Config.RenderedAccessoryTag)
				or model:HasTag(Config.RenderedClassicClothingTag)
			then "Item"
			elseif model:HasTag(Config.RenderedOutfitTag) then "Outfit"
			else error("No valid tag found.")

		if type == "Outfit" then
			highlight.Parent = model
		else
			highlight.Parent = part
		end

		if type == "Item" and (not state.selected or state.selected.part ~= part) then
			model:ScaleTo(model:GetScale() * HOVERSCALE)
		end
		state.hovered = {
			type = type,
			highlight = highlight,
			part = part,
			model = model,
		}
	end
end

local function SetSelected(part: BasePart?)
	local function clearState()
		if not state.selected then
			return
		end
		state.selected.highlight:Destroy()
		state.selected.movedConnection:Disconnect()
		state.selected.model:ScaleTo(state.selected.model:GetScale() / HOVERSCALE)
		state.selected = nil
	end

	local function update(part: BasePart?)
		clearState()

		if part then
			local model = part.Parent
			if not model or not model:IsA("Model") then
				return
			end

			local ownerId = model:GetAttribute("OwnerId") :: number
			if not ownerId or typeof(ownerId) ~= "number" then
				warn("Clicked model without ownerid", ownerId)
				return
			end

			local id = tonumber(model.Name)
			if not id then
				warn(`{id} was not a valid asset!`)
				return
			end

			local highlight = highlightTemplate:Clone()
			highlight.Parent = part

			local movedConnection = part:GetPropertyChangedSignal("Position"):Connect(HandleCameraUpdated)

			state.selected = {
				highlight = highlight,
				id = id,
				shopOwner = ownerId,
				part = part,
				model = model,
				movedConnection = movedConnection,
			}

			gui.Frame.Details.Creator.Text = "Loading..."
			gui.Frame.Details.Item.Text = "Loading..."
			DataFetch.GetItemDetails(id):After(function(item)
				if not item or not state.selected or state.selected.part ~= part then
					return
				end

				gui.Frame.Details.Creator.Text = item.creator
				gui.Frame.Details.Item.Text = Util.TruncateString(item.name, 17)
			end)
		end
	end

	update(part)
	HandleCameraUpdated()
end

function HandleCameraUpdated()
	if not state.selected then
		gui.Visible = false
		return
	end
	gui.Visible = true

	local cam = workspace.CurrentCamera

	local model = state.selected.model
	local modelSize = model:GetExtentsSize()
	local offset = math.max(modelSize.X, modelSize.Z) / 2 + 1

	local partPosition, onScreen = cam:WorldToViewportPoint(state.selected.part.Position)
	if not onScreen then
		SetSelected()
		return
	end

	-- Position to the right if the part is on the left, and vice versa
	if partPosition.X < cam.ViewportSize.X * 0.78 then
		local rightPartPosition =
			cam:WorldToViewportPoint(state.selected.part.Position + cam.CFrame.RightVector * offset)
		gui.AnchorPoint = Vector2.new(0, 0.5)
		gui.Position = UDim2.fromOffset(rightPartPosition.X, rightPartPosition.Y)
	else
		gui.AnchorPoint = Vector2.new(1, 0.5)
		local leftPartPosition =
			cam:WorldToViewportPoint(state.selected.part.Position - cam.CFrame.RightVector * offset)
		gui.Position = UDim2.fromOffset(leftPartPosition.X, leftPartPosition.Y)
	end
end

local function HandleMouseMove(inputObject: InputObject)
	local position = inputObject.Position
	local ray = workspace.CurrentCamera:ScreenPointToRay(position.X, position.Y)

	local params = RaycastParams.new()

	-- params.FilterDescendantsInstances = { Players.LocalPlayer.Character }
	-- params.FilterType = Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = { renderedAccessoryFolder }
	params.FilterType = Enum.RaycastFilterType.Include

	local raycast = workspace:Raycast(ray.Origin, ray.Direction * 200, params)
	if not raycast then
		SetHover()
		return
	end

	local hitPart = raycast.Instance :: BasePart
	local model = hitPart.Parent

	-- Allow for clicking on accessories on outfits
	if model and model:IsA("Accessory") then
		model = model.Parent
	end

	if
		not model
		or not model:IsA("Model")
		or (
			not model:HasTag(Config.RenderedAccessoryTag)
			and not model:HasTag(Config.RenderedOutfitTag)
			and not model:HasTag(Config.RenderedClassicClothingTag)
		)
	then
		SetHover()
		return
	end

	SetHover(hitPart, model)
end

local function HandleClick(inputObject: InputObject)
	if state.selected then
		if state.hovered and state.hovered.part == state.selected.part then
			-- Clicked on the same part
			return
		end

		SetSelected()
	end

	if not state.hovered then
		return
	end

	if state.hovered.type == "Item" then
		local hitPart = state.hovered.part
		SetSelected(hitPart)
	elseif state.hovered.type == "Outfit" then
		local humanoid = state.hovered.model:FindFirstChildOfClass("Humanoid") :: Humanoid
		local description =
			assert(humanoid:FindFirstChildOfClass("HumanoidDescription"), "Outfit model had no description")
		local owner = state.hovered.model:GetAttribute("OwnerId")
		if typeof(owner) ~= "number" then
			warn("OwnerId not found", owner)
		end
		CatalogUI:DisplayOutfit(description, owner)
	else
		error("Invalid item type")
	end
end

local function HandleInputBegan(inputObject: InputObject, processed: boolean)
	if processed then
		return
	end

	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		HandleClick(inputObject)
	elseif inputObject.UserInputType == Enum.UserInputType.Touch then
		-- since mobile users cant hover, we just "hover" and then immediately select
		HandleMouseMove(inputObject)
		HandleClick(inputObject)
	end
end

local function HandleInputChanged(inputObject: InputObject, processed: boolean)
	if processed then
		return
	end

	if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
		HandleMouseMove(inputObject)
	end
end

local function HandleBuy()
	if not state.selected then
		return
	end

	PurchaseEvents.Asset:FireServer(state.selected.id, state.selected.shopOwner)
end

local function HandleTry()
	if not state.selected then
		return
	end

	DataFetch.GetItemDetails(state.selected.id):After(function(data)
		if not data then
			return
		end
		if
			data.assetType == Enum.AvatarAssetType.TShirt
			or data.assetType == Enum.AvatarAssetType.Shirt
			or data.assetType == Enum.AvatarAssetType.Pants
		then
			CartController:ToggleClassicClothing(
				state.selected.id,
				data.assetType.Name :: "Pants" | "Shirt" | "TShirt",
				state.selected.shopOwner
			)
		else
			CartController:ToggleInCart(state.selected.id, state.selected.shopOwner)
		end
	end)

	SetSelected()
end

local function Initialize()
	UserInputService.InputBegan:Connect(HandleInputBegan)
	UserInputService.InputChanged:Connect(HandleInputChanged)

	gui.Frame.Frame.Buy.Activated:Connect(HandleBuy)
	gui.Frame.Frame.Try.Activated:Connect(HandleTry)

	workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(HandleCameraUpdated)
end

Initialize()

return ItemHover

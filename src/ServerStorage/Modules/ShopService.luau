local ShopService = {}

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local PurchaseEvents = require(ReplicatedStorage.Events.PurchaseEvents)
local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local VisibilityEvent = require(ReplicatedStorage.Events.VisibilityEvent)
local DataService = require(script.Parent.Data.DataService)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Future = require(ReplicatedStorage.Packages.Future)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local Material = require(ReplicatedStorage.Modules.Shared.Material)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local EditShopEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.EditShowcaseEvent):Server()
local CreateShopEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.CreateShowcaseEvent):Server()
local LoadShopEvent = require(ReplicatedStorage.Events.Showcase.ServerFired.LoadShowcaseEvent):Server()
local DeleteShopEvent = require(ReplicatedStorage.Events.Showcase.ClientFired.DeleteShowcaseEvent):Server()

type ActiveShop = {
	stands: { Types.Stand },
	outfitStands: { Types.OutfitStand },
	playersPresent: { [Player]: true },
	owner: number, -- UserId since owner doesn't have to be in the server
	mode: Types.ShopMode,

	-- Since updating is an asynchronous operation, we don't want old updates to override new ones
	lastUpdate: number,

	name: string,
	layout: Layouts.Layout,
	primaryColor: Color3,
	accentColor: Color3,
	texture: string,
	logoId: number?,
	GUID: string,
	shareCode: number?,
	thumbId: number,
}

local placeTable: { ActiveShop } = {}

local playerShops: { [Player]: ActiveShop? } = {}

-- Don't instance it at run-time as it can cause a race condition on client where sometimes it will find and sometimes it wont
local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Expected ReplicatedStorage.AccessoryReplication folder.")

-- Specialmeshes do not support a way to get their size.
-- MeshParts do.
-- When using Players:CreateHumanoidModelFromDescription with R15 rigs, it generates accessories using MeshParts
-- So we can use this to generate a MeshPart and normalize its size.
function ReplicateAsset(assetId: number)
	return Future.new(function()
		if not accessoryReplication:FindFirstChild(tostring(assetId)) then
			local description = Instance.new("HumanoidDescription")
			description.FaceAccessory = tostring(assetId)

			local playerModel = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)

			if accessoryReplication:FindFirstChild(tostring(assetId)) then
				-- Already found while this was yielding
				return
			end

			local accessory = playerModel:FindFirstChildOfClass("Accessory")
			if not accessory then
				return
			end
			local meshPart = accessory:FindFirstChildOfClass("MeshPart")
			if not meshPart then
				warn(`Accessory generated without meshpart {assetId}`)
				return
			end

			-- Rotation offset of the model from the player
			-- This allows us to set the pivot so the orientation when CFraming is the same as if it was attached to a player
			-- I.e. the front of the model faces forwards.
			-- Need to parent to workspace too otherwise it doesn't return the correct value
			-- Parenting to the camera means they won't get replicated to the client unnecessarily too.
			playerModel.Parent = workspace.CurrentCamera
			local pivot = playerModel:GetPivot():ToObjectSpace(meshPart.CFrame).Rotation:Inverse()
			meshPart.PivotOffset = pivot

			local model = Instance.new("Model")
			meshPart.Parent = model
			model.PrimaryPart = meshPart
			model.Name = tostring(assetId)

			playerModel:Destroy()

			local vectorSize = meshPart.Size
			local maxSize = math.max(vectorSize.X, vectorSize.Y, vectorSize.Z)

			-- Scale meshpart so it fits within a 1x1x1 cube
			local scale = 1 / maxSize

			local wrapLayer = meshPart:FindFirstChildOfClass("WrapLayer")
			if wrapLayer then
				wrapLayer:Destroy()
			end

			model:ScaleTo(scale)
			model.Parent = accessoryReplication
			return true

			-- This is the old code for fetching models through InsertService
			-- It wasn't suitable because there was no way to get consistent sizing for the items.

			-- local asset = InsertService:LoadAsset(assetId)
			-- asset.Name = tostring(assetId)

			-- -- Since fetching is async, this could get called twice, but we don't want unnecessary duplicates.
			-- if not accessoryReplication:FindFirstChild(tostring(assetId)) then
			-- 	asset.Parent = accessoryReplication
			-- 	return true
			-- end
		end
		return false
	end)
end

function ToNetworkShop(shop: ActiveShop): Types.NetworkShop
	return {
		stands = shop.stands,
		outfitStands = shop.outfitStands,
		layoutId = shop.layout.id,
		mode = shop.mode,
		owner = shop.owner,
		name = shop.name,
		GUID = shop.GUID,
		shareCode = shop.shareCode,
		primaryColor = shop.primaryColor,
		accentColor = shop.accentColor,
		texture = shop.texture,
		thumbId = shop.thumbId,
		logoId = shop.logoId,
	}
end

function ShopService:ExitPlayerShop(player: Player, shop: ActiveShop)
	shop.playersPresent[player] = nil

	if next(shop.playersPresent) == nil then
		-- Empty
		ShopService:UnloadPlace(shop)
		return
	end

	local visiblePlayers = {}
	for player, _ in shop.playersPresent do
		table.insert(visiblePlayers, player)
	end
	VisibilityEvent:FireClients(visiblePlayers, visiblePlayers)
end

function ShopService:EnterPlayerShop(player: Player, shop: ActiveShop)
	local oldPlace = playerShops[player]

	-- Need to check GUIDs are different otherwise it will try and delete the old place.
	if oldPlace and oldPlace.GUID ~= shop.GUID then
		ShopService:ExitPlayerShop(player, oldPlace)
	end

	shop.playersPresent[player] = true
	playerShops[player] = shop

	LoadShopEvent:Fire(player, ToNetworkShop(shop))

	local visiblePlayers = {}
	for player, _ in shop.playersPresent do
		table.insert(visiblePlayers, player)
	end
	VisibilityEvent:FireClients(visiblePlayers, visiblePlayers)
end

function ShopService:GetShopOfPlayer(player: Player): ActiveShop?
	local shop = playerShops[player]
	return shop
end

function SaveShop(shop: ActiveShop)
	local owner = Players:GetPlayerByUserId(shop.owner)
	if not owner then
		warn("Tried to save shop for player not in-game")
		return
	end

	if shop.mode ~= "Edit" then
		warn("Tried to save shop when not in edit mode.")
		return
	end

	local data = DataService:ReadData(owner):Await()
	if not data then
		return
	end

	local shopIndex
	for i, v in data.shops do
		if v.GUID == shop.GUID then
			shopIndex = i
		end
	end

	if not shopIndex then
		warn("Could not find owned shop")
		return
	end

	-- Filter out stands that are invalid or lack an asset id
	-- Invalid stands can be caused when switching layouts - the old stands may not have valid positions anymore.
	local validPositions = shop.layout.getValidStandPositions()
	local filteredStands: { Data.Stand } = {}

	for _, stand in shop.stands do
		if stand.assetId and validPositions[stand.roundedPosition] then
			table.insert(filteredStands, {
				assetId = stand.assetId,
				roundedPosition = Data.VectorToTable(stand.roundedPosition),
			})
		end
	end

	local validOutfitPositions = shop.layout.getValidOutfitStandPositions()

	local filteredOutfitStands: { Data.OutfitStand } = {}
	for _, stand in shop.outfitStands do
		if stand.description and validOutfitPositions[stand.roundedPosition] then
			table.insert(filteredOutfitStands, {
				description = stand.description,
				roundedPosition = Data.VectorToTable(stand.roundedPosition),
			})
		end
	end

	local newShop: Data.Shop = {
		stands = filteredStands,
		outfitStands = filteredOutfitStands,
		layoutId = shop.layout.id,
		GUID = shop.GUID,
		shareCode = shop.shareCode,
		name = shop.name,
		primaryColor = shop.primaryColor:ToHex(),
		accentColor = shop.accentColor:ToHex(),
		texture = shop.texture,
		thumbId = shop.thumbId,
		logoId = shop.logoId,
	}

	DataService:WriteData(owner, function(data)
		data.shops[shopIndex] = newShop
	end)
end

function PopulateLayoutStands(savedStands: { Types.Stand }, standPositions: { [Vector3]: boolean }): { Types.Stand }
	local savedStandMap: { [Vector3]: Types.Stand } = {}
	for i, stand in savedStands do
		savedStandMap[stand.roundedPosition] = stand
	end

	local outputStands = {}

	for position, _ in standPositions do
		local stand = savedStandMap[position]
		if stand then
			table.insert(outputStands, stand)
			if stand.assetId then
				ReplicateAsset(stand.assetId)
			end
		else
			table.insert(outputStands, {
				assetId = nil,
				roundedPosition = position,
			})
		end
	end

	return outputStands
end

function PopulateLayoutOutfitStands(
	savedStands: { Types.OutfitStand },
	standPositions: { [Vector3]: boolean }
): { Types.OutfitStand }
	local savedStandMap = {}

	for i, stand in savedStands do
		savedStandMap[stand.roundedPosition] = stand
	end

	local outputStands = {}

	for position, _ in standPositions do
		local stand = savedStandMap[position]
		if stand then
			table.insert(outputStands, stand)
		else
			table.insert(outputStands, {
				description = nil,
				roundedPosition = position,
			})
		end
	end

	return outputStands
end

function ShopService:GetShop(shop: Types.Shop, mode: Types.ShopMode)
	-- Check for already existing shop with the same GUID, but only for viewing. Shops in edit mode should
	-- Be kept entirely separate because the mode is stored within the shop data itself, and not on a per-player basis.
	for i, place in placeTable do
		if place.GUID == shop.GUID and mode == "View" and place.mode == "View" then
			return place
		end
	end

	local layout = Layouts:GetLayout(shop.layoutId)

	-- Every physical part should have a registered stand
	-- This is necessary so the shop can accept stand updates for stands that don't yet have an item.
	local stands = PopulateLayoutStands(shop.stands, layout.getValidStandPositions())
	local outfitStands = PopulateLayoutOutfitStands(shop.outfitStands, layout.getValidOutfitStandPositions())

	local place: ActiveShop = {
		stands = stands,
		outfitStands = outfitStands,
		layout = layout,
		owner = shop.owner,
		playersPresent = {},
		mode = mode,
		GUID = shop.GUID,
		shareCode = shop.shareCode,
		name = shop.name,
		primaryColor = shop.primaryColor,
		accentColor = shop.accentColor,
		texture = shop.texture,
		lastUpdate = os.clock(),
		thumbId = shop.thumbId,
		logoId = shop.logoId,
	}

	table.insert(placeTable, place)

	return place
end

function ShopService:UnloadPlace(place: ActiveShop)
	if next(place.playersPresent) ~= nil then
		warn("Unloaded a place while players were still inside it!")
	end

	local index = table.find(placeTable, place)
	if index then
		table.remove(placeTable, index)
	else
		warn(debug.traceback("Tried to unload a place without it existing in the place table! Should never occur."))
	end
end

function HandleCreatePlace(player: Player)
	local data = DataService:ReadData(player):Await()
	if not data then
		return
	end

	if #data.shops >= Config.MaxPlaces then
		return
	end

	local newShop: Types.Shop = {
		name = `{player.Name}'s Shop`,
		layoutId = Config.DefaultLayout,
		stands = {},
		outfitStands = {},
		GUID = HttpService:GenerateGUID(false),
		owner = player.UserId,
		primaryColor = Config.DefaultPrimaryColor,
		accentColor = Config.DefaultAccentColor,
		texture = Material:GetDefault(),
		thumbId = Config.DefaultShopThumbnail,
		logoId = nil,
	}

	DataService:WriteData(player, function(data)
		table.insert(data.shops, Data.ToDataShop(newShop))
	end)
end

function HandleEditShop(player: Player, GUID: string)
	local data = DataService:ReadData(player):Await()
	if not data then
		return
	end

	local chosenShop
	for i, shop in data.shops do
		if shop.GUID == GUID then
			chosenShop = Data.FromDataShop(shop, player.UserId)
			break
		end
	end

	if not chosenShop then
		return
	end

	local place = ShopService:GetShop(chosenShop, "Edit")
	ShopService:EnterPlayerShop(player, place)
end

local function GetEditableShop(player: Player): ActiveShop?
	local shop = playerShops[player]
	if not shop then
		return nil
	end

	if shop.mode ~= "Edit" then
		warn(player, "Tried to update a shop that was not in edit mode.")
		return nil
	end

	return shop
end

function HandleUpdateStand(player: Player, roundedPosition: Vector3, assetId: number?)
	local shop = GetEditableShop(player)
	if not shop then
		return
	end

	if not shop.layout.getValidStandPositions()[roundedPosition] then
		warn("Updated with an invalid position:", roundedPosition)
		return
	end

	local stand = TableUtil.Find(shop.stands, function(stand)
		return stand.roundedPosition == roundedPosition
	end)

	if not stand then
		warn("Could not find stand when updating:", roundedPosition)
		return
	end

	if stand.assetId == assetId then
		-- Asset did not change
		return
	end

	stand.assetId = assetId
	if assetId then
		ReplicateAsset(assetId)
	end

	LoadShopEvent:Fire(player, ToNetworkShop(shop))
	SaveShop(shop)
end

local function HandleUpdateOutfitStand(
	player: Player,
	roundedPosition: Vector3,
	description: Types.SerializedDescription?
)
	local shop = GetEditableShop(player)
	if not shop then
		return
	end

	if not shop.layout.getValidOutfitStandPositions()[roundedPosition] then
		warn("Updated with an invalid position:", roundedPosition)
		return
	end

	local stand = TableUtil.Find(shop.outfitStands, function(stand)
		return stand.roundedPosition == roundedPosition
	end)

	if not stand then
		warn("Could not find stand when updating:", roundedPosition)
		return
	end

	if HumanoidDescription.Equal(stand.description, description) then
		-- Asset did not change
		return
	end

	stand.description = description

	LoadShopEvent:Fire(player, ToNetworkShop(shop))
	SaveShop(shop)
end

local function HandleUpdateShopSettings(player: Player, settings: ShopEvents.UpdateSettings)
	local shop = GetEditableShop(player)
	if not shop then
		return
	end

	local updateTime = os.clock()
	shop.lastUpdate = updateTime

	local primaryColorExists = Config.PrimaryColors[settings.primaryColor:ToHex()]
	if not primaryColorExists then
		warn("Invalid primary color sent:", settings.primaryColor)
		return
	end

	local accentColorExists = Config.AccentColors[settings.accentColor:ToHex()]
	if not accentColorExists then
		warn("Invalid accent color sent:", settings.accentColor)
		return
	end

	local textureExists = Material:TextureExists(settings.texture)
	if not textureExists then
		warn("Invalid texture sent:", settings.texture)
		return
	end

	if shop.name ~= settings.name then
		-- Yields
		local success, result = pcall(function()
			return TextService:FilterStringAsync(
					settings.name,
					player.UserId,
					Enum.TextFilterContext.PublicChat
				) :: TextFilterResult
		end)

		if not success then
			-- Unable to filter, assume it's bad
			-- This should really never happen
			warn("TextService filter was unsuccessful!")
			return
		end

		-- Yields
		local filteredName = result:GetNonChatStringForBroadcastAsync()

		-- Eliminates race conditions caused by updating name quickly
		if shop.lastUpdate ~= updateTime then
			return
		end

		shop.name = Util.LimitString(filteredName, Config.MaxPlaceNameLength)
	end

	shop.primaryColor = settings.primaryColor
	shop.accentColor = settings.accentColor
	shop.thumbId = settings.thumbId
	shop.logoId = settings.logoId
	shop.texture = settings.texture

	LoadShopEvent:Fire(player, ToNetworkShop(shop))
	SaveShop(shop)
end

local function HandleUpdateShopLayout(player: Player, layoutId: LayoutData.LayoutId)
	local shop = GetEditableShop(player)
	if not shop then
		return
	end
	local newLayout = Layouts:GetLayout(layoutId)
	shop.layout = newLayout
	shop.stands = PopulateLayoutStands(shop.stands, newLayout.getValidStandPositions())
	shop.outfitStands = PopulateLayoutOutfitStands(shop.outfitStands, newLayout.getValidOutfitStandPositions())

	LoadShopEvent:Fire(player, ToNetworkShop(shop))
	SaveShop(shop)
end

function HandleDeleteShop(player: Player, guid: string)
	DataService:WriteData(player, function(data)
		for i, shop in data.shops do
			if shop.GUID == guid then
				table.remove(data.shops, i)
				return
			end
		end

		warn("Tried to delete a non-existent shop")
	end)
end

local function HandlePurchaseAsset(player: Player, assetId: number)
	-- When we get exclusive deals we will need to secure this so users can't buy the exclusive assets.
	MarketplaceService:PromptPurchase(player, assetId)
end

local function PlayerRemoving(player: Player)
	local currentPlace = playerShops[player]
	if currentPlace then
		playerShops[player] = nil
		ShopService:ExitPlayerShop(player, currentPlace)
	end
end

function ShopService:Initialize()
	CreateShopEvent:On(HandleCreatePlace)
	EditShopEvent:On(HandleEditShop)
	DeleteShopEvent:On(HandleDeleteShop)
	PurchaseEvents.Asset:SetServerListener(HandlePurchaseAsset)

	ShopEvents.UpdateStand:SetServerListener(HandleUpdateStand)
	ShopEvents.UpdateOutfitStand:SetServerListener(HandleUpdateOutfitStand)
	ShopEvents.UpdateSettings:SetServerListener(HandleUpdateShopSettings)
	ShopEvents.UpdateLayout:SetServerListener(function(player, id)
		HandleUpdateShopLayout(player, id :: LayoutData.LayoutId)
	end)

	Players.PlayerRemoving:Connect(PlayerRemoving)
end

ShopService:Initialize()

return ShopService

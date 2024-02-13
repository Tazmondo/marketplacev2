--!nolint LocalShadow
local ShopService = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TextService = game:GetService("TextService")

local RandomFeed = require(ServerStorage.Modules.Feed.RandomFeed)
local ShopEvents = require(ReplicatedStorage.Events.ShopEvents)
local DataService = require(script.Parent.Data.DataService)
local LoadedService = require(script.Parent.LoadedService)
local PlayerSales = require(script.Parent.PlayerSales)
local SponsoredShops = require(script.Parent.SponsoredShops)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Layouts = require(ReplicatedStorage.Modules.Shared.Layouts.Layouts)
local MallCFrames = require(ReplicatedStorage.Modules.Shared.MallCFrames)
local Material = require(ReplicatedStorage.Modules.Shared.Material)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

local Future = require(ReplicatedStorage.Packages.Future)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

type ActiveShop = {
	stands: { Types.Stand },
	outfitStands: { Types.OutfitStand },
	owner: number, -- UserId since owner doesn't have to be in the server
	mode: Types.SpawnMode,
	cframe: CFrame,

	-- Since updating is an asynchronous operation, we don't want old updates to override new ones
	lastUpdate: number,

	name: string,
	layout: Layouts.Layout,
	storefront: Layouts.Storefront,
	primaryColor: Color3,
	accentColor: Color3,
	texture: string,
	logoId: number?,
	GUID: string,
	shareCode: number?,
	thumbId: number,
}

type RandomShop = {
	cooldownTime: number,
	activeShop: ActiveShop,
}

local activeShops: { ActiveShop } = {}

-- Don't instance it at run-time as it can cause a race condition on client where sometimes it will find and sometimes it wont
local accessoryReplication = ReplicatedStorage:FindFirstChild("AccessoryReplication") :: Folder
assert(accessoryReplication, "Expected ReplicatedStorage.AccessoryReplication folder.")

local placeholderShop = ReplicatedStorage.Assets["Shop Placeholders"].ShopPlaceholder :: Model

local function GetActiveShopAtCFrame(cframe: CFrame): ActiveShop?
	return TableUtil.Find(activeShops, function(shop)
		return (shop.cframe.Position - cframe.Position).Magnitude < 5
	end)
end

local function ToNetworkShop(shop: ActiveShop): ShopEvents.LoadShopSettings
	local networkShop = {
		stands = shop.stands,
		outfitStands = shop.outfitStands,
		layoutId = shop.layout.id,
		storefrontId = shop.storefront.id,
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

	return {
		shop = networkShop,
		spawnMode = shop.mode,
	}
end

local function SaveShop(shop: ActiveShop)
	local owner = Players:GetPlayerByUserId(shop.owner)
	if not owner then
		warn("Tried to save shop for player not in-game")
		return
	end

	if shop.mode ~= "Player" then
		warn("Tried to save shop that was not spawned by the player. E.g. a sponsored/random shop.")
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
		if stand.item and validPositions[stand.roundedPosition] then
			table.insert(filteredStands, {
				assetId = stand.item.id,
				type = stand.item.type,
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
		storefrontId = shop.storefront.id,
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

local function PopulateLayoutStands(
	savedStands: { Types.Stand },
	standPositions: { [Vector3]: boolean }
): { Types.Stand }
	local savedStandMap: { [Vector3]: Types.Stand } = {}
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
				roundedPosition = position,
				item = nil,
			})
		end
	end

	return outputStands
end

local function PopulateLayoutOutfitStands(
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

-- If being replaced is true, then it wont unload on the client
local function UnloadShop(place: ActiveShop, beingReplaced: boolean)
	local index = table.find(activeShops, place)
	if index then
		table.remove(activeShops, index)
		if not beingReplaced then
			ShopEvents.LoadShop:FireAllClients(place.cframe)
		end
	else
		warn(debug.traceback("Tried to unload a place without it existing in the place table! Should never occur."))
	end
end

local function LoadShop(cframe: CFrame, shopDetails: Types.Shop, mode: Types.SpawnMode)
	local existingShop = TableUtil.Find(activeShops, function(shop)
		return (shop.cframe.Position - cframe.Position).Magnitude < 5
	end)

	if existingShop then
		UnloadShop(existingShop, true)
	end

	local layout = Layouts:GetLayout(shopDetails.layoutId)
	local storefront = Layouts:GetStorefront(shopDetails.storefrontId)

	-- Every physical part should have a registered stand
	-- This is necessary so the shop can accept stand updates for stands that don't yet have an item.
	local stands = PopulateLayoutStands(shopDetails.stands, layout.getValidStandPositions())
	local outfitStands = PopulateLayoutOutfitStands(shopDetails.outfitStands, layout.getValidOutfitStandPositions())

	local shop: ActiveShop = {
		stands = stands,
		outfitStands = outfitStands,
		layout = layout,
		storefront = storefront,
		cframe = cframe,
		owner = shopDetails.owner,
		playersPresent = {},
		mode = mode,
		GUID = shopDetails.GUID,
		shareCode = shopDetails.shareCode,
		name = shopDetails.name,
		primaryColor = shopDetails.primaryColor,
		accentColor = shopDetails.accentColor,
		texture = shopDetails.texture,
		lastUpdate = os.clock(),
		thumbId = shopDetails.thumbId,
		logoId = shopDetails.logoId,
	}

	table.insert(activeShops, shop)

	ShopEvents.LoadShop:FireAllClients(cframe, ToNetworkShop(shop))

	return shop
end

local function HandleCreatePlace(player: Player): string?
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
		storefrontId = Layouts:GetRandomStorefrontId(),
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

	return newShop.GUID
end

local function GetEditableShop(player: Player): ActiveShop?
	local shop = TableUtil.Find(activeShops, function(shop)
		return shop.mode == "Player" and shop.owner == player.UserId
	end)
	if not shop then
		return
	end

	return shop
end

local function HandleUpdateStand(player: Player, roundedPosition: Vector3, assetId: number?)
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

	if stand.item and stand.item.id == assetId then
		-- Asset did not change
		return
	end

	if assetId then
		local details = DataFetch.GetItemDetails(assetId):Await()
		if details and details.standType then
			stand.item = {
				id = assetId,
				type = details.standType,
			}
		else
			-- todo: notify player the item failed to fetch or something
		end
	else
		stand.item = nil
	end

	ShopEvents.LoadShop:FireAllClients(shop.cframe, ToNetworkShop(shop))
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

	ShopEvents.LoadShop:FireAllClients(shop.cframe, ToNetworkShop(shop))
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

	ShopEvents.LoadShop:FireAllClients(shop.cframe, ToNetworkShop(shop))
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

	ShopEvents.LoadShop:FireAllClients(shop.cframe, ToNetworkShop(shop))
	SaveShop(shop)
end

local function HandleUpdateShopStorefront(player: Player, layoutId: LayoutData.StorefrontId)
	local shop = GetEditableShop(player)
	if not shop then
		return
	end
	local newStorefront = Layouts:GetStorefront(layoutId)
	shop.storefront = newStorefront

	ShopEvents.LoadShop:FireAllClients(shop.cframe, ToNetworkShop(shop))
	SaveShop(shop)
end

local function HandleDeleteShop(player: Player, guid: string)
	local loadedShop = GetEditableShop(player)
	if loadedShop and loadedShop.GUID == guid then
		UnloadShop(loadedShop, false)
	end

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

local function HandleClaimShop(player: Player, shopCFrame: CFrame, guid: string)
	local data = DataService:ReadData(player):Await()
	if not data then
		return
	end

	local mallShop = MallCFrames.GetShop(shopCFrame)
	if not mallShop then
		warn("Tried to claim an invalid CFrame!")
		return
	end

	local shop = TableUtil.Find(data.shops, function(shop)
		return shop.GUID == guid
	end)
	if not shop then
		warn("Tried to claim a mall without a valid shop")
		return
	end

	local existingShopPosition = GetActiveShopAtCFrame(mallShop.cframe)
	if existingShopPosition then
		if existingShopPosition.owner ~= player.UserId then
			-- Tried to load at a position owned by someone else
			return
		end

		-- The player owns the shop at this position, so we can unload and replace it.
		UnloadShop(existingShopPosition, true)
	elseif not existingShopPosition then
		local playerOldShop = TableUtil.Find(activeShops, function(shop)
			return shop.owner == player.UserId
		end)

		if playerOldShop then
			-- Unload the player's old shop
			UnloadShop(playerOldShop, false)
		end
	end

	LoadShop(mallShop.cframe, Data.FromDataShop(shop, player.UserId), "Player")
end

local function PlayerAdded(player: Player)
	local loaded = LoadedService:GetLoadedFuture(player):Await()
	if not loaded then
		return
	end

	-- Replicate all active shops
	for i, shop in activeShops do
		ShopEvents.LoadShop:FireClient(player, shop.cframe, ToNetworkShop(shop))
	end
end

local function PlayerRemoving(player: Player)
	-- Unclaim their shop
	local claimedShop = TableUtil.Find(activeShops, function(shop)
		return shop.mode == "Player" and shop.owner == player.UserId
	end)
	if claimedShop then
		UnloadShop(claimedShop, false)
	end
end

local function SpawnSponsoredShops()
	task.spawn(function()
		local sponsoredShops = TableUtil.Filter(MallCFrames.shops, function(shop)
			return shop.type == "Sponsored"
		end)

		local codes = TableUtil.Shuffle(SponsoredShops)
		local randomShops = TableUtil.Shuffle(sponsoredShops)

		for _, code in codes do
			local details = DataService:ShopFromShareCode(code):Await()
			if not details then
				continue
			end

			local shop = table.remove(randomShops) -- pop
			if not shop then
				return
			end

			local existingShop = GetActiveShopAtCFrame(shop.cframe)
			if existingShop then
				UnloadShop(existingShop, true)
			end

			LoadShop(shop.cframe, details, "Server")
		end
	end)
end

local function CreateRandomShop(cframe: CFrame)
	return Future.new(function(): RandomShop?
		local nextShop = RandomFeed.GetNextShop():Await()
		if not nextShop then
			warn("Failed to load random shop!")
			return
		end

		local activeShop = LoadShop(cframe, nextShop, "Random")

		local randomShop: RandomShop = {
			activeShop = activeShop,
			cooldownTime = Config.RandomShopTimeout,
			enteredPlayers = {},
		}

		return randomShop
	end)
end

local function SetupRandomizedShops()
	return Future.new(function()
		local randomShops: { RandomShop } = {}

		for _, shop in MallCFrames.shops do
			if shop.type == "Randomized" then
				local newShop = CreateRandomShop(shop.cframe):Await()
				if newShop then
					table.insert(randomShops, newShop)
				end
			end
		end

		local shopSize = placeholderShop:GetExtentsSize()
		local frontAttachment = placeholderShop:FindFirstChild("FrontAttachment") :: BasePart
		local offset = frontAttachment.CFrame:ToObjectSpace(placeholderShop:GetPivot())

		RunService.Heartbeat:Connect(function(dt)
			for i, shop in randomShops do
				local playerInside = false

				for _, player in Players:GetPlayers() do
					local char = player.Character
					if Util.PointInBounds(char:GetPivot().Position, shop.activeShop.cframe * offset, shopSize) then
						playerInside = true
						break
					end
				end

				if not playerInside then
					if shop.cooldownTime == Config.RandomShopTimeout then
						ShopEvents.SetRandomShopTimer:FireAllClients(shop.activeShop.cframe, false)
					end
					shop.cooldownTime -= dt
				else
					if shop.cooldownTime ~= Config.RandomShopTimeout then
						ShopEvents.SetRandomShopTimer:FireAllClients(shop.activeShop.cframe, true)
					end
					shop.cooldownTime = Config.RandomShopTimeout
				end

				if shop.cooldownTime <= 0 then
					randomShops[i] = nil
					CreateRandomShop(shop.activeShop.cframe):After(function(newShop)
						if newShop then
							randomShops[i] = newShop
						else
							warn("Failed to load a new random shop!")
						end
					end)
				end
			end
		end)
	end)
end

function ShopService:ShopFromPlayerAndOwner(player: Player, owner: number): ActiveShop?
	local char = player.Character
	if not char then
		return
	end

	local charPos = char:GetPivot().Position

	local ownerShops = TableUtil.Filter(activeShops, function(shop)
		return shop.owner == owner
	end)

	local closestShop
	local closestDistance = math.huge
	for _, shop in ownerShops do
		local distance = (shop.cframe.Position - charPos).Magnitude
		if distance < closestDistance then
			closestShop = shop
			closestDistance = distance
		end
	end

	return closestShop
end

local passRateLimit = Util.RateLimit(5, 30)
local function HandleGetOwnerPasses(player: Player, owner: number): { Types.Pass }
	local ownerShop = TableUtil.Find(activeShops, function(shop)
		return shop.owner == owner
	end)

	if not ownerShop then
		warn("Fetching passes for an unloaded shop")
		-- server does not know about dynamic shops
		-- spamming can put pressure on proxy server, so rate limit
		if not passRateLimit(player) then
			return {}
		end
	end

	return PlayerSales.GetPasses(owner):Await()
end

local function Initialize()
	ShopEvents.CreateShop:SetCallback(HandleCreatePlace)
	ShopEvents.DeleteShop:SetServerListener(HandleDeleteShop)

	ShopEvents.ClaimShop:SetServerListener(HandleClaimShop)

	ShopEvents.UpdateStand:SetServerListener(HandleUpdateStand)
	ShopEvents.UpdateOutfitStand:SetServerListener(HandleUpdateOutfitStand)
	ShopEvents.UpdateSettings:SetServerListener(HandleUpdateShopSettings)
	ShopEvents.UpdateLayout:SetServerListener(function(player, id)
		HandleUpdateShopLayout(player, id :: LayoutData.LayoutId)
	end)
	ShopEvents.UpdateStorefront:SetServerListener(function(player, id)
		HandleUpdateShopStorefront(player, id :: LayoutData.StorefrontId)
	end)
	ShopEvents.GetOwnerPasses:SetCallback(HandleGetOwnerPasses)

	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)

	SpawnSponsoredShops()
	SetupRandomizedShops()
end

Initialize()

return ShopService

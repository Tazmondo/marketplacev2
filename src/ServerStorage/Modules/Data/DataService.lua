local DataService = {}

local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataEvents = require(ReplicatedStorage.Events.DataEvents)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local ProfileService = require(script.Parent.ProfileService)
local SharedIncremental = require(script.Parent.SharedIncremental)

DataService.PlayerRemoving = Signal()

local STOREPREFIX = "PlayerData8"
local PLAYERPREFIX = "Player_"
local PLAYERCACHETIMEOUT = 60 * 15
local SHARECODECACHEEXPIRATION = 60 * 60 * 24 * 8 -- 8 days

local ProfileStore =
	assert(ProfileService.GetProfileStore(STOREPREFIX, Data.dataTemplate), "Failed to load profile store")

local ShareCodeStore = DataStoreService:GetDataStore("ShareCodes")
local ShareCodeMemoryStore = MemoryStoreService:GetSortedMap("ShareCodes")

type Profile = typeof(assert(ProfileStore:LoadProfileAsync(...)))
type CachedProfile = {
	cachedTime: number,
	data: Future.Future<Data.Data?>,
}

type ShareCodeUpdate = {
	type: "ShareCode",
	code: number,
	player: number,
	guid: string,
}

type GlobalUpdateData = ShareCodeUpdate

local profiles: { [Player]: Profile } = {}
local cachedShops: { [number]: CachedProfile? } = {}
local shareCodeCache: { [number]: { owner: number, guid: string } | false } = {}

local function GetKey(userId: number)
	return PLAYERPREFIX .. userId
end

local function UpdateShareCodeCache(code: number, owner: number, guid: string)
	return Future.new(function()
		local tries = 0
		while true do
			local success = pcall(function()
				ShareCodeMemoryStore:SetAsync(tostring(code), {
					owner = owner,
					guid = guid,
				}, SHARECODECACHEEXPIRATION)
			end)
			if success then
				return
			end

			tries += 1
			task.wait(2 ^ tries)
		end
	end)
end

local function UpdateShareCode(data: Data.Data, code: number, owner: number, guid: string)
	local shop = TableUtil.Find(data.shops, function(shop)
		return shop.GUID == guid
	end)

	if not shop then
		return
	end

	shop.shareCode = code
end

local function ProcessGlobalUpdate(profile: Profile, update: GlobalUpdateData): boolean
	if update.type == "ShareCode" then
		UpdateShareCode(profile.Data, update.code, update.player, update.guid)
	end

	return false
end

local function UpdateLeaderstats(player: Player, data: Data.Data)
	local stats = player:FindFirstChild("leaderstats") :: Folder?
	if not stats then
		local newStats = Instance.new("Folder")
		newStats.Name = "leaderstats"
		newStats.Parent = player

		stats = newStats
	end
	assert(stats)

	local purchases = stats:FindFirstChild("Purchases") :: IntValue?
	if not purchases then
		local newPurchases = Instance.new("IntValue")
		newPurchases.Name = "Purchases"
		newPurchases.Parent = stats

		purchases = newPurchases
	end
	assert(purchases)

	purchases.Value = data.purchases
end

local function PlayerAdded(player: Player)
	local profile = ProfileStore:LoadProfileAsync(GetKey(player.UserId))
	if profile ~= nil then
		profile:AddUserId(player.UserId)

		Data.Migrate(profile.Data, player.UserId)

		DataEvents.ReplicateData:FireClient(player, profile.Data)

		profile:ListenToRelease(function()
			profiles[player] = nil
			player:Kick()
			return
		end)

		for _, update in profile.GlobalUpdates:GetActiveUpdates() do
			profile.GlobalUpdates:LockActiveUpdate(update[1])
		end

		for _, update in profile.GlobalUpdates:GetLockedUpdates() do
			local id = update[1]
			local data = update[2]

			ProcessGlobalUpdate(profile, data)
			profile.GlobalUpdates:ClearLockedUpdate(id)
		end

		profile.GlobalUpdates:ListenToNewActiveUpdate(function(updateId, data: GlobalUpdateData)
			profile.GlobalUpdates:LockActiveUpdate(updateId)
		end)

		profile.GlobalUpdates:ListenToNewLockedUpdate(function(updateId, data: GlobalUpdateData)
			ProcessGlobalUpdate(profile, data)

			profile.GlobalUpdates:ClearLockedUpdate(updateId)
		end)

		if player.Parent == Players then
			UpdateLeaderstats(player, profile.Data)
			profiles[player] = profile
		else
			profile:Release()
		end
	else
		player:Kick()
	end
end

function PlayerRemoving(player: Player)
	local profile = profiles[player]
	DataService.PlayerRemoving:Fire(player, if profile then profile.Data :: Data.Data else nil)

	if profile ~= nil then
		profile.Data.firstTime = false

		-- Might not need to deep copy here, but doing it just to be safe.
		cachedShops[player.UserId] = {
			cachedTime = tick(),
			data = Future.new(function(): Data.Data?
				return TableUtil.Copy(profile.Data, true)
			end),
		}
		profile:Release()
	end
end

function FetchOfflineData(userId: number)
	local dataFuture = Future.new(function(userId): Data.Data?
		local profile = ProfileStore:ViewProfileAsync(GetKey(userId))
		if profile then
			Data.Migrate(profile.Data, userId)

			-- Apply pending global updates when viewing the profile.
			-- 	This allows sharecodes to be up to date when viewing a profile even if the owner has not logged on.
			for _, update in profile.GlobalUpdates:GetActiveUpdates() do
				local data = update[2]

				ProcessGlobalUpdate(profile, data)
			end
			for _, update in profile.GlobalUpdates:GetLockedUpdates() do
				local data = update[2]

				ProcessGlobalUpdate(profile, data)
			end

			return profile.Data
		end

		return nil
	end, userId)

	cachedShops[userId] = {
		cachedTime = tick(),
		data = dataFuture,
	}

	return dataFuture
end

function DataService:ReadOfflineData(userId: number, bypassCache: boolean?)
	return Future.new(function(): Data.Data?
		local player = Players:GetPlayerByUserId(userId)

		-- Since they may not have loaded yet
		if player and profiles[player] then
			return profiles[player].Data
		end

		local cache = cachedShops[userId]
		if cache and tick() - cache.cachedTime <= PLAYERCACHETIMEOUT and not bypassCache then
			return cache.data:Await()
		end

		local data = FetchOfflineData(userId):Await()
		return data
	end)
end

function DataService:ReadData(player: Player)
	return Future.new(function()
		while player.Parent ~= nil and not profiles[player] do
			task.wait()
		end

		local profile = profiles[player]
		if profile then
			return profile.Data :: Data.Data?
		else
			return nil
		end
	end)
end

function DataService:IsDataLoaded(player: Player)
	return profiles[player] ~= nil
end

function DataService:WriteData(player: Player, mutate: (Data.Data) -> ())
	return Future.new(function()
		local data = DataService:ReadData(player):Await()
		if not data then
			return
		end

		-- We need to detect yielding because it could result in data not being replicated to the client
		-- As it would be updated after the event is sent

		local yielded = true
		task.spawn(function()
			mutate(data)
			yielded = false
		end)

		if yielded then
			warn(debug.traceback("Data transform function yielded!"))
		end

		UpdateLeaderstats(player, data)
		DataEvents.ReplicateData:FireClient(player, data)
	end)
end

local shareCodeRateLimit = Util.RateLimit(1, 6)
local function GenerateNextShareCode(player: Player, targetId: number, guid: string)
	return Future.new(function(player: Player): number?
		local data = DataService:ReadOfflineData(targetId):Await()
		if not data then
			return
		end

		local shop = TableUtil.Find(data.shops, function(shop)
			return shop.GUID == guid
		end)
		if not shop then
			return
		end

		if shop.shareCode then
			return shop.shareCode
		end

		-- Don't need to rate limit before this point, as the offline data gets cached.
		if not shareCodeRateLimit(player) then
			return nil
		end

		local nextNumber = SharedIncremental:FetchNext():Await()
		if not nextNumber then
			return
		end

		local targetPlayer = Players:GetPlayerByUserId(targetId)
		if targetPlayer and DataService:IsDataLoaded(player) then
			DataService:WriteData(player, function(data)
				UpdateShareCode(data, nextNumber, targetId, guid)
			end)
		else
			ProfileStore:GlobalUpdateProfileAsync(GetKey(targetId), function(globalUpdates)
				local data: GlobalUpdateData = {
					type = "ShareCode",
					code = nextNumber,
					player = targetId,
					guid = guid,
				}

				globalUpdates:AddActiveUpdate(data)
			end)
		end

		task.spawn(function()
			local tries = 0
			repeat
				local success = pcall(function()
					ShareCodeStore:SetAsync(tostring(nextNumber), {
						owner = targetId,
						guid = guid,
					})
				end)
				tries += 1
				task.wait(2 ^ tries)
			until success == true
		end)

		UpdateShareCodeCache(nextNumber, targetId, guid)

		return nextNumber
	end, player)
end

local function GetShareCodeData(code: number)
	return Future.new(function(): (number?, string?)
		local localCached = shareCodeCache[code]
		if localCached ~= nil then
			if typeof(localCached) == "boolean" then
				return nil
			end
			return localCached.owner, localCached.guid
		end

		local owner: number
		local guid: string

		local cacheSuccess, cacheData = pcall(function()
			return ShareCodeMemoryStore:GetAsync(tostring(code))
		end)

		if cacheSuccess and cacheData then
			owner = cacheData.owner
			guid = cacheData.guid
		else
			local success, codeData = pcall(function()
				return ShareCodeStore:GetAsync(tostring(code))
			end)

			if not success or not codeData then
				shareCodeCache[code] = false
				return nil
			end

			owner = codeData.owner
			guid = codeData.guid
		end

		-- Always update the cache to reset the expiry date.
		UpdateShareCodeCache(code, owner, guid)

		shareCodeCache[code] = { owner = owner, guid = guid }

		return owner, guid
	end)
end

local function ShopFromShareCode(shareCode: number)
	return Future.new(function(shareCode): (Data.Shop?, number?)
		local owner, guid = GetShareCodeData(shareCode):Await()
		if not owner or not guid then
			return
		end

		local ownerData = DataService:ReadOfflineData(owner):Await()
		if not ownerData then
			return
		end

		local shop = TableUtil.Find(ownerData.shops, function(shop)
			return shop.GUID == guid
		end)

		return shop, owner
	end, shareCode)
end

function DataService:ShopFromShareCode(shareCode: number)
	return Future.new(function(shareCode: number): Types.Shop?
		local shop, owner = ShopFromShareCode(shareCode):Await()
		if not shop or not owner then
			return
		end

		return Data.FromDataShop(shop, owner)
	end, shareCode)
end

local function HandleGetShopDetails(player: Player, shareCode: number): Types.NetworkShopDetails?
	local shop, owner = ShopFromShareCode(shareCode):Await()
	if not shop or not owner then
		return
	end

	return {
		owner = owner,
		name = shop.name,
		thumbId = shop.thumbId,
		logoId = shop.logoId,
		primaryColor = Color3.fromHex(shop.primaryColor),
		accentColor = Color3.fromHex(shop.accentColor),
		GUID = shop.GUID,
		shareCode = shop.shareCode,
	}
end

local function HandleGenerateShareCode(player: Player, guid: string): number?
	local data = DataService:ReadData(player):Await()
	if not data then
		return
	end

	local shop = TableUtil.Find(data.shops, function(shop)
		return shop.GUID == guid
	end)
	if not shop or shop.shareCode ~= nil then
		return
	end
	local code = GenerateNextShareCode(player, player.UserId, guid):Await()
	return code
end

local function HandleGetShop(player: Player, shareCode: number): Types.Shop?
	local shop, owner = ShopFromShareCode(shareCode):Await()
	if not shop or not owner then
		return
	end

	return Data.FromDataShop(shop, owner)
end

local function HandleNewOutfit(player: Player, name: string, serDescription: Types.SerializedDescription)
	local newOutfit: Data.Outfit = {
		name = name,
		description = serDescription,
	}
	DataService:WriteData(player, function(data)
		table.insert(data.outfits, newOutfit)
	end)
end

local function HandleDeleteOutfit(player: Player, name: string, serDescription: Types.SerializedDescription)
	DataService:WriteData(player, function(data)
		local _, outfitIndex = TableUtil.Find(data.outfits, function(outfit)
			return outfit.name == name and HumanoidDescription.Equal(outfit.description, serDescription)
		end)

		if outfitIndex then
			table.remove(data.outfits, outfitIndex)
		end
	end)
end

function DataService:Initialize()
	Players.PlayerAdded:Connect(PlayerAdded)
	for i, player in Players:GetPlayers() do
		task.spawn(PlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(PlayerRemoving)

	DataEvents.CreateOutfit:SetServerListener(HandleNewOutfit)
	DataEvents.DeleteOutfit:SetServerListener(HandleDeleteOutfit)
	DataEvents.GetShopDetails:SetCallback(HandleGetShopDetails)
	DataEvents.GetShop:SetCallback(HandleGetShop)
	DataEvents.GenerateShareCode:SetCallback(HandleGenerateShareCode)
end

DataService:Initialize()

return DataService

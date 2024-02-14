local DataService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalUpdates = require(script.Parent.GlobalUpdates)
local DataEvents = require(ReplicatedStorage.Events.DataEvents)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local ProfileService = require(script.Parent.ProfileService)
local ShareCodes = require(script.Parent.ShareCodes)
local SharedIncremental = require(script.Parent.SharedIncremental)

DataService.PlayerRemoving = Signal()

local STOREPREFIX = "PlayerData9"
local PLAYERPREFIX = "Player_"
local PLAYERCACHETIMEOUT = 60 * 15

local ProfileStore =
	assert(ProfileService.GetProfileStore(STOREPREFIX, Data.dataTemplate), "Failed to load profile store")

type Profile = typeof(assert(ProfileStore:LoadProfileAsync(...)))
type CachedProfile = {
	cachedTime: number,
	data: Future.Future<Data.Data?>,
}

local profiles: { [Player]: Profile } = {}
local cachedProfiles: { [number]: CachedProfile? } = {}

local function GetKey(userId: number)
	return PLAYERPREFIX .. userId
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

	local earned = stats:FindFirstChild("Raised") :: IntValue?
	if not earned then
		local newEarned = Instance.new("IntValue")
		newEarned.Name = "Raised"
		newEarned.Parent = stats

		earned = newEarned
	end
	assert(earned)

	purchases.Value = data.purchases
	earned.Value = data.donationRobux
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

		-- note that locking an active update does not immediately put it in the locked updates
		-- it marks it as "pending" , and it is locked on the next autosave
		for _, update in profile.GlobalUpdates:GetLockedUpdates() do
			local id = update[1]
			local data = update[2]
			GlobalUpdates.ProcessGlobalUpdate(profile.Data, data)
			profile.GlobalUpdates:ClearLockedUpdate(id)
		end

		profile.GlobalUpdates:ListenToNewActiveUpdate(function(updateId, data: GlobalUpdates.Update)
			profile.GlobalUpdates:LockActiveUpdate(updateId)
		end)

		profile.GlobalUpdates:ListenToNewLockedUpdate(function(updateId, data: GlobalUpdates.Update)
			local success = GlobalUpdates.ProcessGlobalUpdate(profile.Data, data)

			-- we may receive a globalupdate from a new server, which this old server does not know how to deal with
			-- in this case we don't want to clear the update
			if success then
				-- processglobalupdate does not notify of updates, as it may run before the profile has loaded
				-- so we manually update here, which will update leaderstats and replicate to client
				DataService:WriteData(player, function() end)

				profile.GlobalUpdates:ClearLockedUpdate(updateId)
			end
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
		cachedProfiles[player.UserId] = {
			cachedTime = tick(),
			data = Future.new(function(): Data.Data?
				return TableUtil.Copy(profile.Data, true)
			end),
		}
		profile:Release()
	end
end

local function IsPlayerCached(id: number)
	local player = Players:GetPlayerByUserId(id)
	if player and profiles[player] then
		return true
	end

	if cachedProfiles[id] then
		return true
	end

	return false
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

				GlobalUpdates.ProcessGlobalUpdate(profile.Data, data)
			end
			for _, update in profile.GlobalUpdates:GetLockedUpdates() do
				local data = update[2]

				GlobalUpdates.ProcessGlobalUpdate(profile.Data, data)
			end

			return profile.Data
		end

		return nil
	end, userId)

	cachedProfiles[userId] = {
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

		local cache = cachedProfiles[userId]
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
	return Future.new(function(): number?
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
		if targetPlayer and DataService:IsDataLoaded(targetPlayer) then
			DataService:WriteData(targetPlayer, function(data)
				ShareCodes.UpdatePlayerData(data, nextNumber, targetId, guid)
			end)
		else
			ProfileStore:GlobalUpdateProfileAsync(GetKey(targetId), function(globalUpdates)
				GlobalUpdates.CreateShareCodeUpdate(globalUpdates, targetId, nextNumber, guid)
			end)
		end

		ShareCodes.CreateShareCode(nextNumber, targetId, guid)

		return nextNumber
	end)
end

local function ShopFromShareCode(shareCode: number)
	return Future.new(function(shareCode): (Data.Shop?, number?)
		local owner, guid = ShareCodes.FetchWithCode(shareCode):Await()
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

local function HandleFetchEarned(player: Player, id: number): number?
	if not IsPlayerCached(id) then
		-- if the player is not cached then don't allow the client to request
		-- this stops exploiters from spamming this endpoint and using up the request limit
		return nil
	end

	local data = DataService:ReadOfflineData(id):Await()
	if data then
		return data.donationRobux
	else
		return nil
	end
end

function DataService:SendEarnedUpdate(owner: number, amount: number, count: number)
	return Future.new(function(): boolean
		local success, updates = pcall(function()
			return ProfileStore:GlobalUpdateProfileAsync(GetKey(owner), function(globalUpdates)
				GlobalUpdates.CreateEarnedUpdate(globalUpdates, amount, count)
			end)
		end)

		return success and updates ~= nil
	end)
end

function DataService:SendDonationUpdate(owner: number, amount: number, count: number)
	return Future.new(function(): boolean
		local success, updates = pcall(function()
			return ProfileStore:GlobalUpdateProfileAsync(GetKey(owner), function(globalUpdates)
				GlobalUpdates.CreateDonatedUpdate(globalUpdates, amount, count)
			end)
		end)

		return success and updates ~= nil
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
	DataEvents.FetchEarned:SetCallback(HandleFetchEarned)
end

DataService:Initialize()

return DataService

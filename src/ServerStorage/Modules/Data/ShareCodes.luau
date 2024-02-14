local ShareCodes = {}

local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Future = require(ReplicatedStorage.Packages.Future)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local ShareCodeStore = DataStoreService:GetDataStore("ShareCodes")
local ShareCodeMemoryStore = MemoryStoreService:GetSortedMap("ShareCodes")

local shareCodeCache: { [number]: { owner: number, guid: string } | false } = {}

local SHARECODECACHEEXPIRATION = 60 * 60 * 24 * 8 -- 8 days

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

function ShareCodes.UpdatePlayerData(data: Data.Data, code: number, owner: number, guid: string)
	local shop = TableUtil.Find(data.shops, function(shop)
		return shop.GUID == guid
	end)

	if not shop then
		return
	end

	shop.shareCode = code
end

function ShareCodes.CreateShareCode(code: number, owner: number, guid: string)
	task.spawn(function()
		local tries = 0
		repeat
			local success = pcall(function()
				ShareCodeStore:SetAsync(tostring(code), {
					owner = owner,
					guid = guid,
				})
			end)
			tries += 1
			task.wait(2 ^ tries)
		until success == true
	end)

	UpdateShareCodeCache(code, owner, guid)
end

function ShareCodes.FetchWithCode(code: number)
	return Future.new(function(code: number): (number?, string?)
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
	end, code)
end

return ShareCodes

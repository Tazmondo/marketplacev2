local SharedIncremental = {}

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)

local datastore = DataStoreService:GetDataStore("Shared_Increment")
local key = "Shop_Increment"

local function _FetchNext(key: string)
	local tryCount = 0
	local newKey: number?

	while not newKey and tryCount < 5 do
		if tryCount > 0 then
			task.wait(2 ^ tryCount) -- if datastore requests are failing, then wait progressively longer
		end
		tryCount += 1

		local success, value = pcall(function()
			return datastore:UpdateAsync(key, function(oldKey: number?): number
				if not oldKey then
					return 1
				else
					return oldKey + 1
				end
			end)
		end)

		if success then
			newKey = value
		end
	end

	return newKey
end

-- We only want one concurrent fetch to be running
local DebounceFetch = Util.CreateYieldDebounce(_FetchNext)

function SharedIncremental:FetchNext()
	return Future.new(function(): number?
		return DebounceFetch(key)
	end)
end

return SharedIncremental

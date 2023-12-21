local RandomPlayerService = {}

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Future = require(ReplicatedStorage.Packages.Future)

local STOREKEY = "FullPlayerList"
local PLAYERLISTKEY = "BasicPlayerList"

-- Actual limit is something like 333333, but just to be safe doing less.
-- Also need to contend with the experience wide 25MB/min read and 4MB/min write limit.
local MAXPLAYERS = 100000

-- Store as lists because they take up less space in datastore, and allow for random indexing, but convert to maps for O(1) look-up times
-- Comes at a cost to server memory and some processing time but overall it saves more time as the indexing saves a lot of iterations.
type Data = {
	list: { number },
	map: { [number]: true },
	length: number,
}

local PlayerStore = DataStoreService:GetDataStore(STOREKEY)

local savedData: Data? = nil
local tempData: Data = {
	list = {},
	map = {},
	length = 0,
}
local random = Random.new()
local invalidPlayers: { number } = {}

function GetSavedData()
	return Future.new(function()
		if savedData then
			return savedData
		end

		local warnThread = task.delay(10, warn, "Took too long to retrieve saved player list!")

		while savedData == nil do
			task.wait()
		end
		task.cancel(warnThread)

		assert(savedData)
		return savedData
	end)
end

-- This is optional because it is a valid case for there to be no players in the datastore.
function RandomPlayerService:GetPlayer()
	return Future.new(function()
		local data = GetSavedData():Await()
		local totalLimit = data.length + tempData.length

		local randomIndex = random:NextInteger(1, totalLimit)

		local player

		if randomIndex <= data.length then
			-- Index falls in the range of the saved data

			player = data.list[randomIndex]
		else
			-- Index falls in range of the temporary data

			local correctedIndex = randomIndex - data.length
			player = tempData.list[correctedIndex]
		end

		return player or nil -- so it's inferred as number
	end)
end

function RandomPlayerService:AddPlayer(userId: number)
	local data = GetSavedData():Await()

	if data.map[userId] or tempData.map[userId] then
		return
	end

	tempData.map[userId] = true
	table.insert(tempData.list, userId)
	tempData.length += 1
end

function GameClosing()
	-- No need to run this relatively expensive operation when working in studio
	if RunService:IsStudio() then
		return
	end

	PlayerStore:UpdateAsync(PLAYERLISTKEY, function(list: { number } | nil)
		list = list or {}
		assert(list)

		local map = {}
		for i, userId in list do
			map[userId] = true
		end

		for i, userId in tempData.list do
			if not map[userId] then
				table.insert(list, userId)
			end
		end

		return list
	end)
end

function RandomPlayerService:Initialize()
	game:BindToClose(GameClosing)

	Players.PlayerAdded:Connect(function(player)
		RandomPlayerService:AddPlayer(player.UserId)
	end)
	for i, player in Players:GetPlayers() do
		RandomPlayerService:AddPlayer(player.UserId)
	end

	task.spawn(function()
		local savedList = PlayerStore:GetAsync(PLAYERLISTKEY) or {}
		local savedMap: { [number]: true } = {}
		local length = #savedList

		for i, userId in savedList do
			savedMap[userId] = true
		end

		savedData = {
			list = savedList,
			map = savedMap,
			length = length,
		}

		print(`Loaded random player list. Length: {length}`)
		print(RandomPlayerService:GetPlayer():Await())
	end)
end

RandomPlayerService:Initialize()

return RandomPlayerService
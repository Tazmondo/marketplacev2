local RandomPlayerService = {}

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Data = require(ReplicatedStorage.Modules.Shared.Data)
local DataService = require(ServerStorage.Modules.DataService.DataService)
local RandomValid = require(ServerStorage.Modules.Feed.RandomValid)
local Future = require(ReplicatedStorage.Packages.Future)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local STOREKEY = "FullPlayerList"
local PLAYERLISTKEY = "BasicPlayerList"

-- Actual limit is something like 333333, but just to be safe doing less.
-- Also need to contend with the experience wide 25MB/min read and 4MB/min write limit.
local MAXPLAYERS = 330000

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
local pendingRemoval: { [number]: true? } = {}

local random = Random.new()

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

--- This is optional because it is a valid case for there to be no players in the datastore.
function RandomPlayerService:GetPlayer(ignoreSet: { [number]: true? }?)
	return Future.new(function(): number?
		-- # should work since the keys are numerical but i don't want to risk it
		local ignoreLength = 0
		if ignoreSet then
			for _, _ in ignoreSet do
				ignoreLength += 1
			end
		end

		local data = GetSavedData():Await()

		local totalLimit = data.length + tempData.length

		if ignoreLength >= totalLimit then
			return nil
		end

		local filteredData
		local filteredTempData

		if ignoreSet then
			filteredData = {}
			filteredTempData = {}

			for i, id in data.list do
				if not ignoreSet[id] then
					table.insert(filteredData, id)
				end
			end

			for i, id in tempData.list do
				if not ignoreSet[id] then
					table.insert(filteredTempData, id)
				end
			end
		else
			filteredData = data.list
			filteredTempData = tempData.list
		end

		local totalFilteredLimit = #filteredData + #filteredTempData
		if totalFilteredLimit == 0 then
			return nil
		end

		local randomIndex = random:NextInteger(1, totalFilteredLimit)

		local player

		if randomIndex <= data.length then
			-- Index falls in the range of the saved data

			player = filteredData[randomIndex]
		else
			-- Index falls in range of the temporary data

			local correctedIndex = randomIndex - data.length
			player = filteredTempData[correctedIndex]
		end

		return player
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

function RandomPlayerService:RemovePlayer(userId: number)
	pendingRemoval[userId] = true
end

function GameClosing()
	if #Players:GetPlayers() > 0 then
		-- This ideally should never show up in the error log
		warn("Bindtoclose called before all players left")
	end

	-- Make sure all players have left before saving.
	-- Might not be necessary but doesn't hurt to make sure.
	for i, player in Players:GetPlayers() do
		player:Kick("Shutting Down")
	end
	while #Players:GetPlayers() > 0 do
		task.wait()
	end

	-- No need to run this relatively expensive operation when working in studio
	-- if RunService:IsStudio() then
	-- 	return
	-- end

	PlayerStore:UpdateAsync(PLAYERLISTKEY, function(list: { number } | nil)
		list = list or {}
		assert(list)

		local map = {}
		for i, userId in list do
			if pendingRemoval[userId] then
				TableUtil.SwapRemove(list, i)
				map[list[i]] = true -- Since the swapped value won't get iterated over we add it here.
			else
				map[userId] = true
			end
		end

		for i, userId in tempData.list do
			if not map[userId] then
				table.insert(list, userId)
			end
		end

		return list
	end)
end

function LoadData()
	return Future.new(function()
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
	end)
end

function PlayerAdded(player: Player)
	local data = DataService:ReadData(player):Await()
	if data and RandomValid.AnyValid(data.showcases) then
		RandomPlayerService:AddPlayer(player.UserId)
	end
end

function PlayerRemoving(player: Player, data: Data.Data?)
	if data and RandomValid.AnyValid(data.showcases) then
		RandomPlayerService:AddPlayer(player.UserId)
	end
end

function RandomPlayerService:Initialize()
	game:BindToClose(function()
		-- Deferring just in case, i want this function to definitely run last.
		task.defer(GameClosing)
	end)

	Players.PlayerAdded:Connect(PlayerAdded)
	for i, player in Players:GetPlayers() do
		PlayerAdded(player)
	end
	DataService.PlayerRemoving:Connect(PlayerRemoving)

	LoadData()
end

RandomPlayerService:Initialize()

return RandomPlayerService

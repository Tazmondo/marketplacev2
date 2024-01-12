local DataController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataEvents = require(ReplicatedStorage.Events.DataEvents)
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)

local data: Data.Data?

DataController.Updated = Signal()

function HandleReplicateData(incomingData: Data.Data)
	data = incomingData
	DataController.Updated:Fire(incomingData)
end

function DataController:GetData()
	return Future.new(function()
		if data == nil then
			return DataController.Updated:Wait()
		end

		return assert(data)
	end)
end

function DataController:UnwrapData()
	return data
end

function DataController:Initialize()
	DataEvents.ReplicateData:SetClientListener(HandleReplicateData)
end

DataController:Initialize()

return DataController

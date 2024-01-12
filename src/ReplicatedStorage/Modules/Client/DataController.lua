local DataController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)

local ReplicateDataEvent = require(ReplicatedStorage.Events.Data.ReplicateDataEvent):Client()

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
	ReplicateDataEvent:On(HandleReplicateData)
end

DataController:Initialize()

return DataController

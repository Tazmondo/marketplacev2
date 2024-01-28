local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ReplicatedStorage.Modules.Shared.Data)
local HumanoidDescription = require(ReplicatedStorage.Modules.Shared.HumanoidDescription)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

return {
	ReplicateData = Red.SharedEvent("Data_ReplicateData", function(data)
		return data :: Data.Data
	end),

	CreateOutfit = Red.SharedEvent("Data_CreateOutfit", function(name, serDescription)
		return Guard.String(name), HumanoidDescription.Guard(serDescription)
	end),

	DeleteOutfit = Red.SharedEvent("Data_DeleteOutfit", function(name, serDescription)
		return Guard.String(name), HumanoidDescription.Guard(serDescription)
	end),

	GetShopDetails = Red.Function("Data_ShopDetails", function(shareCode)
		return Guard.Number(shareCode)
	end, function(details)
		return details :: Types.NetworkShopDetails?
	end),

	GetShop = Red.Function("Data_FullShop", function(shareCode)
		return Guard.Number(shareCode)
	end, function(shop)
		return shop :: Types.Shop?
	end),

	GenerateShareCode = Red.Function("GenerateShareCode", function(guid)
		return Guard.String(guid)
	end, function(code)
		return Guard.Optional(Guard.Number)(code)
	end),
}

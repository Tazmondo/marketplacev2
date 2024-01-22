local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Red = require(ReplicatedStorage.Packages.Red)
return Red.Event("Shop_LoadShop", function(shop)
	return shop :: Types.NetworkShop
end)

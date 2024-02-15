local ServerStorage = game:GetService("ServerStorage")

local DataService = require(ServerStorage.Modules.Data.DataService)

return function(context, amount: number, targets: { Player })
	for _, player in targets do
		DataService:WriteData(player, function(data)
			data.shopbux += amount
			data.totalShopbux += amount
		end)
	end
end

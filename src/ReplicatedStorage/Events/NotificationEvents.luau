local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)
return {
	Donated = Red.SharedEvent("Notif_Donate", function(robux, receiver)
		return Guard.Number(robux), Guard.Number(receiver)
	end),

	ReceiveDonation = Red.SharedEvent("Notif_ReceiveDonate", function(robux, giver)
		return Guard.Number(robux), Guard.Number(giver)
	end),

	ReceiveSale = Red.SharedEvent("Notif_Sale", function(robux, buyer)
		return Guard.Number(robux), Guard.Number(buyer)
	end),

	EarnedShopbux = Red.SharedEvent("Notif_EarnShopbux", function(shopbux)
		return Guard.Number(shopbux)
	end),
}

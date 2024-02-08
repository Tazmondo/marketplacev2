local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)
return {
	Raised = Red.SharedEvent("Notify_Raised", function(amount, owner)
		return Guard.Number(amount), Guard.Number(owner)
	end),

	Earned = Red.SharedEvent("Notify_Earned", function(amount)
		return Guard.Number(amount)
	end),
}

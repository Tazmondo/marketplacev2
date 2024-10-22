--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loaded = require(ReplicatedStorage.Modules.Client.Loaded)
local Spawn = require(ReplicatedStorage.Packages.Spawn)

local Client = ReplicatedStorage.Modules.Client

print("Beginning loading.")

local scripts = Client:GetDescendants()
for i, moduleScript in ipairs(scripts) do
	if not moduleScript:IsA("ModuleScript") then
		continue
	end
	local yielded = true
	local success
	local message

	Spawn(function()
		success, message = pcall(function()
			require(moduleScript)
		end)

		yielded = false
	end)

	if success == false then
		error(`{moduleScript:GetFullName()}: {message}`)
	end

	if yielded then
		warn("Yielded while requiring" .. moduleScript:GetFullName())
	end
end

print("Finished loading, firing server.")

Loaded:RegisterLoaded()

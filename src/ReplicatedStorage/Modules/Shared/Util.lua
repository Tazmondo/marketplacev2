local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Base64 = require(ReplicatedStorage.Packages.Base64)
local Types = require(script.Parent.Types)
local Util = {}

function Util.NumberWithCommas(number: number)
	local numString = tostring(number)
	local newString = ""
	local offset = 3 - (#numString % 3)
	local index = 1

	while index <= #numString do
		if index ~= 1 and (index + offset) % 3 == 0 then
			newString ..= ","
		end

		newString ..= numString:sub(index, index)
		index += 1
	end

	return newString
end

function Util.TruncateString(string: string, maxLength: number)
	maxLength = math.max(3, maxLength)
	if #string <= maxLength then
		return string
	else
		return `{string:sub(1, maxLength - 2)}...`
	end
end

function Util.LimitString(string: string, maxLength: number)
	return string:sub(1, maxLength)
end

function Util.RoundedVector(vector: Vector3)
	return Vector3.new(math.round(vector.X), math.round(vector.Y), math.round(vector.Z))
end

function Util.PrettyPrint(table: { [any]: any })
	local out = "{\n"
	for k, v in table do
		out ..= `\t {k}: {v}\n`
	end
	out ..= "}"
	print(out)
end

function Util.GenerateDeeplink(ownerId: number, GUID: string)
	local data: Types.LaunchData = {
		ownerId = ownerId,
		GUID = GUID,
	}
	local json = HttpService:JSONEncode(data)
	local b64 = Base64.encode(json)

	return `https://www.roblox.com/games/start?placeId={game.PlaceId}&launchData={b64}`
end

return Util

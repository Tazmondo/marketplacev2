local alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local lookupToByte: { [number]: number } = {}
local lookupFromByte: { [number]: number } = {}

for i = 1, #alphabet do
	local byte = string.byte(alphabet, i, i)
	lookupToByte[i - 1] = byte
	lookupFromByte[byte] = i - 1
end

local function Encode(num: number): string
	assert(num >= 0, "Tried to encode a negative number")

	local outputBytes = {}
	repeat
		local remainder = math.fmod(num, 36)
		local character = lookupToByte[remainder]
		table.insert(outputBytes, character)

		num = (num - remainder) / 36
	until num <= 0

	return string.reverse(string.char(unpack(outputBytes)))
end

local function Decode(str: string): number
	local num = 0
	local values = { string.byte(str:upper(), 1, -1) }
	for i, value in values do
		num += lookupFromByte[value] * (math.pow(36, #values - i))
	end
	return num
end

return {
	Encode = Encode,
	Decode = Decode,
}

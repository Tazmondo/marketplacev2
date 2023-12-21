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

-- Note that this should only be used in non-greedy situations
-- I.e. where this being blocked is not a problem - it is a constant process
-- I had extending the random feed list in mind when writing this.
function Util.CreateRateDelay(interval: number)
	local lastCalled = 0
	local resumptionQueue = {}

	local function popResume()
		lastCalled = os.clock()

		local thread = assert(table.remove(resumptionQueue, 1))
		if #resumptionQueue > 0 then
			task.delay(interval, popResume)
		end

		coroutine.resume(thread)
	end

	local function rateDelay()
		if (os.clock() - lastCalled) >= interval then
			lastCalled = os.clock()
			return
		end
		if #resumptionQueue == 0 then
			task.delay(interval - (os.clock() - lastCalled), popResume)
		end

		table.insert(resumptionQueue, coroutine.running())
		if #resumptionQueue >= 10 then
			warn(debug.traceback("Rate delay may be getting overloaded!"))
		end
		coroutine.yield()
	end

	return rateDelay
end

return Util

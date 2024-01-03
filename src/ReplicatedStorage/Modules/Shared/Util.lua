local Util = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Future = require(ReplicatedStorage.Packages.Future)
local Signal = require(ReplicatedStorage.Packages.Signal)

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
function Util.CreateRateYield(interval: number)
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

-- A regular rate limit, returning a boolean for whether a request is allowed or not.
function Util.RateLimit<T>(count: number, interval: number)
	assert(count > 0 and interval > 0, "Count and interval must be >0 for rate limits.")
	local limits: { [T]: number? } = {}

	local function rateLimit(key: T): boolean
		local currentCount = (limits[key] or 0)
		if currentCount >= count then
			return false
		end

		limits[key] = currentCount + 1

		task.delay(interval, function()
			local newCount = assert(limits[key]) - 1

			-- Set to nil when 0 to prevent memory leaks.
			limits[key] = if newCount > 0 then newCount else nil
		end)

		return true
	end

	return rateLimit
end

-- Instead of having the rate limit logic account for the possibility of no key
-- 	just create a wrapper that uses a constant key instead.
function Util.GlobalRateLimit(count: number, interval: number)
	local rateLimit = Util.RateLimit(count, interval)

	return function()
		return rateLimit(1)
	end
end

-- Forces a yielding function to only be running once at any given time.
function Util.CreateYieldDebounce<T..., U...>(func: (T...) -> U...): (T...) -> U...
	local debounce = false
	local completed = Signal()

	return function(...)
		while debounce do
			completed:Wait()
		end
		debounce = true

		-- Use pcall here so one error doesn't permanently break the debounce
		local success, result = pcall(function(...)
			return table.pack(func(...)) :: any -- Type pack tables can't be properly typed right now.
		end, ...)

		debounce = false

		-- Defer here so we return before continuing subsequent calls
		task.defer(function()
			completed:Fire()
		end)

		-- We don't want errors to be silenced
		if not success then
			error(result)
		end

		-- Convert back into a tuple
		return table.unpack(result)
	end
end

function Util.ToFuture<T..., U...>(func: (T...) -> U...): (T...) -> Future.Future<U...>
	return function(...)
		return Future.new(func, ...)
	end
end
return Util

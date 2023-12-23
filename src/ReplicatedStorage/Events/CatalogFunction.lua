local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Red = require(ReplicatedStorage.Packages.Red)

return Red.Function("Catalog_Search", function(searchParams)
	print("Catalog search:", searchParams)
	return Types.GuardSearchParams(searchParams)
end, function(results)
	return results :: { Types.SearchResult } | false
end)

--!nolint LocalShadow
-- Handles catalog searching. From the client there are heavy rate limits but it's a lot more lenient from the server.
local CatalogService = {}

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

local CatalogFunction = require(ReplicatedStorage.Events.CatalogFunction)

local CatalogRateLimit = Util.RateLimit(5, 10)

local MAXPAGES = 4

function HandleSearch(player: Player, params: Types.SearchParams): boolean | { Types.SearchResult }
	local canSearch = CatalogRateLimit(player)
	if not canSearch then
		return false
	end

	-- Need to cast to any as luau lsp wasnt up to date with the latest api, giving incorrect type errors
	-- https://create.roblox.com/docs/reference/engine/datatypes/CatalogSearchParams
	local paramsInstance: any = CatalogSearchParams.new()

	if params.SearchKeyword then
		paramsInstance.SearchKeyword = params.SearchKeyword
	end
	if params.CreatorName then
		paramsInstance.CreatorName = params.CreatorName
	end
	if params.IncludeOffSale then
		paramsInstance.IncludeOffSale = params.IncludeOffSale
	end
	if params.MaxPrice then
		paramsInstance.MaxPrice = params.MaxPrice
	end
	if params.MinPrice then
		paramsInstance.MinPrice = params.MinPrice
	end
	if params.SortType then
		paramsInstance.SortType = Enum.CatalogSortType:GetEnumItems()[params.SortType]
	end

	paramsInstance.AssetTypes = DataFetch.GetValidAssetArray()

	-- Yields
	local success, pages = pcall(function()
		return AvatarEditorService:SearchCatalog(paramsInstance)
	end)
	if not success then
		return false
	end

	local filteredItems = {}
	local currentPage = 1

	while true do
		local items = pages:GetCurrentPage() :: { Types.SearchResult }
		for i, item in items do
			if params.CreatorMode ~= "All" and params.CreatorMode ~= item.CreatorType then
				continue
			end

			if item.AssetType and DataFetch.IsAssetTypeValid(item.AssetType) then
				table.insert(filteredItems, item)
			end
		end

		if pages.IsFinished or currentPage == MAXPAGES or #filteredItems >= 60 then
			break
		end

		pages:AdvanceToNextPageAsync()
		currentPage += 1
	end

	return filteredItems
end

function CatalogService:Initialize()
	CatalogFunction:SetCallback(HandleSearch)
end

CatalogService:Initialize()

return CatalogService

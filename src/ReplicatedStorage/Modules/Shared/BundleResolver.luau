local BundleResolver = {}

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataFetch = require(ReplicatedStorage.Modules.Shared.DataFetch)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Future = require(ReplicatedStorage.Packages.Future)

export type Bundle = {
	id: number,
	creator: string,
	price: number?,
	name: string,
}

-- Some body parts use a dash, some don't,
local endings = {
	" - Left Arm",
	" Left Arm",
	" - Right Arm",
	" Right Arm",
	" - Head",
	" Head",
	" - Torso",
	" Torso",
	" - Right Leg",
	" Right Leg",
	" - Left Leg",
	" Left Leg",
}

local function HasEnding(str: string, ending: string): boolean
	return string.sub(str, -#ending, -1) == ending
end

local function ExtractBundleName(bodyPart: string): string?
	for _, ending in endings do
		if HasEnding(bodyPart, ending) then
			local bundleName = string.sub(bodyPart, 1, (-#ending - 1))
			return bundleName
		end
	end
	return
end

local function GetBundleFromPart(partId: number)
	return Future.new(function(partId: number): Bundle?
		local bodyPartDetails = DataFetch.GetItemDetails(partId):Await()
		if not bodyPartDetails then
			return
		end

		local bundleName = ExtractBundleName(bodyPartDetails.name)
		if not bundleName then
			return
		end

		local searchParams = CatalogSearchParams.new()
		searchParams.SearchKeyword = bundleName;
		(searchParams :: any).BundleTypes = { Enum.BundleType.BodyParts };
		(searchParams :: any).IncludeOffSale = true
		searchParams.SortType = Enum.CatalogSortType.Relevance

		local success, bundles = pcall(function()
			return AvatarEditorService:SearchCatalog(searchParams):GetCurrentPage()
		end)

		if not success then
			warn(bundles)
			return nil
		end

		if #bundles == 0 then
			return
		end

		-- This is naive - in future, i should loop through the bundles and find the first one which contains the given body part id
		local bundle = bundles[1]

		return {
			id = bundle.Id,
			creator = bundle.CreatorName,
			price = bundle.Price,
			name = bundle.Name,
		}
	end, partId)
end

BundleResolver.BundleFromPart = Util.FutureCache(GetBundleFromPart)

function BundleResolver.GetOutfitBundles(outfit: HumanoidDescription)
	return Future.new(function(): { Bundle }
		local doneBundleSet: { [number]: true? } = {}
		local bundles = {}

		for _, id in
			{
				outfit.LeftArm,
				outfit.LeftLeg,
				outfit.RightArm,
				outfit.RightLeg,
				outfit.Torso,
				outfit.Head,
			}
		do
			if id == 0 then
				continue
			end

			local bundle = BundleResolver.BundleFromPart.Get(id):Await()
			if bundle and not doneBundleSet[bundle.id] then
				doneBundleSet[bundle.id] = true
				table.insert(bundles, bundle)
			end
		end

		return bundles
	end)
end

function BundleResolver.GetOutfitPrice(outfit: HumanoidDescription)
	return Future.new(function(): number
		local price = 0

		for _, accessory in outfit:GetAccessories(true) do
			local data = DataFetch.GetItemDetails(accessory.AssetId):Await()
			if data and data.price then
				price += data.price
			end
		end

		for _, bundle in BundleResolver.GetOutfitBundles(outfit):Await() do
			if bundle.price then
				price += bundle.price
			end
		end

		for _, classic in
			{
				outfit.GraphicTShirt,
				outfit.Shirt,
				outfit.Pants,
			}
		do
			if classic == 0 then
				continue
			end

			local data = DataFetch.GetItemDetails(classic):Await()
			if data and data.price then
				price += data.price
			end
		end

		return price
	end)
end

function BundleResolver.IsAssetBodyPart(assetType: Enum.AssetType | Enum.AvatarAssetType): boolean
	return assetType == Enum.AssetType.Head
		or assetType == Enum.AssetType.Torso
		or assetType == Enum.AssetType.LeftArm
		or assetType == Enum.AssetType.LeftLeg
		or assetType == Enum.AssetType.RightArm
		or assetType == Enum.AssetType.RightLeg
		or assetType == Enum.AvatarAssetType.Head
		or assetType == Enum.AvatarAssetType.Torso
		or assetType == Enum.AvatarAssetType.LeftArm
		or assetType == Enum.AvatarAssetType.LeftLeg
		or assetType == Enum.AvatarAssetType.RightArm
		or assetType == Enum.AvatarAssetType.RightLeg
end

local function GetBundleDetails(bundleId: number)
	return Future.new(function(): Bundle?
		local success, bundle = pcall(function()
			return AvatarEditorService:GetItemDetails(bundleId, Enum.AvatarItemType.Bundle)
		end)

		if not success then
			warn(bundle)
			return nil
		end

		return {
			id = bundle.Id,
			creator = bundle.CreatorName,
			price = bundle.Price,
			name = bundle.Name,
		}
	end)
end

BundleResolver.BundleFromId = Util.FutureCache(GetBundleDetails)

return BundleResolver

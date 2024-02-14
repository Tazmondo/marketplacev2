local GlobalUpdates = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(script.Parent.ProfileService)
local ShareCodes = require(script.Parent.ShareCodes)
local Data = require(ReplicatedStorage.Modules.Shared.Data)

export type ShareCodeUpdate = {
	type: "ShareCode",
	code: number,
	player: number,
	guid: string,
}

export type EarnedUpdate = {
	type: "EarnedV2",
	amount: number,
	count: number,
}

export type DonationUpdate = {
	type: "Donation",
	amount: number,
	count: number,
}

export type Update = ShareCodeUpdate | EarnedUpdate | DonationUpdate
type UpdateType = typeof(((nil :: any) :: Update).type)

function GlobalUpdates.ProcessGlobalUpdate(data: Data.Data, update: Update): boolean
	-- legacy checks, old global updates that are no longer valid
	if (update.type :: string) == "Earned" then
		return true
	end

	if update.type == "ShareCode" then
		ShareCodes.UpdatePlayerData(data, update.code, update.player, update.guid)
	elseif update.type == "EarnedV2" then
		data.sales += update.count
		data.shopbux += update.amount
		data.totalShopbux += update.amount
	elseif update.type == "Donation" then
		data.donationRobux += update.amount
		data.donationsReceived += update.count
	end

	return false
end

-- Pseudo-turbofish, for ease of use when being called
local function GetExistingUpdate<T>(globalUpdates: ProfileService.GlobalUpdates, type: UpdateType, turboFish: T & Update)
	for _, update in globalUpdates:GetActiveUpdates() do
		local id = update[1]
		local data = update[2] :: T & Update
		if data.type == type then
			return data or nil, id
		end
	end
	return nil, nil
end

function GlobalUpdates.CreateShareCodeUpdate(
	globalUpdates: ProfileService.GlobalUpdates,
	player: number,
	code: number,
	guid: string
)
	local data: ShareCodeUpdate = {
		type = "ShareCode",
		code = code,
		player = player,
		guid = guid,
	}

	globalUpdates:AddActiveUpdate(data)
end

function GlobalUpdates.CreateEarnedUpdate(globalUpdates: ProfileService.GlobalUpdates, amount: number, count: number)
	local existingUpdate, id = GetExistingUpdate(globalUpdates, "EarnedV2", {} :: EarnedUpdate)

	if existingUpdate then
		local data: EarnedUpdate = {
			type = "EarnedV2",
			amount = existingUpdate.amount + amount,
			count = existingUpdate.count + count,
		}
		globalUpdates:ChangeActiveUpdate(id, data)
	else
		local data: EarnedUpdate = {
			type = "EarnedV2",
			amount = amount,
			count = count,
		}
		globalUpdates:AddActiveUpdate(data)
	end
end

function GlobalUpdates.CreateDonatedUpdate(globalUpdates: ProfileService.GlobalUpdates, amount: number, count: number)
	local existingUpdate, id = GetExistingUpdate(globalUpdates, "Donation", {} :: DonationUpdate)
	if existingUpdate then
		local data: DonationUpdate = {
			type = "Donation",
			amount = existingUpdate.amount + amount,
			count = existingUpdate.count + count,
		}
		globalUpdates:ChangeActiveUpdate(id, data)
	else
		local data: DonationUpdate = {
			type = "Donation",
			amount = amount,
			count = count,
		}
		globalUpdates:AddActiveUpdate(data)
	end
end

return GlobalUpdates

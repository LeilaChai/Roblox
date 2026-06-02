--!strict
-- Minimal per-player save data. Backed by DataStore, with a graceful
-- in-memory fallback so it still works in Studio without API access enabled.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Profile = {}

type Data = { legPower: number, leapCoins: number, maxHeight: number }

local DEFAULT: Data = { legPower = 0, leapCoins = 0, maxHeight = 0 }

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[Profile] DataStore unavailable — using in-memory fallback. " ..
			"(Enable Studio Access to API Services to persist.)")
	end
end

local cache: { [Player]: Data } = {}

local function key(player: Player): string
	return "u_" .. player.UserId
end

function Profile.load(player: Player): Data
	local loaded: any = nil
	if store then
		local ok, result = pcall(function()
			return store:GetAsync(key(player))
		end)
		if ok and type(result) == "table" then
			loaded = result
		end
	end

	local data: Data = {
		legPower = (loaded and loaded.legPower) or DEFAULT.legPower,
		leapCoins = (loaded and loaded.leapCoins) or DEFAULT.leapCoins,
		maxHeight = (loaded and loaded.maxHeight) or DEFAULT.maxHeight,
	}
	cache[player] = data
	return data
end

function Profile.get(player: Player, field: string): number
	local data = cache[player]
	return (data and (data :: any)[field]) or 0
end

function Profile.set(player: Player, field: string, value: number)
	local data = cache[player]
	if data then
		(data :: any)[field] = value
	end
end

function Profile.save(player: Player)
	local data = cache[player]
	if not data or not store then
		return
	end
	pcall(function()
		store:SetAsync(key(player), data)
	end)
end

function Profile.clear(player: Player)
	cache[player] = nil
end

return Profile

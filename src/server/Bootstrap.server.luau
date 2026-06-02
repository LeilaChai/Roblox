--!strict
-- M1 server entry point: loads services and wires player lifecycle + jumps.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local Services = script.Parent:WaitForChild("Services")
local Profile = require(Services:WaitForChild("Profile"))
local LegPowerService = require(Services:WaitForChild("LegPowerService"))
local EconomyService = require(Services:WaitForChild("EconomyService"))
local HeightTracker = require(Services:WaitForChild("HeightTracker"))
local LegVisual = require(Services:WaitForChild("LegVisual"))

local function onCharacterAdded(player: Player, character: Model)
	LegVisual.apply(player, character)
	HeightTracker.onCharacter(player, character)
end

local function onPlayerAdded(player: Player)
	Profile.load(player)

	-- Seed replicated attributes for the client/HUD.
	LegPowerService.sync(player)
	EconomyService.sync(player)
	player:SetAttribute("MaxHeight", Profile.get(player, "maxHeight"))
	player:SetAttribute("Height", 0)
	player:SetAttribute("ChargeBonus", 0) -- run-scoped loop reward (future milestone)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	Profile.save(player)
	Profile.clear(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player) -- handle players already present (live sync)
end

-- A landed charged jump grows LegPower (authoritative) and updates girth.
Remotes.RequestJump.OnServerEvent:Connect(function(player, chargeFraction)
	if type(chargeFraction) ~= "number" then
		return
	end
	LegPowerService.onJump(player)
	LegVisual.apply(player, player.Character)
end)

-- Height -> Leap Coins (new height only).
HeightTracker.start({
	onNewHeight = function(player, studsGained)
		EconomyService.addCoins(player, studsGained * Config.COINS_PER_STUD)
	end,
})

print("[Leap of Legends] M1 server ready.")

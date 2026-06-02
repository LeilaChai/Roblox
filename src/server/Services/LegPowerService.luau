--!strict
-- Owns the account-permanent LegPower stat. Each charged jump grows it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Profile = require(script.Parent:WaitForChild("Profile"))

local LegPowerService = {}

-- Sync the player's LegPower to a replicated attribute so the client can
-- compute jump height locally for a responsive feel.
function LegPowerService.sync(player: Player)
	player:SetAttribute("LegPower", Profile.get(player, "legPower"))
end

-- Called once per landed charged jump. Returns the new LegPower.
function LegPowerService.onJump(player: Player): number
	local newValue = Profile.get(player, "legPower") + Config.LEGPOWER_PER_JUMP
	Profile.set(player, "legPower", newValue)
	player:SetAttribute("LegPower", newValue)
	return newValue
end

return LegPowerService

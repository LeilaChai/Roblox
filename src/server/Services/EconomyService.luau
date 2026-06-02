--!strict
-- Leap Coins wallet. Coins are awarded by HeightTracker for new height.

local Profile = require(script.Parent:WaitForChild("Profile"))

local EconomyService = {}

function EconomyService.sync(player: Player)
	player:SetAttribute("LeapCoins", Profile.get(player, "leapCoins"))
end

function EconomyService.addCoins(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	local newValue = Profile.get(player, "leapCoins") + amount
	Profile.set(player, "leapCoins", newValue)
	player:SetAttribute("LeapCoins", newValue)
end

return EconomyService

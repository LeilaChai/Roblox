--!strict
-- Makes the avatar visibly thicker as LegPower grows — but ONLY when the
-- LegPower tier actually changes. Re-setting body scale every frame re-fits
-- the rig and causes a leg twitch, so we throttle to tier boundaries.
-- M1 uses the robust Humanoid body-scale values (width/depth); true per-leg
-- girth scaling is a later polish pass (see GDD §4.2 / §11).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Profile = require(script.Parent:WaitForChild("Profile"))

local LegVisual = {}

local lastTier: { [Player]: number } = {}

local function tierFor(legPower: number): number
	local tier = 1
	local thresholds = Config.LEGPOWER_TIER_PRESSES
	for i = #thresholds, 1, -1 do
		if legPower >= thresholds[i] then
			tier = i
			break
		end
	end
	return tier
end

local function setScale(character: Model, scale: number)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local width = humanoid:FindFirstChild("BodyWidthScale")
	local depth = humanoid:FindFirstChild("BodyDepthScale")
	if width and width:IsA("NumberValue") then
		width.Value = scale
	end
	if depth and depth:IsA("NumberValue") then
		depth.Value = scale
	end
end

-- Call freely (e.g. on every jump). It only touches the rig when the tier moves.
function LegVisual.apply(player: Player, character: Model?)
	if not character then
		return
	end
	local tier = tierFor(Profile.get(player, "legPower"))
	if lastTier[player] == tier then
		return
	end
	lastTier[player] = tier
	setScale(character, Config.LEGPOWER_TIER_GIRTH[tier] or 1)
end

-- Reset cache so the next apply re-stamps the scale onto a fresh character.
function LegVisual.onNewCharacter(player: Player)
	lastTier[player] = nil
end

function LegVisual.clear(player: Player)
	lastTier[player] = nil
end

return LegVisual

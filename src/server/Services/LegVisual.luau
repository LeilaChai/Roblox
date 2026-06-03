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

local lastScale: { [Player]: number } = {}

local function girthFor(legPower: number): number
	return math.clamp(1 + legPower * Config.GIRTH_PER_PRESS, 1, Config.GIRTH_MAX_SCALE)
end

-- The leg parts we balloon. R15 first, R6 names as a fallback.
local LEG_PARTS = {
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
	"Left Leg", "Right Leg",
}

-- Thicken ONLY the leg parts: scale their X/Z (girth) but keep Y (length) so
-- the hip/knee joints stay vertically aligned and the legs don't detach.
local function setScale(character: Model, scale: number)
	for _, name in ipairs(LEG_PARTS) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			local origAttr = part:GetAttribute("LeapOrigSize")
			local orig: Vector3
			if typeof(origAttr) == "Vector3" then
				orig = origAttr :: Vector3
			else
				orig = part.Size
				part:SetAttribute("LeapOrigSize", orig) -- remember the original once
			end
			part.Size = Vector3.new(orig.X * scale, orig.Y, orig.Z * scale)
		end
	end
end

-- Call freely (e.g. on every jump). It only re-stamps the rig once the girth
-- has moved by GIRTH_UPDATE_STEP (avoids a per-frame rig re-fit / jitter).
function LegVisual.apply(player: Player, character: Model?)
	if not character then
		return
	end
	local scale = girthFor(Profile.get(player, "legPower"))
	local prev = lastScale[player]
	if prev and math.abs(scale - prev) < Config.GIRTH_UPDATE_STEP and scale < Config.GIRTH_MAX_SCALE then
		return
	end
	lastScale[player] = scale
	setScale(character, scale)
end

-- Reset cache so the next apply re-stamps the scale onto a fresh character.
function LegVisual.onNewCharacter(player: Player)
	lastScale[player] = nil
end

function LegVisual.clear(player: Player)
	lastScale[player] = nil
end

return LegVisual

--!strict
-- Makes the avatar visibly thicker as LegPower grows.
-- M1 uses the robust Humanoid body-scale values (width/depth). True per-leg
-- girth scaling is a later polish pass (see GDD §4.2 / §11).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Profile = require(script.Parent:WaitForChild("Profile"))

local LegVisual = {}

function LegVisual.apply(player: Player, character: Model?)
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local legPower = Profile.get(player, "legPower")
	local scale = math.clamp(1 + legPower * Config.GIRTH_PER_PRESS, 1, Config.GIRTH_MAX_SCALE)

	local width = humanoid:FindFirstChild("BodyWidthScale")
	local depth = humanoid:FindFirstChild("BodyDepthScale")
	if width and width:IsA("NumberValue") then
		width.Value = scale
	end
	if depth and depth:IsA("NumberValue") then
		depth.Value = scale
	end
end

return LegVisual

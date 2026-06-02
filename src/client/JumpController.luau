--!strict
-- Hold SPACE to jump. You rise to your jump height; the progress bar drains as
-- you rise and is EMPTY exactly at the peak — at which point you fall. Holding
-- through a landing immediately jumps again, so you bounce up the tower.
-- Jump height and rise/fall speed both scale with account-permanent LegPower.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local JumpController = {}

local ACTION_NAME = "LeapJump"

local holding = false
local spent = false   -- reached the peak of the current jump; falling until we land
local airTime = 0     -- safety: how long we've been rising (prevents sticking under a ledge)
local tickAccum = 0   -- accumulates time to space out LegPower "presses"
local lastGroundY = 0 -- Y of the platform we last stood on (jump-height reference)
local barFraction = 1 -- 1 = full (ready / just launched), 0 = at the peak

local function getCharacter(): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return humanoid, hrp
end

-- ── Jump-time bar UI ─────────────────────────────────────────────
local barFill: Frame? = nil

local function buildBar()
	local gui = Instance.new("ScreenGui")
	gui.Name = "JumpTimeGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.AnchorPoint = Vector2.new(0.5, 1)
	back.Position = UDim2.new(0.5, 0, 1, -40)
	back.Size = UDim2.new(0, 240, 0, 18)
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	back.BackgroundTransparency = 0.25
	back.BorderSizePixel = 0
	back.Parent = gui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
	fill.BorderSizePixel = 0
	fill.Parent = back

	barFill = fill
end

local function updateBar()
	if not barFill then
		return
	end
	local fraction = math.clamp(barFraction, 0, 1)
	barFill.Size = UDim2.new(fraction, 0, 1, 0)
	-- green with rise headroom left, red as you near the peak
	barFill.BackgroundColor3 = Color3.fromRGB(
		math.floor(90 + (1 - fraction) * 165),
		math.floor(80 + fraction * 120),
		math.floor(120 - fraction * 40)
	)
end

-- Disable the Humanoid's Jumping state so Roblox doesn't keep replaying the
-- jump animation each time we apply upward velocity. We drive the vertical
-- movement ourselves; airborne stays in a stable Freefall pose.
local function setupCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end
end

function JumpController.start()
	if player.Character then
		setupCharacter(player.Character)
	end
	player.CharacterAdded:Connect(setupCharacter)

	buildBar()

	ContextActionService:BindAction(ACTION_NAME, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			holding = true
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			holding = false
		end
		return Enum.ContextActionResult.Sink -- prevent the default jump
	end, true, Enum.KeyCode.Space)

	RunService.Heartbeat:Connect(function(dt)
		local humanoid, hrp = getCharacter()
		if not humanoid or not hrp then
			return
		end
		if humanoid.Health <= 0 or humanoid.Sit then
			return
		end

		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		if grounded then
			-- Touch down -> ready to jump again immediately (bar full).
			spent = false
			airTime = 0
			lastGroundY = hrp.Position.Y -- launch reference for the jump-height cap
		end

		-- LegPower (account-permanent) + ChargeBonus (run-scoped) drive both how
		-- HIGH you can jump and how FAST you rise/fall.
		local legPower = (player:GetAttribute("LegPower") :: number?) or 0
		local chargeBonus = (player:GetAttribute("ChargeBonus") :: number?) or 0
		local speedMult = (1 + legPower * Config.LEGPOWER_SPEED_BONUS_PER_PRESS) * (1 + chargeBonus)
		local heightMult = (1 + legPower * Config.LEGPOWER_HEIGHT_BONUS_PER_PRESS) * (1 + chargeBonus)

		local maxJumpHeight = Config.BASE_JUMP_HEIGHT * heightMult
		local riseSpeed = math.min(Config.JUMP_RISE_SPEED * speedMult, Config.MAX_VERTICAL_SPEED)
		local fallSpeed = math.min(Config.BASE_FALL_SPEED * speedMult, Config.MAX_VERTICAL_SPEED)

		-- Horizontal steering from movement input, so you can move while jumping.
		local move = humanoid.MoveDirection * Config.AIR_MOVE_SPEED
		local velocity = hrp.AssemblyLinearVelocity
		local heightGained = hrp.Position.Y - lastGroundY
		local rising = holding and not spent and heightGained < maxJumpHeight

		if rising then
			-- Rise fast toward your jump height. The bar drains with height gained
			-- and hits empty exactly at the peak.
			hrp.AssemblyLinearVelocity = Vector3.new(move.X, riseSpeed, move.Z)
			barFraction = 1 - heightGained / maxJumpHeight

			if not grounded then
				airTime += dt
				if airTime > Config.MAX_JUMP_TIME then
					spent = true -- safety: blocked under a ledge, stop trying to rise
				end
			end

			-- Holding counts as repeated presses for LegPower growth (rate-limited).
			tickAccum += dt
			while tickAccum >= Config.LEGPOWER_TICK_INTERVAL do
				tickAccum -= Config.LEGPOWER_TICK_INTERVAL
				Remotes.RequestJump:FireServer(1)
			end
		else
			tickAccum = 0
			-- Peak reached (or released): commit to falling until we land again.
			if holding and not grounded then
				spent = true
			end
			barFraction = grounded and 1 or 0

			-- Thicker legs fall faster: enforce a LegPower-scaled minimum fall speed,
			-- while still letting you steer horizontally on the way down.
			if not grounded and velocity.Y < 0 then
				local vy = math.min(velocity.Y, -fallSpeed)
				hrp.AssemblyLinearVelocity = Vector3.new(move.X, vy, move.Z)
			end
		end

		updateBar()
	end)
end

return JumpController

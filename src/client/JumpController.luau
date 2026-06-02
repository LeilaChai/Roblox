--!strict
-- Hold SPACE to keep jumping. A Jump-Time meter (seconds) drains while you
-- jump; when it empties you fall automatically and must land to recharge it.
-- Each hop scales with account-permanent LegPower (more presses = higher),
-- and the server independently grows LegPower on every hop.

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
local jumpTime = Config.MAX_JUMP_TIME -- seconds of jumping remaining
local depletedLock = false            -- true once drained; cleared on landing
local tickAccum = 0                   -- accumulates time to space out LegPower "presses"

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
	local fraction = math.clamp(jumpTime / Config.MAX_JUMP_TIME, 0, 1)
	barFill.Size = UDim2.new(fraction, 0, 1, 0)
	-- green when plenty of jump time, red when nearly out
	barFill.BackgroundColor3 = Color3.fromRGB(
		math.floor(90 + (1 - fraction) * 165),
		math.floor(80 + fraction * 120),
		math.floor(120 - fraction * 40)
	)
end

-- Speed multiplier from LegPower (account-permanent) + ChargeBonus (run-scoped).
local function speedMultiplier(): number
	local legPower = (player:GetAttribute("LegPower") :: number?) or 0
	local chargeBonus = (player:GetAttribute("ChargeBonus") :: number?) or 0
	return (1 + legPower * Config.LEGPOWER_SPEED_BONUS_PER_PRESS) * (1 + chargeBonus)
end

function JumpController.start()
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
			-- Touching down instantly refills jump time — no waiting to jump again.
			jumpTime = Config.MAX_JUMP_TIME
			depletedLock = false
		end

		local mult = speedMultiplier()
		local velocity = hrp.AssemblyLinearVelocity
		local active = holding and jumpTime > 0 and not depletedLock

		if active then
			if not grounded then
				jumpTime = math.max(0, jumpTime - dt) -- only airborne jumping drains time
				if jumpTime <= 0 then
					depletedLock = true -- out of time -> fall until we land
				end
			end

			-- Smooth, constant upward speed every frame (no apex snapping = no glitch).
			-- Faster with thicker legs.
			local riseSpeed = Config.JUMP_RISE_SPEED * mult
			hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, riseSpeed, velocity.Z)

			-- Holding counts as repeated presses for LegPower growth (rate-limited).
			tickAccum += dt
			while tickAccum >= Config.LEGPOWER_TICK_INTERVAL do
				tickAccum -= Config.LEGPOWER_TICK_INTERVAL
				Remotes.RequestJump:FireServer(1)
			end
		else
			tickAccum = 0
			-- Thicker legs fall faster: enforce a LegPower-scaled minimum fall speed.
			if not grounded and velocity.Y < 0 then
				local fallSpeed = Config.BASE_FALL_SPEED * mult
				if velocity.Y > -fallSpeed then
					hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, -fallSpeed, velocity.Z)
				end
			end
		end

		updateBar()
	end)
end

return JumpController

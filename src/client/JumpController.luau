--!strict
-- Press SPACE to jump, then KEEP HOLDING to keep rising toward your max jump
-- height; release (or hit the peak) and you fall immediately. The more total
-- presses you've made, the higher you can go (max height = presses × BASE_JUMP_HEIGHT),
-- so bigger jumps require holding longer.
-- NO auto-jump: once you land, a still-held key does nothing — you must RELEASE
-- and press Space again to start the next jump.
-- The progress bar drains as you rise and is EMPTY exactly at the peak.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local JumpController = {}

local ACTION_NAME = "LeapJump"

local holding = false  -- is Space currently held? (must hold to keep rising)
local jumpQueued = false -- a fresh Space press waiting to start a jump
local jumpActive = false -- a jump is in progress (launched from a press, not yet landed)
local spent = false   -- reached the peak of the current jump; falling until we land
local wasGrounded = false -- tracks the air→ground transition to detect a fresh landing
local airTime = 0     -- safety: how long we've been rising (prevents sticking under a ledge)
local lastGroundY = 0 -- Y of the platform we last stood on (jump-height reference)
local barFraction = 1 -- 1 = full (ready / just launched), 0 = at the peak (true value)
local displayedFraction = 1 -- smoothed value shown on the bar (drains slowly)
local knockedUntil = 0 -- os.clock() until which we're stomped (jump input ignored)
local knockSpeed = 0   -- downward speed applied while knocked
local jumpTrack: AnimationTrack? = nil -- jump animation, played while rising
-- Local, immediately-updated count of total spacebar presses. The server's
-- LegPower is authoritative & persisted, but it replicates back a frame late;
-- we increment this the instant a jump launches so the CURRENT jump already
-- reflects the press (jump height = presses × BASE_JUMP_HEIGHT, no lag).
local presses = 0

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
	local fraction = math.clamp(displayedFraction, 0, 1)
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
	if not (humanoid and humanoid:IsA("Humanoid")) then
		return
	end
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	-- Kill Roblox's automatic obstacle-jump (on by default, esp. on touch) — a
	-- real source of "auto jump" where the character hops without input.
	humanoid.AutoJumpEnabled = false

	-- With the Jumping state disabled, the default Animate script shows the FALL
	-- pose the WHOLE time you're airborne. To show the JUMP pose while RISING, load
	-- the jump animation here and play it ourselves during the rise (high priority
	-- so it overrides the default fall); on the way down we stop it and fall shows.
	jumpTrack = nil
	local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5)
	if animator and animator:IsA("Animator") then
		local jumpId = "rbxassetid://616163682" -- R15 default jump (fallback)
		local animate = character:FindFirstChild("Animate")
		local jumpFolder = animate and animate:FindFirstChild("jump")
		local jumpAnim = jumpFolder and jumpFolder:FindFirstChildWhichIsA("Animation")
		if jumpAnim and jumpAnim.AnimationId ~= "" then
			jumpId = jumpAnim.AnimationId
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = jumpId
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Action4 -- override the default fall
			track.Looped = true -- hold the jump pose for the whole rise
			jumpTrack = track
		end
	end
end

function JumpController.start()
	if player.Character then
		setupCharacter(player.Character)
	end
	player.CharacterAdded:Connect(setupCharacter)

	buildBar()

	-- Seed the local press count from the server's saved LegPower, and keep it in
	-- sync as the authoritative value replicates (never go backwards from a late
	-- update — our local count may legitimately be ahead by the in-flight press).
	presses = (player:GetAttribute("LegPower") :: number?) or 0
	player:GetAttributeChangedSignal("LegPower"):Connect(function()
		local serverValue = (player:GetAttribute("LegPower") :: number?) or 0
		if serverValue > presses then
			presses = serverValue
		end
	end)

	-- M2: got stomped by a stronger-legged player -> get knocked down.
	Remotes.Stomped.OnClientEvent:Connect(function(pushSpeed: number, stun: number)
		knockSpeed = pushSpeed
		knockedUntil = os.clock() + stun
	end)

	-- Bind Space at HIGH priority so we always sink it ABOVE Roblox's built-in
	-- jump binding (the default control module also uses ContextActionService; a
	-- plain BindAction can sit BELOW it and let the default auto-jump through).
	ContextActionService:BindActionAtPriority(ACTION_NAME, function(_, inputState)
		-- Begin fires once per physical press: arm a jump on that edge AND mark the
		-- key as held. Holding keeps you rising; releasing makes you fall. The
		-- landing-edge guard below stops a held key from auto-starting a new jump.
		if inputState == Enum.UserInputState.Begin then
			holding = true
			jumpQueued = true -- fresh press: arm exactly one jump
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			holding = false
		end
		return Enum.ContextActionResult.Sink -- prevent the default jump
	end, true, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)

	RunService.Heartbeat:Connect(function(dt)
		local humanoid, hrp = getCharacter()
		if not humanoid or not hrp then
			return
		end
		if humanoid.Health <= 0 or humanoid.Sit then
			return
		end

		-- M2: while stomped, get driven downward and ignore jump input.
		if os.clock() < knockedUntil then
			local v = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, -knockSpeed, v.Z)
			spent = true -- can't jump out of the knockback
			displayedFraction = 0
			updateBar()
			return
		end

		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		if grounded and not wasGrounded then
			-- JUST LANDED: end the jump and clear any press that was buffered while
			-- airborne. This is what prevents auto-jump — a key still held from the
			-- previous jump is ignored; you must release and press Space again.
			spent = false
			airTime = 0
			lastGroundY = hrp.Position.Y -- launch reference for the jump-height cap
			jumpActive = false
			jumpQueued = false
		elseif grounded then
			lastGroundY = hrp.Position.Y -- standing still: keep the launch reference fresh
		end
		wasGrounded = grounded

		-- A jump starts ONLY from a fresh Space press (Begin edge) made while
		-- grounded. jumpQueued is set by the input callback and cleared on landing,
		-- so holding the key can never trigger a second jump.
		if grounded and jumpQueued and not jumpActive then
			jumpActive = true
			jumpQueued = false -- consume the press
			-- Count this press locally RIGHT NOW so the jump we're about to take
			-- already uses the new height (no waiting for the server to replicate).
			presses += 1
			-- TEMP debug: confirm height scales with presses (remove after testing).
			print(string.format("[Leap] Jump #%d  ->  height = %d studs",
				presses, presses * Config.BASE_JUMP_HEIGHT))
			-- One jump = one "press": grow account-permanent LegPower (higher/faster
			-- jumps + thicker legs). Server is authoritative.
			Remotes.RequestJump:FireServer(1)
		end

		-- Total accumulated presses (account-permanent) + ChargeBonus (run-scoped)
		-- drive both how HIGH you can jump and how FAST you rise/fall.
		local chargeBonus = (player:GetAttribute("ChargeBonus") :: number?) or 0
		local speedMult = (1 + presses * Config.LEGPOWER_SPEED_BONUS_PER_PRESS) * (1 + chargeBonus)

		-- Jump height = (number of spacebar presses) × base. Each press adds
		-- BASE_JUMP_HEIGHT studs and accumulates forever; the first jump is base.
		local maxJumpHeight = math.max(1, presses) * Config.BASE_JUMP_HEIGHT
		local riseSpeed = math.min(Config.JUMP_RISE_SPEED * speedMult, Config.MAX_VERTICAL_SPEED)
		local fallSpeed = math.min(Config.BASE_FALL_SPEED * speedMult, Config.MAX_VERTICAL_SPEED)

		-- Horizontal steering from movement input, so you can move while jumping.
		local move = humanoid.MoveDirection * Config.AIR_MOVE_SPEED
		local heightGained = hrp.Position.Y - lastGroundY
		-- You rise only while STILL HOLDING Space and below your max jump height.
		-- Release early (or hit the peak) → you stop rising and fall immediately.
		-- Bigger jump height (more presses) means you must hold longer to reach it.
		local rising = jumpActive and holding and not spent and heightGained < maxJumpHeight

		if rising then
			local remaining = maxJumpHeight - heightGained
			if remaining <= riseSpeed * dt then
				-- We hit the TOP this frame: stop rising and FALL IMMEDIATELY. No
				-- easing/deceleration into the apex — the instant you reach your peak
				-- height you start dropping at full fall speed.
				spent = true
				barFraction = 0
				hrp.AssemblyLinearVelocity = Vector3.new(move.X, -fallSpeed, move.Z)
			else
				-- Rise at FULL speed the whole way up (no slow crawl near the top).
				hrp.AssemblyLinearVelocity = Vector3.new(move.X, riseSpeed, move.Z)
				barFraction = 1 - heightGained / maxJumpHeight
			end

			if not grounded then
				airTime += dt
				if airTime > Config.MAX_JUMP_TIME then
					spent = true -- safety: blocked under a ledge, stop trying to rise
				end
			end
		else
			-- Released, or peak reached: FALL IMMEDIATELY. Force downward velocity so
			-- there is no leftover upward momentum or hover at the top.
			if jumpActive and not grounded then
				spent = true
			end
			barFraction = grounded and 1 or 0

			-- Thicker legs fall faster (and we steer horizontally on the way down).
			if not grounded then
				hrp.AssemblyLinearVelocity = Vector3.new(move.X, -fallSpeed, move.Z)
			end
		end

		-- Animation: show the JUMP pose while RISING; on the way down (and on the
		-- ground) stop it so the default FALL / idle / walk poses show through.
		if jumpTrack then
			if rising and not grounded then
				if not jumpTrack.IsPlaying then
					jumpTrack:Play(0.1)
				end
			elseif jumpTrack.IsPlaying then
				jumpTrack:Stop(0.1)
			end
		end

		-- Ease the displayed bar toward the true power value: cap how fast it can
		-- DRAIN (so it decreases slowly and readably), but refill instantly when a
		-- new jump starts.
		local target = math.clamp(barFraction, 0, 1)
		if target < displayedFraction then
			displayedFraction = math.max(target, displayedFraction - Config.JUMP_BAR_DRAIN_RATE * dt)
		else
			displayedFraction = target
		end

		updateBar()
	end)
end

return JumpController

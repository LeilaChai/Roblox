--!strict
-- Hold SPACE to charge, release to jump. Jump height scales with charge,
-- account-permanent LegPower, and the run-scoped ChargeBonus.
-- Runs locally for responsiveness; the server independently grows LegPower.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local ChargeJump = {}

local ACTION_NAME = "LeapChargeJump"

local charging = false
local chargeStart = 0

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function getHumanoid(): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function isGrounded(humanoid: Humanoid): boolean
	return humanoid.FloorMaterial ~= Enum.Material.Air
end

-- ── Charge bar UI ────────────────────────────────────────────────
local barFill: Frame? = nil
local function buildBar()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ChargeBarGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.AnchorPoint = Vector2.new(0.5, 1)
	back.Position = UDim2.new(0.5, 0, 1, -40)
	back.Size = UDim2.new(0, 220, 0, 16)
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	back.BackgroundTransparency = 0.25
	back.BorderSizePixel = 0
	back.Visible = false
	back.Parent = gui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
	fill.BorderSizePixel = 0
	fill.Parent = back

	barFill = fill
end

local function setBar(fraction: number)
	if not barFill then
		return
	end
	local back = barFill.Parent :: Frame
	back.Visible = charging
	barFill.Size = UDim2.new(fraction, 0, 1, 0)
	barFill.BackgroundColor3 = fraction >= 1
		and Color3.fromRGB(240, 200, 70)
		or Color3.fromRGB(90, 200, 120)
end

-- ── Charge logic ─────────────────────────────────────────────────
local function startCharge()
	local humanoid = getHumanoid()
	if not humanoid or not isGrounded(humanoid) then
		return
	end
	charging = true
	chargeStart = os.clock()
	humanoid.WalkSpeed = 16 * Config.CHARGE_WALKSPEED_MULT
end

local function releaseCharge()
	if not charging then
		return
	end
	charging = false

	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = 16
	end
	setBar(0)
	if not humanoid then
		return
	end

	local fraction = math.clamp((os.clock() - chargeStart) / Config.FULL_CHARGE_TIME, 0, 1)
	if fraction < Config.MIN_CHARGE_FRACTION then
		fraction = Config.MIN_CHARGE_FRACTION
	end

	local legPower = (player:GetAttribute("LegPower") :: number?) or 0
	local chargeBonus = (player:GetAttribute("ChargeBonus") :: number?) or 0
	local legBonus = legPower * Config.LEGPOWER_JUMP_BONUS_PER_PRESS

	local height = lerp(Config.BASE_JUMP_HEIGHT, Config.MAX_CHARGE_JUMP_HEIGHT, fraction)
	height = height * (1 + legBonus) * (1 + chargeBonus)

	humanoid.UseJumpPower = false
	humanoid.JumpHeight = height
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	Remotes.RequestJump:FireServer(fraction)
end

local function onAction(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		startCharge()
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		releaseCharge()
	end
	-- Sink the input so the default jump never fires.
	return Enum.ContextActionResult.Sink
end

function ChargeJump.start()
	buildBar()

	-- Bind SPACE (and the mobile jump button) to our charge handler.
	ContextActionService:BindAction(ACTION_NAME, onAction, true, Enum.KeyCode.Space)

	RunService.RenderStepped:Connect(function()
		if charging then
			local fraction = math.clamp((os.clock() - chargeStart) / Config.FULL_CHARGE_TIME, 0, 1)
			setBar(fraction)
		end
	end)
end

return ChargeJump

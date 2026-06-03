--!strict
-- M2 stomp: when a player is on top of another and has STRONGER legs
-- (higher LegPower), the one underneath gets pushed down. Server-authoritative
-- detection; the victim's client applies the knock (see JumpController).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local StompService = {}

local lastStomp: { [Player]: number } = {} -- victim -> os.clock() of last stomp

local function rootOf(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function legPowerOf(player: Player): number
	return (player:GetAttribute("LegPower") :: number?) or 0
end

local function check()
	local players = Players:GetPlayers()
	for _, top in ipairs(players) do
		local topRoot = rootOf(top)
		if topRoot then
			for _, bottom in ipairs(players) do
				if top ~= bottom then
					local bottomRoot = rootOf(bottom)
					if bottomRoot then
						local dy = topRoot.Position.Y - bottomRoot.Position.Y
						if dy >= Config.STOMP_MIN_DY and dy <= Config.STOMP_MAX_DY then
							local delta = topRoot.Position - bottomRoot.Position
							local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude
							-- on top of them, and not jumping up into them
							if horizontal <= Config.STOMP_RADIUS and topRoot.AssemblyLinearVelocity.Y <= 1 then
								if legPowerOf(top) > legPowerOf(bottom) then
									local now = os.clock()
									if now - (lastStomp[bottom] or 0) >= Config.STOMP_COOLDOWN then
										lastStomp[bottom] = now
										Remotes.Stomped:FireClient(bottom, Config.STOMP_PUSH_SPEED, Config.STOMP_STUN)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function StompService.start()
	local accum = 0
	RunService.Heartbeat:Connect(function(dt)
		accum += dt
		if accum < Config.STOMP_CHECK_INTERVAL then
			return
		end
		accum = 0
		check()
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastStomp[player] = nil
	end)
end

return StompService

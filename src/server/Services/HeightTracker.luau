--!strict
-- Tracks how high each player has climbed above their spawn point.
-- Awards Leap Coins for NEW height only (no farming by bouncing up/down),
-- and records the account-permanent max height for the leaderboard.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Profile = require(script.Parent:WaitForChild("Profile"))

local HeightTracker = {}

type RunData = { baseline: number, runMax: number }
local data: { [Player]: RunData } = {}

export type Callbacks = { onNewHeight: (player: Player, studsGained: number) -> () }

-- Re-baseline whenever a fresh character spawns (a "run" resets here).
function HeightTracker.onCharacter(player: Player, character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hrp then
		return
	end
	task.wait(0.25) -- let the spawn settle before sampling Y
	data[player] = { baseline = hrp.Position.Y, runMax = 0 }
end

function HeightTracker.start(callbacks: Callbacks)
	RunService.Heartbeat:Connect(function()
		for player, d in pairs(data) do
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local height = hrp.Position.Y - d.baseline
				player:SetAttribute("Height", math.floor(math.max(height, 0)))

				if height > d.runMax + 0.001 then
					local gained = math.floor(height) - math.floor(d.runMax)
					if gained > 0 then
						callbacks.onNewHeight(player, gained)
					end
					d.runMax = height

					local accountMax = Profile.get(player, "maxHeight")
					if height > accountMax then
						Profile.set(player, "maxHeight", height)
						player:SetAttribute("MaxHeight", math.floor(height))
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		data[player] = nil
	end)
end

return HeightTracker

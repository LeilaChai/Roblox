local UserInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local FallDamage = game:GetService("ReplicatedStorage"):WaitForChild("FallDamage")
local UpdateMuscle = game:GetService("ReplicatedStorage"):WaitForChild("UpdateMuscle")
local UpdateJumpHeight = game:GetService("ReplicatedStorage"):WaitForChild("UpdateJumpHeight")
local StartFalling = game:GetService("ReplicatedStorage"):WaitForChild("StartFalling")
local StopFalling = game:GetService("ReplicatedStorage"):WaitForChild("StopFalling")

local numPressed = 1
local MAX_JUMPS = 1
local TIME_BETWEEN_JUMPS = 0.2
local numJUMPS = 0

local canJumpAgain = false
local isFalling = false
local startFallY = nil
local reachPeak = false

--humanoid.JumpHeight = 20






local function onStateChanged(oldState, newState)
	if Enum.HumanoidStateType.Landed == newState then
		numJUMPS = 0
		canJumpAgain = false
		reachPeak = false
		isFalling = false
		StopFalling:FireServer()
		--humanoid.JumpHeight = numPressed * 20
		-- fall damage check
		if not startFallY then return end -- if startFallY is empty exist the entire function
		local fallDistance = startFallY - hrp.Position.Y
		print("fallDistance:", fallDistance)
		if fallDistance >= 600 then
			FallDamage:FireServer() --auto passed player to the server side
		end
		startFallY = nil
	elseif Enum.HumanoidStateType.Jumping == newState then
		canJumpAgain = false
		numJUMPS += 1
		numPressed += 1
		UpdateMuscle:FireServer(numPressed)
		UpdateJumpHeight:FireServer(numPressed)
		startFallY = hrp.Position.Y
		print("Jumping:", startFallY)

	elseif Enum.HumanoidStateType.Freefall == newState then
		if not startFallY then
			startFallY = hrp.Position.Y
		end
		task.delay(TIME_BETWEEN_JUMPS, function()
			canJumpAgain = true
			print("Freefall", startFallY)
		end)
	end

end

runService.Heartbeat:Connect(function()
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		local verticalVelocity = hrp.AssemblyLinearVelocity.Y
		if verticalVelocity < 0 and not reachPeak then
			reachPeak = true
			startFallY = hrp.Position.Y
			print("Peak:", startFallY)
		end

		if verticalVelocity < 0 and not isFalling then
			isFalling = true
			StartFalling:FireServer(numPressed) -- pass the numPressed parameter to server, use to update falling speed
		end
	end
end)

local function onJumpRequest()
	if canJumpAgain and numJUMPS < MAX_JUMPS then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

humanoid.StateChanged:Connect(onStateChanged)
UserInputService.JumpRequest:Connect(onJumpRequest)

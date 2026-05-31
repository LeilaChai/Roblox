local UserInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local contextActionService = game:GetService("ContextActionService")
local connection = nil
local primaryPart = character.PrimaryPart

local vectorForce = script:WaitForChild("VectorForce")
local alignOrientation = script:WaitForChild("AlignOrientation")
vectorForce.Attachment0 = primaryPart.RootRigAttachment
alignOrientation.Attachment0 = primaryPart.RootRigAttachment




local gravityVector = Vector3.new(0, game.Workspace.Gravity, 0)

local drag = 1

local reachPeak = false
local isFalling = false
local startFallY = nil
local numPressed = 0

local FallDamage = game:GetService("ReplicatedStorage"):WaitForChild("FallDamage")
local UpdateMuscle = game:GetService("ReplicatedStorage"):WaitForChild("UpdateMuscle")

local flyTimeRemaining = 0
local isFlying = false
local flyExhaused = false
local spaceHeld = false

local jumped = false
local IsLanded = true

humanoid.JumpHeight = 5

local function FlyAction(actionName, inputState, inputObject)
	if not IsLanded then return end
	if inputState == Enum.UserInputState.Begin then
		numPressed += 0.1
		if connection == nil then
			vectorForce.Enabled = true
			alignOrientation.Enabled = true
			character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics) -- not able to move while fly
			flyTimeRemaining = numPressed
			isFlying = true
			connection = runService.Heartbeat:Connect(function(deltaTime)
				flyTimeRemaining = flyTimeRemaining - deltaTime
				print("Fly time left:",flyTimeRemaining)
					if flyTimeRemaining <= 0 then
						vectorForce.Enabled = false
						alignOrientation.Enabled = false
						connection:Disconnect()
						connection = nil
						--flyExhaused = true
						character.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
						isFlying = false

						return
					end


				local isMoving = UserInputService:IsKeyDown(Enum.KeyCode.W)
					or UserInputService:IsKeyDown(Enum.KeyCode.A)
					or UserInputService:IsKeyDown(Enum.KeyCode.S)
					or UserInputService:IsKeyDown(Enum.KeyCode.D)



				if isMoving and isFlying then

					local currentHeight = hrp.Position.Y
					local camera = workspace.CurrentCamera
					local lookDirection = camera.CFrame.LookVector
					local flatLook = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
					-- keep position, just change rotation to 90 degrees on X facing movement direction
					hrp.CFrame = CFrame.new(hrp.Position)
						* CFrame.lookAt(Vector3.new(0,0,0), flatLook)
						* CFrame.Angles(math.rad(-90), 0, 0)
					hrp.AssemblyLinearVelocity = Vector3.new(
						flatLook.X * numPressed * 100,
						0,  -- keep Y velocity unchanged
						flatLook.Z * numPressed * 100)
				else
					hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)  -- stop horizontal movement
					vectorForce.Force = gravityVector * primaryPart.AssemblyMass * 1.5
				end

				--[[if primaryPart.AssemblyLinearVelocity.Magnitude > 0 then
					local dragVector =- primaryPart.AssemblyLinearVelocity.Unit
					local v2 = primaryPart.AssemblyLinearVelocity.Magnitude ^ 2
					vectorForce.Force += dragVector * drag * primaryPart.AssemblyMass * v2

				end]]


				print("HB") --when press F it start to fly, press again stop flying
			end)
		end


	elseif inputState == Enum.UserInputState.End then
		character.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		isFlying = false
		vectorForce.Enabled = false
		alignOrientation.Enabled = false




		if connection then
			connection:Disconnect()
			connection = nil
			print("change to freefall")
		end

	end
	print(inputState)
end

--[[UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		FlyAction("Fly", Enum.UserInputState.Begin, nil)
	end
end)]]

--[[InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space or
		input.UserInputType == Enum.UserInputType.Touch then
		spaceHeld = false
		FlyAction("Fly", Enum.UserInputState.End, nil)
	end
end)]]



contextActionService:BindAction("Fly", FlyAction, true, Enum.KeyCode.Space)
local playerGui = player:WaitForChild("PlayerGui")
local touchGui = playerGui:WaitForChild("TouchGui", 5)
if touchGui then
	local jumpButton = touchGui:WaitForChild("TouchControlFrame")
		:WaitForChild("JumpButton")

	local flyButton = contextActionService:GetButton("Fly")
	if flyButton and jumpButton then
		flyButton.Size = jumpButton.Size
		flyButton.Position = jumpButton.Position
	--lyButton.BackgroundTransparency = 1
	--lyButton.ImageTransparency = 1
	end
end





local function onStateChanged(oldState, newState)
	if Enum.HumanoidStateType.Landed == newState then
		reachPeak = false
		isFalling = false
		IsLanded = true

		if not startFallY then return end -- if startFallY is empty exist the entire function
		local fallDistance = startFallY - hrp.Position.Y
		print("fallDistance:", fallDistance)
		if fallDistance >= 600 then
			FallDamage:FireServer() --auto passed player to the server side
		end
		startFallY = nil
	elseif Enum.HumanoidStateType.Jumping == newState then
		--numPressed += 1
		UpdateMuscle:FireServer(numPressed)
		IsLanded = false
		--UpdateJumpHeight:FireServer(numPressed)
		startFallY = hrp.Position.Y
		print("Jumping:", startFallY)

	elseif Enum.HumanoidStateType.Freefall == newState then
		IsLanded = false
		if not startFallY then
			startFallY = hrp.Position.Y
		end
	end

end

humanoid.StateChanged:Connect(onStateChanged)

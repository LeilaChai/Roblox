--!strict
-- M1 client entry point.

local JumpController = require(script.Parent:WaitForChild("JumpController"))
local HUD = require(script.Parent:WaitForChild("HUD"))

HUD.start()
JumpController.start()

print("[Leap of Legends] M1 client ready.")

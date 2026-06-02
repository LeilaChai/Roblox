--!strict
-- M1 client entry point.

local ChargeJump = require(script.Parent:WaitForChild("ChargeJump"))
local HUD = require(script.Parent:WaitForChild("HUD"))

HUD.start()
ChargeJump.start()

print("[Leap of Legends] M1 client ready.")

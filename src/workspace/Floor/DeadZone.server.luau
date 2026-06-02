local KillZone = script.Parent

KillZone.Touched:Connect(function(otherPart)
	local humanoid = otherPart.Parent:FindFirstChild("Humanoid")

	if humanoid then
		humanoid.Health = 0
	end
end)

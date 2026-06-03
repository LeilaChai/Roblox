--!strict
-- Lazily creates (server) / waits for (client) the RemoteEvents used by the game.
-- Require this from either side and access Remotes.<Name>.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local function getFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder :: Folder
	else
		return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
	end
end

local folder = getFolder()

local function event(name: string): RemoteEvent
	if RunService:IsServer() then
		local e = folder:FindFirstChild(name)
		if not e then
			e = Instance.new("RemoteEvent")
			e.Name = name
			e.Parent = folder
		end
		return e :: RemoteEvent
	else
		return folder:WaitForChild(name) :: RemoteEvent
	end
end

local Remotes = {
	-- Client -> Server: a jump "press" tick (grows LegPower).
	RequestJump = event("RequestJump"),
	-- Server -> Client: you got stomped — get knocked down. (pushSpeed, stunSeconds)
	Stomped = event("Stomped"),
}

return Remotes

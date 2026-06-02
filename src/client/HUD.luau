--!strict
-- Simple stats HUD: Height, LegPower, Leap Coins, and best height.
-- Reads replicated Player attributes set by the server.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local HUD = {}

local function makeLabel(parent: Instance, order: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, 26)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
	label.Parent = parent
	return label
end

function HUD.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "StatsHud"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0, 0)
	holder.Position = UDim2.new(0, 16, 0, 16)
	holder.Size = UDim2.new(0, 260, 0, 120)
	holder.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	holder.BackgroundTransparency = 0.35
	holder.BorderSizePixel = 0
	holder.Parent = gui

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 8)
	pad.Parent = holder

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = holder

	local height = makeLabel(holder, 1, Color3.fromRGB(255, 255, 255))
	local best = makeLabel(holder, 2, Color3.fromRGB(180, 200, 255))
	local legPower = makeLabel(holder, 3, Color3.fromRGB(255, 210, 140))
	local coins = makeLabel(holder, 4, Color3.fromRGB(120, 230, 150))
	local hint = makeLabel(holder, 5, Color3.fromRGB(150, 150, 160))
	hint.TextSize = 14
	hint.Font = Enum.Font.Gotham
	hint.Text = "Hold SPACE to keep jumping — watch your jump time!"

	local function refresh()
		height.Text = string.format("Height: %d", (player:GetAttribute("Height") :: number?) or 0)
		best.Text = string.format("Best: %d", (player:GetAttribute("MaxHeight") :: number?) or 0)
		legPower.Text = string.format("LegPower: %d", (player:GetAttribute("LegPower") :: number?) or 0)
		coins.Text = string.format("Leap Coins: %d", (player:GetAttribute("LeapCoins") :: number?) or 0)
	end

	for _, attr in ipairs({ "Height", "MaxHeight", "LegPower", "LeapCoins" }) do
		player:GetAttributeChangedSignal(attr):Connect(refresh)
	end
	refresh()
end

return HUD

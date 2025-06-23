local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local AttackRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ActivateMove")

local keybinds = {
	Q = Enum.KeyCode.Q,
	E = Enum.KeyCode.E,
	R = Enum.KeyCode.R,
	F = Enum.KeyCode.F,
	T = Enum.KeyCode.T,
	G = Enum.KeyCode.G
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local AttackRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ActivateMove")
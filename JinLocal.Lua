local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local AttackRemote = ReplicatedStorage:WaitForChild("pressed key")
local HoldingE = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	local key = input.KeyCode
	if key == Enum.KeyCode.R then
		AttackRemote:FireServer("R")
	else if key == Enum.KeyCode.E then
		AttackRemote:FireServer("E")
		end			
	end
end)


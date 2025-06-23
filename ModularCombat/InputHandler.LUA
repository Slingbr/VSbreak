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

local function onAbilityInput(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return end

	if actionName == "F" then
		local mousePos = mouse.Hit.Position
		AttackRemote:FireServer("F", mousePos)
	else
		AttackRemote:FireServer(actionName)
	end
end


for name, key in pairs(keybinds) do
	ContextActionService:BindAction(name, onAbilityInput, false, key)
end

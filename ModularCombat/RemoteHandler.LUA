
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActivateMoveRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ActivateMove")


local MoveHandler = require(game.ServerScriptService:WaitForChild("combat"):WaitForChild("MoveHandler"))

ActivateMoveRemote.OnServerEvent:Connect(function(player, moveKey, inputData)
	if typeof(moveKey) ~= "string" then return end

	local success, err = pcall(function()
		MoveHandler:Execute(player, moveKey, inputData)
	end)

	if not success then
		warn("Failed to execute move for " .. player.Name .. ": " .. tostring(err))
	end
end)

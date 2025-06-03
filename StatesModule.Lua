local StateModule = {}
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local activeStates = {}

local function getCharId(char)
	return char and char:GetAttribute("CharacterId") or char
end

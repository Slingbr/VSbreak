local StateModule = {}
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local activeStates = {}

local function getCharId(char)
	return char and char:GetAttribute("CharacterId") or char
end

local function cleanup(char, state)
	if activeStates[char] then
		activeStates[char][state] = nil
		if next(activeStates[char]) == nil then
			activeStates[char] = nil
		end
	end
end

StateModule.Apply = {}
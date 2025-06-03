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


local function setHighlightFill(char, color, transparency)
	local hl = char:FindFirstChildWhichIsA("Highlight")
	if not hl then return end


	activeStates[char].HighlightBackup = activeStates[char].HighlightBackup or {
		FillColor = hl.FillColor,
		FillTransparency = hl.FillTransparency
	}

	hl.FillColor = color
	hl.FillTransparency = transparency
end


local function restoreHighlight(char)
	local hl = char:FindFirstChildWhichIsA("Highlight")
	if not hl then return end

	local backup = activeStates[char] and activeStates[char].HighlightBackup
	if backup then
		hl.FillColor = backup.FillColor
		hl.FillTransparency = backup.FillTransparency
	end
end
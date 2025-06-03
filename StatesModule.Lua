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

function StateModule.Apply.Slowed(char, duration, slowSpeed, highlightFillColor, highlightFillTransparency)
	if not char or not char:FindFirstChild("Humanoid") then return end
	local hum = char:FindFirstChild("Humanoid")

	activeStates[char] = activeStates[char] or {}
	if not activeStates[char].Slowed then
		activeStates[char].Slowed = { OriginalSpeed = hum.WalkSpeed }
		setHighlightFill(
			char,
			highlightFillColor or Color3.fromRGB(25, 25, 25),
			highlightFillTransparency or 0.25
		)
	end

	hum.WalkSpeed = slowSpeed

	task.delay(duration, function()
		if hum and hum.Parent and activeStates[char] and activeStates[char].Slowed then
			hum.WalkSpeed = activeStates[char].Slowed.OriginalSpeed
			cleanup(char, "Slowed")

			if not activeStates[char].Frozen then
				restoreHighlight(char)
			else warn("they arent highlighted")
			end
		end
	end)
end
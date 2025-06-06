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

function StateModule.Apply.Frozen(char, duration, highlightFillColor)
	if not char then return end

	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	activeStates[char] = activeStates[char] or {}
	if not activeStates[char].Frozen then
		activeStates[char].Frozen = true
		setHighlightFill(char, highlightFillColor or Color3.fromRGB(25, 25, 25), 0.25)
	end

	task.delay(duration, function()
		if char and activeStates[char] and activeStates[char].Frozen then
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
				end
			end
			cleanup(char, "Frozen")

			if not activeStates[char].Slowed then
				restoreHighlight(char)
			end
		end
	end)
end

function StateModule.Apply.Stunned(char, duration)
	if not char then return end

	activeStates[char] = activeStates[char] or {}
	activeStates[char].Stunned = true

	task.delay(duration, function()
		if char and activeStates[char] and activeStates[char].Stunned then
			cleanup(char, "Stunned")
		end
	end)
end


function StateModule.Apply.Rooted(char, duration)
	if not char or not char:FindFirstChild("Humanoid") then return end
	local hum = char:FindFirstChild("Humanoid")

	activeStates[char] = activeStates[char] or {}
	activeStates[char].Rooted = true
	hum.PlatformStand = true

	task.delay(duration, function()
		if hum and activeStates[char] and activeStates[char].Rooted then
			hum.PlatformStand = false
			cleanup(char, "Rooted")
		end
	end)
end

function StateModule.Apply.Invisible(char, duration)
	if not char then return end

	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Decal") then
			v.Transparency = 1
		end
	end

	activeStates[char] = activeStates[char] or {}
	activeStates[char].Invisible = true

	task.delay(duration, function()
		if char and activeStates[char] and activeStates[char].Invisible then
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("Decal") then
					v.Transparency = 0
				end
			end
			cleanup(char, "Invisible")
		end
	end)
end


function StateModule.Apply.CustomState(char, duration)

end


function StateModule.IsActive(char, state)
	return activeStates[char] and activeStates[char][state] ~= nil
end

return StateModule

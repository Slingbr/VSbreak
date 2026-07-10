
--// DamageHandlerService.lua
-- Character-based damage + 20s decay + HYBRID awakening (per-player progress, per-character caps/multipliers)


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RagdollModule = require(game.ServerScriptService.Modules.NewRagdollModule) 
local ProfileConnector = require(script.Parent.ProfileConnector)
local LeaderboardService = require(script.Parent.LeaderboardService)



local CombatRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatRemotes")
local OnStreak = CombatRemotes:WaitForChild("OnStreak")
local OnAwakeningReady = CombatRemotes:WaitForChild("OnAwakeningReady")

local DamageHandler = {}

local DamageData = {}     -- [targetChar][attackerChar] = {Total, LastHit, HitCount}
local StreakData = {}     -- [char] = {Count, LastKillTime}
local CombatTags = {}     -- [char] = task handle

-- Awakening (authoritative per player, mirrored to attribute for UI)
local AwakeningData = {}  -- [UserId] = progress number
local DecayThreads = {}   -- [UserId] = thread/task
local DecayActive = {}    -- [UserId] = true/false

local COMBAT_TAG_TIMEOUT = 8
local DAMAGE_DECAY_TIME = 20
local STREAK_MILESTONES = {3, 5, 10}

---------------------------------------------------------------------
-- Awakening Config (EXPOSED / TUNABLE)
-- Add your character names here. Unknown chars use defaults.
---------------------------------------------------------------------
local DEFAULT_AWAKENING_RULES = {
	Cap = 100,
	GainMultiplier = 1.0,
	DecayDuration = 12, -- used by StartAwakeningDecay if caller doesn't pass a duration
}

DamageHandler.AwakeningConfig = {

	Gon = { Cap = 100, GainMultiplier = .35, DecayDuration = 60 },
	Jinwoo = { Cap = 140, GainMultiplier = 0.4, DecayDuration = 40 },
	Vegeta = { Cap = 90, GainMultiplier = .25, DecayDuration = 45 },
	AllMight = { Cap = 5, GainMultiplier = .3, DecayDuration = 250 },
}

---------------------------------------------------------------------
-- Internal Helpers (Combat)
---------------------------------------------------------------------
local function EndCombat(character)
	if not character or not character.Parent then return end

	character:SetAttribute("InCombat", false)
	if CollectionService:HasTag(character, "InCombat") then
		CollectionService:RemoveTag(character, "InCombat")
	end

	if CombatTags[character] then
		local thread = CombatTags[character]
		if type(thread) == "thread" then
			pcall(function()
				task.cancel(thread)
			end)
		end
		CombatTags[character] = nil
	end
end

local function SetInCombat(character)
	if not character or not character.Parent then return end

	character:SetAttribute("InCombat", true)
	if not CollectionService:HasTag(character, "InCombat") then
		CollectionService:AddTag(character, "InCombat")
	end

	if CombatTags[character] then
		local thread = CombatTags[character]
		if type(thread) == "thread" then
			pcall(function()
				task.cancel(thread)
			end)
		end
	end

	CombatTags[character] = task.delay(COMBAT_TAG_TIMEOUT, function()
		EndCombat(character)
	end)
end

---------------------------------------------------------------------
-- Internal Helpers (Awakening)
---------------------------------------------------------------------
local function TriggerStreakVFX(player, count)
	OnStreak:FireClient(player, count)
end

local function TriggerAwakeningReady(player)
	OnAwakeningReady:FireClient(player)
end

local function GetCharacterName(player)
	local character = player.Character
	if not character then
		return nil
	end

	local name = character:GetAttribute("CharacterName")
	if typeof(name) == "string" and name ~= "" then
		return name
	end

	return nil
end


local function GetRulesForPlayer(player)
	local charName = GetCharacterName(player)
	if charName and DamageHandler.AwakeningConfig[charName] then
		local cfg = DamageHandler.AwakeningConfig[charName]
		return {
			Cap = cfg.Cap or DEFAULT_AWAKENING_RULES.Cap,
			GainMultiplier = cfg.GainMultiplier or DEFAULT_AWAKENING_RULES.GainMultiplier,
			DecayDuration = cfg.DecayDuration or DEFAULT_AWAKENING_RULES.DecayDuration,
		}
	end
	return DEFAULT_AWAKENING_RULES
end

local function MirrorAwakeningAttribute(player)
	local char = player.Character
	if not char then return end
	char:SetAttribute("AwakeningProgress", AwakeningData[player.UserId] or 0)
end

local function IsGainBlocked(player)
	local char = player.Character
	if not char then return true end

	-- hard rule: cannot gain while awakened
	if char:GetAttribute("Awakened") == true then
		return true
	end

	-- also block while decay is active (extra safety)
	if DecayActive[player.UserId] == true then
		return true
	end

	return false
end

local function ClampToCap(player, value)
	local rules = GetRulesForPlayer(player)
	return math.clamp(value, 0, rules.Cap)
end

local function ClearAwakeningInternal(player)
	AwakeningData[player.UserId] = 0
	MirrorAwakeningAttribute(player)
end

---------------------------------------------------------------------
-- Public API 
---------------------------------------------------------------------
function DamageHandler:ForceEndCombat(character)
	EndCombat(character)
end

---------------------------------------------------------------------
-- Leaderstats helper
---------------------------------------------------------------------
local function UpdateLeaderstats(player, kills, streak, highest)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end

	if kills then
		local k = ls:FindFirstChild("Kills")
		if k then k.Value = kills end
	end

	if streak then
		local s = ls:FindFirstChild("CurrentStreak")
		if s then s.Value = streak end
	end

	if highest then
		local h = ls:FindFirstChild("HighestStreak")
		if h then h.Value = highest end
	end
end

---------------------------------------------------------------------
-- Awakening Exposed Operations (NEW, callable hooks)
-- (These don't do permission checks; you can call them from anywhere.)
---------------------------------------------------------------------

-- Clears progress to 0 (used by: leave, character switch, death while awakened, decay end)
function DamageHandler:ClearAwakeningProgress(player)
	if not player then return end
	ClearAwakeningInternal(player)
end

-- Sets progress directly (clamped 0..cap)
function DamageHandler:SetAwakeningProgress(player, value)
	if not player then return end
	local v = ClampToCap(player, tonumber(value) or 0)
	AwakeningData[player.UserId] = v
	MirrorAwakeningAttribute(player)
end

-- One-time subtraction (silent, clamped at 0)
function DamageHandler:SubtractAwakeningProgress(player, amount)
	if not player then return end
	local a = tonumber(amount) or 0
	if a <= 0 then return end

	local current = AwakeningData[player.UserId] or 0
	local newValue = math.max(0, current - a)

	AwakeningData[player.UserId] = newValue
	MirrorAwakeningAttribute(player)
end

-- Instantly fill to cap for their current character
function DamageHandler:MaxAwaken(player)
	if not player then return end
	local rules = GetRulesForPlayer(player)
	AwakeningData[player.UserId] = rules.Cap
	MirrorAwakeningAttribute(player)
	TriggerAwakeningReady(player)
end

-- Returns true if progress is at cap for current character
function DamageHandler:IsAwakeningReady(player)
	if not player then return false end
	local rules = GetRulesForPlayer(player)
	return (AwakeningData[player.UserId] or 0) >= rules.Cap
end

-- Starts unstoppable decay to 0 over duration (only intended to be called when awakening is activated).
-- Decay updates the SAME AwakeningProgress value down to 0, then flips Awakened false.
function DamageHandler:StartAwakeningDecay(player, duration)
	if not player then return end
	local userId = player.UserId

	if DecayActive[userId] then
		-- already running; unstoppable; ignore
		return
	end

	local rules = GetRulesForPlayer(player)
	local totalTime = tonumber(duration) or rules.DecayDuration
	if totalTime <= 0 then totalTime = rules.DecayDuration end

	DecayActive[userId] = true

	-- store thread handle so you can introspect if needed; we do NOT cancel (unstoppable)
	local thread = task.spawn(function()
		local start = os.clock()
		local last = start

		while true do
			local now = os.clock()
			local dt = now - last
			last = now

			local current = AwakeningData[userId] or 0
			if current <= 0 then
				-- finish
				AwakeningData[userId] = 0
				MirrorAwakeningAttribute(player)

				-- End awakened state if character exists
				local char = player.Character
				if char then
					char:SetAttribute("Awakened", false)
				end

				DecayActive[userId] = nil
				DecayThreads[userId] = nil
				break
			end

			-- linear decay rate to reach 0 at totalTime
			local rate = (rules.Cap / totalTime) -- "cap per second" baseline
			-- But decay should be based on current value, not cap, to guarantee totalTime from full.
			-- If player starts decay at less than cap, it will end sooner; that's fine.
			local dec = rate * dt

			local newValue = math.max(0, current - dec)
			AwakeningData[userId] = newValue
			MirrorAwakeningAttribute(player)

			task.wait(0.05)
		end
	end)

	DecayThreads[userId] = thread
end

---------------------------------------------------------------------
-- Existing awakening getters 
---------------------------------------------------------------------
function DamageHandler:GetAwakeningDamage(player)
	if not player then return 0 end
	return AwakeningData[player.UserId] or 0
end


-- Interpreted as "force add awakening progress by a raw amount" (NOT multiplied),
-- still clamped to cap, and still blocked while awakened/decaying.
function DamageHandler:IncrementAwakeningDamage(player, amount)
	if not player then return end
	local a = tonumber(amount) or 0
	if a <= 0 then return end

	if IsGainBlocked(player) then return end

	local current = AwakeningData[player.UserId] or 0
	local newValue = ClampToCap(player, current + a)

	AwakeningData[player.UserId] = newValue
	MirrorAwakeningAttribute(player)

	if self:IsAwakeningReady(player) then
		TriggerAwakeningReady(player)
	end
end

---------------------------------------------------------------------
-- Damage Logic
---------------------------------------------------------------------
function DamageHandler:RegisterDamage(attackerChar, targetChar, amount, options)
	if not attackerChar or not targetChar or attackerChar == targetChar then return end

	-- Default options table if none provided
	options = options or { CanDown = false }

	local attackerHum = attackerChar:FindFirstChildOfClass("Humanoid")
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not targetHum or targetHum.Health <= 0 then return end
	if not attackerHum then return end

	-- Tag both as in combat
	SetInCombat(attackerChar)
	SetInCombat(targetChar)

	--  THE INTERCEPT 
	local willDie = (targetHum.Health - amount) <= 0

	if willDie then
		if options.CanDown and targetChar:GetAttribute("State") ~= "Downed" then
			-- BRANCH A: The setup for an execution (1 HP Godmode)
			targetHum.Health = 1
			targetChar:SetAttribute("State", "Downed")

			-- Force them into a ragdoll
			RagdollModule.Enable(targetChar)

			-- 5-Second Bleedout Timer
			task.delay(5, function()
				if targetChar and targetChar.Parent and targetChar:GetAttribute("State") == "Downed" then
					local hum = targetChar:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.Health = 0 -- Timer ran out, actually kill them
					end
				end
			end)

			-- Return EARLY so we don't process the kill credit yet
			return 
		else
			-- BRANCH B: Actual Death (Body completely destroyed or Bleedout)
			-- We ragdoll them right before they die so their corpse stays intact for the ghost body swap
			targetHum.BreakJointsOnDeath = false
		--	targetHum.RequiresNeck = false
			RagdollModule.Enable(targetChar)

			targetHum:TakeDamage(amount)
		end
	else
		-- BRANCH C: Normal Damage
		targetHum:TakeDamage(amount)
	end

	-- Create or update damage tracking entry
	DamageData[targetChar] = DamageData[targetChar] or {}
	local entry = DamageData[targetChar][attackerChar]

	if not entry then
		entry = { Total = 0, LastHit = os.clock(), HitCount = 0 }
		DamageData[targetChar][attackerChar] = entry
	else
		entry.LastHit = os.clock()
	end

	entry.Total += amount
	entry.HitCount += 1

	-- Awakening gain: derived from damage (multiplied by character rules), clamped, blocked while awakened/decaying
	local attackerPlayer = Players:GetPlayerFromCharacter(attackerChar)
	if attackerPlayer and not IsGainBlocked(attackerPlayer) then
		local rules = GetRulesForPlayer(attackerPlayer)

		local current = AwakeningData[attackerPlayer.UserId] or 0
		local gain = amount * (rules.GainMultiplier or 1)
		local newValue = math.clamp(current + gain, 0, rules.Cap)

		AwakeningData[attackerPlayer.UserId] = newValue
		MirrorAwakeningAttribute(attackerPlayer)

		if newValue >= rules.Cap then
			TriggerAwakeningReady(attackerPlayer)
		end
	end

	-- Optional: clean up expired attackers (no hits for 20s)
	for recordedAttacker, data in pairs(DamageData[targetChar]) do
		if os.clock() - data.LastHit > DAMAGE_DECAY_TIME then
			DamageData[targetChar][recordedAttacker] = nil
		end
	end
end

function DamageHandler:GetDamageBetween(attackerChar, targetChar)
	if DamageData[targetChar] and DamageData[targetChar][attackerChar] then
		return DamageData[targetChar][attackerChar].Total
	end
	return 0
end

---------------------------------------------------------------------
-- Cleanup Loop (remove stale damage after 20s inactivity)
---------------------------------------------------------------------
task.spawn(function()
	while true do
		for targetChar, attackers in pairs(DamageData) do
			for attackerChar, data in pairs(attackers) do
				if os.clock() - data.LastHit > DAMAGE_DECAY_TIME then
					attackers[attackerChar] = nil
				end
			end
			if next(attackers) == nil then
				DamageData[targetChar] = nil
			end
		end
		task.wait(5)
	end
end)

---------------------------------------------------------------------
-- Kill Handling
---------------------------------------------------------------------
function DamageHandler:ResetLife(targetPlayer)
	local targetChar = targetPlayer.Character
	if not targetChar then return end

	-- Hybrid persistence: only reset awakening on death IF they were awakened
	if targetChar:GetAttribute("Awakened") == true then
		self:ClearAwakeningProgress(targetPlayer)
	end

	if CollectionService:HasTag(targetChar, "Dummy") then
		DamageData[targetChar] = nil
		return
	end

	local targetData = DamageData[targetChar]
	local killerChar
	local maxDamage = 0

	if targetData then
		for attackerChar, data in pairs(targetData) do
			if data.Total > maxDamage then
				maxDamage = data.Total
				killerChar = attackerChar
			end
		end
	end

	DamageData[targetChar] = nil

	if killerChar and killerChar ~= targetChar then
		local killerPlayer = Players:GetPlayerFromCharacter(killerChar)
		if killerPlayer then
			ProfileConnector:AddKill(killerPlayer)
			ProfileConnector:AddStreak(killerPlayer)
			ProfileConnector:ResetStreak(targetPlayer)

			local streakCount = (StreakData[killerChar] and StreakData[killerChar].Count or 0) + 1
			StreakData[killerChar] = { Count = streakCount, LastKillTime = os.clock() }

			for _, milestone in ipairs(STREAK_MILESTONES) do
				if streakCount == milestone then
					TriggerStreakVFX(killerPlayer, streakCount)
					break
				end
			end

			StreakData[targetChar] = nil

			UpdateLeaderstats(
				killerPlayer,
				ProfileConnector:GetKills(killerPlayer),
				streakCount,
				ProfileConnector:GetHighestStreak(killerPlayer)
			)
			UpdateLeaderstats(targetPlayer, nil, 0, nil)

			LeaderboardService:RefreshPlayer(killerPlayer)
			LeaderboardService:RefreshPlayer(targetPlayer)
		end
	end
end

---------------------------------------------------------------------
-- Player Leaving (always clear awakening)
---------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	DamageHandler:ClearAwakeningProgress(player)
	DecayActive[player.UserId] = nil
	DecayThreads[player.UserId] = nil
	-- We intentionally do NOT cancel threads; they will end naturally once progress is 0.
end)

---------------------------------------------------------------------
-- Character / Player Connections
---------------------------------------------------------------------
local function CreateAwakeningAttribute(player, character)
	local awakeningVal = DamageHandler:GetAwakeningDamage(player)
	character:SetAttribute("AwakeningProgress", awakeningVal or 0)
	-- fresh body is never awakened by default
	character:SetAttribute("Awakened", false)
end

local function OnCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Stop them from breaking into pieces when Health hits 0
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	CreateAwakeningAttribute(player, character)

	humanoid.Died:Connect(function()
		DamageHandler:ResetLife(player)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(OnCharacterAdded)
	if player.Character then
		OnCharacterAdded(player.Character)
	end
end)


-- Add this near your other Remotes at the top of the script
local ResetRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ResetRemote")

-- The new function to handle voluntary resets
function DamageHandler:HandleReset(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- If they are already downed, resetting again should just kill them immediately to prevent trapping
	if character:GetAttribute("State") == "Downed" then
		humanoid.Health = 0
		return
	end

	-- Apply the "Downed" State
	humanoid.Health = 1
	character:SetAttribute("State", "Downed")

	-- Force the Ragdoll
	local RagdollModule = require(game.ServerScriptService.Modules.NewRagdollModule) -- Ensure path is correct
	RagdollModule.Enable(character)

	-- 4-Second Bleedout Timer
	task.delay(3, function()
		if character and character.Parent and character:GetAttribute("State") == "Downed" then
			local hum = character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Health = 0 -- Times up, actually die
			end
		end
	end)
end

-- Connect the remote
ResetRemote.OnServerEvent:Connect(function(player)
	DamageHandler:HandleReset(player)
end)
---------------------------------------------------------------------
return DamageHandler

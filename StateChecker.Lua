
-- location is child of StateMachineModule
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local SMRegistry = require(SSS.Loaders.StateMachineRegistry) 
local StateMachineModule = require(SSS.Modules.StateMachineModule) 

local StateChecker = {}


local StateAttributes = {
	[StateMachineModule.States.Idle]        = { Hittable = true, Stunnable = true },
	[StateMachineModule.States.Running]     = { Hittable = true, Stunnable = true },
	[StateMachineModule.States.Dashing]     = { Hittable = false, Stunnable = false, IFrame = true },
	[StateMachineModule.States.Blocking]    = { Hittable = false, Stunnable = false, IsBlocking = true },
	[StateMachineModule.States.Iframes]     = { Hittable = false, Stunnable = false, IFrame = true },
	[StateMachineModule.States.Ragdolled]   = { Hittable = true, Stunnable = true, IsDowned = true },
	[StateMachineModule.States.Stunned]     = { Hittable = true, Stunnable = true, IsStunned = true },
	[StateMachineModule.States.Clashing]    = { Hittable = false, Stunnable = false },
	[StateMachineModule.States.Ultimating]  = { Hittable = false, Stunnable = false, HyperArmor = true },
	[StateMachineModule.States.Grabbed] = { Hittable = false, Stunnable = false, IsGrabbed = true },
	[StateMachineModule.States.AbsoluteInvincibility] = { Hittable = false, Stunnable = false, IsAbsoluteInvincible = true },

}

local function GetFlags(stateId)
	return StateAttributes[stateId] or { Hittable = true, Stunnable = true }
end

local function ResolveTarget(targetCharacter)
	local player = Players:GetPlayerFromCharacter(targetCharacter)
	if player then
		local sm = SMRegistry:Get(player)
		if sm then return true, sm end
	end
	return false, targetCharacter
end

--  CHECKER FUNCTIONS

-- CanBeHit: Checks Blocking & Iframes
function StateChecker:CanBeHit(targetCharacter, options)
	options = options or {}
	local isPlayer, data = ResolveTarget(targetCharacter)

	local isAbsoluteInvincible = false
	local isGrabbed  = false
	local isBlocking = false
	local isIFrame   = false

	if isPlayer then
		local activeStates = data:GetState("All")
		for _, stateId in pairs(activeStates) do
			local flags = GetFlags(stateId)
			if flags.IsAbsoluteInvincible then isAbsoluteInvincible = true end
			if flags.IsGrabbed            then isGrabbed            = true end
			if flags.IsBlocking           then isBlocking           = true end
			if flags.IFrame               then isIFrame             = true end
		end
	else
		if data:GetAttribute("IsAbsoluteInvincible") then isAbsoluteInvincible = true end
		if data:GetAttribute("IsBeingGrabbed")       then isGrabbed            = true end
		if data:GetAttribute("IsBlocking")           then isBlocking           = true end
		if data:GetAttribute("Iframes")              then isIFrame             = true end
	end

	-- HardDown is attribute-based, checked on character directly for both players and NPCs
	-- Feeds into IFrame tier so IgnoreIframes moves can still follow up on downed players
	if targetCharacter:GetAttribute("HardDown") then isIFrame = true end

	-- Tier 1: Un-ignorable
	if isAbsoluteInvincible then return false end
	if isGrabbed            then return false end

	-- Tier 2: Ignorable
	if isIFrame   and not options.IgnoreIframes then return false end
	if isBlocking and not options.IgnoreBlock   then return false end

	return true
end
-- CanBeStunned: Checks Visual HyperArmor only
function StateChecker:CanBeStunned(targetCharacter, options)
	options = options or {}
	local isPlayer, data = ResolveTarget(targetCharacter)
	
	local isGrabbed  = false
	local isBlocking = false
	local hasHyperArmor = false
	local isIFrame = false
	local isAbsoluteInvincible = false

	if isPlayer then
		local activeStates = data:GetState("All")
		for _, stateId in pairs(activeStates) do
			local flags = GetFlags(stateId)
			if flags.IsAbsoluteInvincible then isAbsoluteInvincible = true end
			if flags.IsGrabbed  then isGrabbed  = true end
			if flags.IsBlocking then isBlocking = true end
			if flags.HyperArmor then hasHyperArmor = true end
			if flags.IFrame then isIFrame = true end
		end
	else
		if data:GetAttribute("IsAbsoluteInvincible") then isAbsoluteInvincible = true end
		if data:GetAttribute("IsBeingGrabbed") then isGrabbed  = true end
		if data:GetAttribute("IsBlocking") then isBlocking = true end
		if data:GetAttribute("HyperArmor") then hasHyperArmor = true end
		if data:GetAttribute("Iframes") then isIFrame = true end
	end
	
	if isAbsoluteInvincible then return false end
	if isGrabbed then return false end
	
	if isIFrame and not options.IgnoreIframes then return false end
	if isBlocking and not options.BreakBlock then return false end
	if hasHyperArmor and not options.BreakArmor then return false end

	return true
end

-- Force sets the victim into Grabbed state, preventing any other attacker from initiating
function StateChecker:SetGrabbed(targetCharacter)
	local isPlayer, data = ResolveTarget(targetCharacter)
	if isPlayer then
		data:SetState("CombatState", StateMachineModule.States.Grabbed, false, false)
	else
		targetCharacter:SetAttribute("IsBeingGrabbed", true)
	end
end

-- Force clears the Grabbed state
function StateChecker:ClearGrabbed(targetCharacter)
	local isPlayer, data = ResolveTarget(targetCharacter)
	if isPlayer then
		-- Only clear if they are actually still in Grabbed, avoids stomping a state
		-- that got set by something else during the grab resolution
		if data:GetState("CombatState") == StateMachineModule.States.Grabbed then
			data:SetState("CombatState", 0, false, false)
		end
	else
		targetCharacter:SetAttribute("IsBeingGrabbed", false)
	end
end

function StateChecker:SetAbsoluteInvincibility(targetCharacter)
	local isPlayer, data = ResolveTarget(targetCharacter)
	if isPlayer then
		data:SetState("CombatState", StateMachineModule.States.AbsoluteInvincibility, false, false)
	else
		targetCharacter:SetAttribute("IsAbsoluteInvincible", true)
	end
end

function StateChecker:ClearAbsoluteInvincibility(targetCharacter)
	local isPlayer, data = ResolveTarget(targetCharacter)
	if isPlayer then
		if data:GetState("CombatState") == StateMachineModule.States.AbsoluteInvincibility then
			data:SetState("CombatState", 0, false, false)
		end
	else
		targetCharacter:SetAttribute("IsAbsoluteInvincible", false)
	end
end


function StateChecker:IsStunned(targetCharacter)
	local isPlayer, data = ResolveTarget(targetCharacter)

	if isPlayer then
		local activeStates = data:GetState("All")
		for _, stateId in pairs(activeStates) do
			local flags = GetFlags(stateId)
			if flags.IsStunned then return true end
		end
	else
		-- NPC check
		if data:GetAttribute("IsStunned") then return true end
	end

	return false
end

return StateChecker

local SSS = game:GetService("ServerScriptService")
local Rules = require(SSS.Modules.StateMachineRules)

local StateMachine = {}



StateMachine.States = {
	Idle               = 0,
	Running            = 1,
	Dashing            = 2,
	WallHopping        = 3,
	Climbing           = 4,
	Punching           = 5,
	Blocking           = 6,
	Clashing           = 7,
	Ultimating         = 8,
	Ragdolled          = 9,
	Stunned            = 10,
	Iframes            = 11,
	Tilting            = 12,
	Action             = 13,
	WallRunning        = 14,
	ClashingAir        = 15,
	ClashingEscape     = 16,
	ClashingEscapeAir  = 17,
	Interrupt		   = 18,
	Grabbed 		   = 20,
	AbsoluteInvincibility = 21,
}

StateMachine.StateNames = {
	[0]  = "Idle",
	[1]  = "Running",
	[2]  = "Dashing",
	[3]  = "WallHopping",
	[4]  = "Climbing",
	[5]  = "Punching",
	[6]  = "Blocking",
	[7]  = "Clashing",
	[8]  = "Ultimating",
	[9]  = "Ragdolled",
	[10] = "Stunned",
	[11] = "Iframes",
	[12] = "Tilting",
	[13] = "Action",
	[14] = "WallRunning",
	[15] = "ClashingAir",
	[16] = "ClashingEscape",
	[17] = "ClashingEscapeAir",
	[18] = "Interrupt",
	[20] = "Grabbed",
	[21] = "AbsoluteInvincibility",
	
}

local allowedTransitions = {
	[StateMachine.States.Idle] = {
		[StateMachine.States.Idle]        = true,
		[StateMachine.States.Running]     = true,
		[StateMachine.States.Dashing]     = true,
		[StateMachine.States.WallRunning] = true,
		[StateMachine.States.WallHopping] = true,
		[StateMachine.States.Climbing]    = true,
		[StateMachine.States.Punching]    = true,
		[StateMachine.States.Blocking]    = true,
		[StateMachine.States.Ultimating]  = true,
		[StateMachine.States.Stunned]     = true,
		[StateMachine.States.Iframes]     = true,
		[StateMachine.States.Action]      = true,
	},

	[StateMachine.States.Running] = {
		[StateMachine.States.Punching]    = true,
		[StateMachine.States.Blocking]    = true,
		[StateMachine.States.Idle]        = true,
		[StateMachine.States.Dashing]     = true,
		[StateMachine.States.WallRunning] = true,
		[StateMachine.States.WallHopping] = true,
		[StateMachine.States.Climbing]    = true,
		[StateMachine.States.Action]      = true,
		[StateMachine.States.Stunned]     = true,
	},

	[StateMachine.States.Dashing] = {
		[StateMachine.States.Idle]    = true,
		[StateMachine.States.Running] = true,
		[StateMachine.States.Stunned] = true,
		[StateMachine.States.Blocking] = true,
	},

	[StateMachine.States.WallRunning] = {
		[StateMachine.States.Idle]        = true,
		[StateMachine.States.Running]     = true,
		[StateMachine.States.WallHopping] = true,
		[StateMachine.States.ClashingAir] = true,
		[StateMachine.States.Stunned]     = true,
	},

	[StateMachine.States.WallHopping] = {
		[StateMachine.States.WallRunning] = true,
		[StateMachine.States.Idle]        = true,
		[StateMachine.States.Running]     = true,
		[StateMachine.States.ClashingAir] = true,
		[StateMachine.States.Stunned]     = true,
	},

	[StateMachine.States.Climbing] = {
		[StateMachine.States.Idle]    = true,
		[StateMachine.States.Running] = true,
		[StateMachine.States.Stunned] = true,
	},

	[StateMachine.States.Punching] = {
		[StateMachine.States.Idle] = true,
		[StateMachine.States.Punching] = true,
		[StateMachine.States.Stunned] = true,
		[StateMachine.States.Dashing] = true,
	},

	[StateMachine.States.Blocking] = {
		[StateMachine.States.Idle] = true,
		[StateMachine.States.Stunned] = true,
	},

	-- Only allowed to go into Escape
	[StateMachine.States.Clashing] = {
		[StateMachine.States.ClashingEscape] = true,
		[StateMachine.States.Stunned] = true,
	},

	[StateMachine.States.ClashingAir] = {
		[StateMachine.States.ClashingEscapeAir] = true,
		[StateMachine.States.Stunned] = true,
	},

	-- Escapes only allowed into Dashing
	[StateMachine.States.ClashingEscape] = {
		[StateMachine.States.Dashing] = true,
		[StateMachine.States.Stunned] = true,
	},

	[StateMachine.States.ClashingEscapeAir] = {
		[StateMachine.States.Dashing] = true,
		[StateMachine.States.Stunned] = true,
	},

	[StateMachine.States.Ultimating] = {
		[StateMachine.States.Idle]    = true,
		[StateMachine.States.Stunned] = true,
		[StateMachine.States.Iframes] = true,
	},

	[StateMachine.States.Iframes] = {
		[StateMachine.States.Idle] = true,
		[StateMachine.States.Stunned] = true,
	},

	[StateMachine.States.Ragdolled] = {
		[StateMachine.States.Idle] = true,
		[StateMachine.States.Stunned] = true,
	},

	[StateMachine.States.Stunned] = {
		[StateMachine.States.Idle]        = true,
		[StateMachine.States.Running]     = true,
		[StateMachine.States.Dashing]     = true,
		[StateMachine.States.WallRunning] = true,
		[StateMachine.States.WallHopping] = true,
		[StateMachine.States.Climbing]    = true,
		[StateMachine.States.Punching]    = true,
		[StateMachine.States.Blocking]    = true,
		[StateMachine.States.Iframes]     = true,
		[StateMachine.States.Action]      = true,
	},

	[StateMachine.States.Tilting] = {
		[StateMachine.States.Idle]    = true,
		[StateMachine.States.Dashing] = true,
		[StateMachine.States.Stunned] = true,
	},

	[StateMachine.States.Action] = {
		[StateMachine.States.Idle] = true,
		[StateMachine.States.Dashing] = true,
	},
}


function StateMachine.new(user)

	local user = user
	local isInterruptible = false
	local interrupted = false
	local actionList = {} -- Allows tracking of upto 10 previous moves
	local OnStateChanged = Instance.new("BindableEvent")
	
	local currentState = {
		["ActionState"]    = { value = 0, version = 0 },
		["CombatState"]    = { value = 0, version = 0 },
		["MovementState"]  = { value = 0, version = 0 },
		["InterruptState"] = { value = 0, version = 0 },
		["StunState"]      = { value = 0, version = 0 },
	}
	
	local function CanTransition(self, toState)
		
		-- If a person is stunned then cannot transition
		if currentState["StunState"] == 10 then print("User is still stunned. ") return false end
		
		-- Check if transition is allowed from the current state (movement/combat)
		local currentMovementState = currentState["MovementState"].value
		local currentCombatState   = currentState["CombatState"].value
		local currentActionState   = currentState["ActionState"].value
		local groupedStates = {currentMovementState, currentCombatState, currentActionState}

		-- Get allowed transitions for the current states (movement and combat)
		local allowedForMovement = allowedTransitions[currentMovementState]
		local allowedForCombat   = allowedTransitions[currentCombatState]
		local allowedForAction   = allowedTransitions[currentActionState] --May need it later
		
		if Rules:Check(self.user, groupedStates, toState) == true then
			return true
		elseif Rules:Check(self.user, groupedStates, toState) == false then
			return false
		end

		-- If no transitions are allowed for either state, return false
		if not allowedForMovement or not allowedForCombat or not allowedForAction then
			return false
		end

		-- Check if transition to the new state is allowed in both movement and combat
		if allowedForMovement[toState] == nil or allowedForCombat[toState] == nil or allowedForAction[toState] == nil then
			print(string.format(
				"toState: %s | movementState: %s | combatState: %s | actionState: %s",
				tostring(toState),
				tostring(currentMovementState),
				tostring(currentCombatState),
				tostring(currentActionState)
				))
			return false
		end
		-- If all checks pass, transition is allowed
		return true
	end


	local function GetState(self, requiredCategory: string)
		-- enforce required parameter
		assert(requiredCategory, "You must provide a requiredCategory:string")

		if requiredCategory == "All" then
			-- return a copy of the full state table (only values, not versions)
			local states = {}
			for category, entry in pairs(currentState) do
				states[category] = entry.value
			end
			return states
		else
			local entry = currentState[requiredCategory]
			if not entry then
				warn("[StateMachine] Tried to GetState for invalid category:", requiredCategory)
				return nil
			end
			return entry.value
		end
	end
	
	local function GetVersion(self, category:string)
		local entry = currentState[category]
		if not entry then 
			warn("[StateMachine] Tried to GetVersion for unknown category:", category)
			return 0
		end
		return entry.version
	end

	local function SetState(self, requiredCategory:string, toState:number, all:boolean, versionIDCheck:boolean, referenceVersion:number)
		local entry = currentState[requiredCategory]
		if not entry then
			warn("[StateMachine] Tried to SetState on invalid category:", requiredCategory)
			return
		end

		local oldStates = currentState

		-- optional version check
		if versionIDCheck then
			if referenceVersion ~= entry.version then
				print(string.format(
					"[StateMachine] Version mismatch in %s (expected %d, got %d)",
					requiredCategory, referenceVersion, entry.version
					)) --[[If you get this error chances are you got it because
						a versionID check happened and another state happened
						before this (allowed state)]]--
				return false
			end
		end

		-- special logic for InterruptState
		if requiredCategory == "InterruptState" and referenceVersion then
			entry.version = referenceVersion
		else
			entry.version += 1
		end

		-- set all categories at once (rarely used, e.g. hard reset)
		if all == true then
			for cat, data in pairs(currentState) do
				data.value = toState
				if cat ~= "InterruptState" then
					data.version += 1
				end
				if OnStateChanged then
					OnStateChanged:Fire(cat, oldStates, toState, true)
				end
			end
		else
			entry.value = toState
			if requiredCategory ~= "InterruptState" then
				entry.version += 1
			end
			if OnStateChanged then
				OnStateChanged:Fire(requiredCategory, oldStates, toState, true)
			end
		end
	end

	
	local function TrySetState(self, requiredCategory:string, toState:number, versionIDCheck:boolean, referenceVersion:number)
		local entry = currentState[requiredCategory]
		if not entry then
			warn("[StateMachine] Tried to TrySetState on invalid category:", requiredCategory)
			return false
		end

		local canTransition = CanTransition(self, toState)
		if not canTransition then
			print(string.format(
				"[StateMachine] Transition not allowed from %s → %s",
				StateMachine.StateNames[entry.value],
				StateMachine.StateNames[toState]
				))
			return false
		end

		-- do version check if requested
		if versionIDCheck and referenceVersion ~= entry.version then
			print(string.format(
				"[StateMachine] Version mismatch in %s (expected %d, got %d)",
				requiredCategory, referenceVersion, entry.version
				))
			return false
		end

		-- update
		local oldState = entry.value
		entry.value = toState
		entry.version += 1

		print(string.format(
			"[StateMachine] %s transitioned %s → %s (v%d)",
			requiredCategory,
			StateMachine.StateNames[oldState],
			StateMachine.StateNames[toState],
			entry.version
			))

		if OnStateChanged then
			OnStateChanged:Fire(requiredCategory, oldState, toState, true)
		end

		return true
	end
	
	 local function SetInterrupted(self, flag:boolean)
		
		interrupted = flag and true or false
		return interrupted
	end

	return {
		CanTransition   = CanTransition,
		GetState        = GetState,
		SetState        = SetState,
		GetVersion      = GetVersion,
		user            = user,
		OnStateChanged  = OnStateChanged,
		SetInterrupted = SetInterrupted,
	}

end

return StateMachine

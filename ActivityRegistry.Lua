-- this is where all non state machine specifics will pass through, so the game knows specifically what someone is doing and the involved instances.Moves can be cancelled.countered and functions called based on cancellation/ on counters.
-- Location: ServerScriptService.Modules.ActivityRegistry
local Players = game:GetService("Players")

local ActiveMoveRegistry = {}

-- Registry[key] = { Poise = number, Cancel = function, OnCounter = function, MoveName = string }
-- key is either a Player or a character Model (for NPCs)
local Registry = {}

local function resolveKey(entity)
	if not entity then return nil end

	if entity:IsA("Player") then
		return entity
	end

	local player = Players:GetPlayerFromCharacter(entity)
	return player or entity
end

function ActiveMoveRegistry:Register(entity, moveData)
	if not entity then return end

	local key = resolveKey(entity)
	if not key then return end

	local activeMove = Registry[key]
	if activeMove and activeMove.Cancel then
		activeMove.Cancel()
	end

	Registry[key] = {
		Poise     = moveData.Poise or 0,
		Cancel    = moveData.Cancel,
		OnCounter = moveData.OnCounter,
		MoveName  = moveData.Name or "Unknown"
	}
end

function ActiveMoveRegistry:Update(entity, newData)
	if not entity then return end

	local key = resolveKey(entity)
	if not key then return end

	local current = Registry[key]
	if current then
		if newData.Poise        then current.Poise     = newData.Poise     end
		if newData.Cancel       then current.Cancel    = newData.Cancel    end
		if newData.OnCounter ~= nil then current.OnCounter = newData.OnCounter end
		if newData.Name         then current.MoveName  = newData.Name      end
	end
end

function ActiveMoveRegistry:Clear(entity, specificCancelFunc)
	if not entity then return end

	local key = resolveKey(entity)
	if not key then return end

	local current = Registry[key]
	if current and current.Cancel == specificCancelFunc then
		Registry[key] = nil
	end
end

function ActiveMoveRegistry:Get(entity)
	if not entity then return nil end

	local key = resolveKey(entity)
	if not key then return nil end

	return Registry[key]
end

function ActiveMoveRegistry:GetFromCharacter(character)
	if not character then return nil end

	local key = resolveKey(character)
	if not key then return nil end

	return Registry[key]
end

--[[
	HANDLE INTERRUPT:
	victimEntity           — the victim, either a Player or character Model
	attackerInterruptPower — the attacker's interrupt power value
	attackerEntity         — optional, the attacker's character Model or Player
	                         passed through to OnCounter so the counter move
	                         knows exactly who hit them
]]
function ActiveMoveRegistry:HandleInterrupt(victimEntity, attackerInterruptPower, attackerEntity)
	if not victimEntity then return "NothingRegistered" end

	local key = resolveKey(victimEntity)
	if not key then return "NothingRegistered" end

	local current = Registry[key]
	if not current then return "NothingRegistered" end

	if current.OnCounter then
		-- Counter move: strict > required to break through poise
		-- Equal interrupt power favours the defender and triggers the counter
		if attackerInterruptPower > current.Poise then
			if current.Cancel then
				current.Cancel()
			end
			return "Cancelled"
		else
			current.OnCounter(attackerEntity)
			return "Countered"
		end
	else
		-- Normal move: >= cancels, equal interrupt power is enough
		if attackerInterruptPower >= current.Poise then
			if current.Cancel then
				current.Cancel()
			end
			return "Cancelled"
		end
	end

	return "NothingRegistered"
end

return ActiveMoveRegistry

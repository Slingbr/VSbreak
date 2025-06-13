local jinMoves = {}
jinMoves.__index = jinMoves

print("Server script started")

local ragdoll = require(game.ReplicatedStorage.Ragdoll)
local VfxRemote = game.ReplicatedStorage.VFX
local HitboxModule = require(game.ServerScriptService.Modules["HitBox Module"])
local States = require(game.ServerScriptService.Modules.StatesModule)
local RaycastHitbox = require(game.ServerScriptService.Modules["RayCast Module"])
local C2S = game.ReplicatedStorage.CharacterScripts.JinWoo.userVFX.Client2Server

function jinMoves.new(player: Player, getCombatInstanceFunc)
	local self = setmetatable({}, jinMoves)
	self.player = player
	self.getCombatInstanceFromCharacter = getCombatInstanceFunc

	self.character = player.Character or player.CharacterAdded:Wait()
	self.humanoid = self.character:FindFirstChild("Humanoid")
	self.hrp = self.character:WaitForChild("HumanoidRootPart")

	self.busy = false
	self.LastAttacktime = {
		R = 0, E = 0, F = 0, G = 0
	}
	self.cooldowns = {
		R = 3, E = 3, F = 3, G = 3
	}
	self.Damage = {
		R = 8, E = 0.15, F = 5, G = 10
	}
local jinMoves = {}
jinMoves.__index = jinMoves

print("Server script started")

local ragdoll = require(game.ReplicatedStorage.Ragdoll)
local VfxRemote = game.ReplicatedStorage.VFX
local HitboxModule = require(game.ServerScriptService.Modules["HitBox Module"])
local States = require(game.ServerScriptService.Modules.StatesModule)
local RaycastHitbox = require(game.ServerScriptService.Modules["RayCast Module"])
local C2S = game.ReplicatedStorage.CharacterScripts.JinWoo.userVFX.Client2Server


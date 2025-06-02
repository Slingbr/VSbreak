local VfxRemote = game.ReplicatedStorage:WaitForChild("VFX")
local JinWooVFX = require(game.ReplicatedStorage.CharacterScripts.JinWoo.userVFX["VFX scripts"])
local enemyJinVFX = require(game.ReplicatedStorage.CharacterScripts.JinWoo.enemyVFX["enemy VFX"])

local vfxHandlers = {
	KillIntent = JinWooVFX.KillIntent,
	KillIntentEnemy = enemyJinVFX.KillIntent,
	SlashBarrage = JinWooVFX.SlashBarrage,
}

VfxRemote.OnClientEvent:Connect(function(vfxType, data)
	if not vfxType or not data then return end

	local handler = vfxHandlers[vfxType]
	if handler then
		handler(data)
	else
		warn("No handler found for VFX type:", vfxType)
	end
end)

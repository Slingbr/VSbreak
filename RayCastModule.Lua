local RaycastHitboxModule = {}

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")


-- Parameters:
-- {
--     Origin = Vector3,
--     Direction = Vector3,
--     Distance = number,
--     Filter = {Instance, ...} (optional),
--     ReturnMultiple = boolean (optional),
--     IgnoreSelf = Instance (optional),
--     Steps = number (optional, default = 5),
--     SpreadAngle = number in degrees (optional, default = 10),
--     Debug = boolean (optional)
-- }
function RaycastHitboxModule.Raycast(params)
	assert(params.Origin, "Origin is required")
	assert(params.Direction, "Direction is required")
	assert(params.Distance, "Distance is required")

	local origin = params.Origin
	local direction = params.Direction.Unit
	local distance = params.Distance
	local filter = params.Filter or {}
	local returnMultiple = params.ReturnMultiple or false
	local ignoreSelf = params.IgnoreSelf
	local debug = params.Debug

	local steps = params.Steps or 5
	local spreadAngle = math.rad(params.SpreadAngle or 10) 

	if ignoreSelf then
		table.insert(filter, ignoreSelf)
	end


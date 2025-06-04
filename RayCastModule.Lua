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


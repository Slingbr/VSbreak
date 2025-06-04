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

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = filter
	raycastParams.IgnoreWater = true

	local results = {}
	local alreadyHit = {}
-- debugger so i can see my rays
	local function debugDrawRay(startPos, directionVec)
		local rayPart = Instance.new("Part")
		rayPart.Size = Vector3.new(0.1, 0.1, directionVec.Magnitude)
		rayPart.Anchored = true
		rayPart.CanCollide = false
		rayPart.Material = Enum.Material.Neon
		rayPart.BrickColor = BrickColor.new("Bright red")
		rayPart.CFrame = CFrame.new(startPos, startPos + directionVec) * CFrame.new(0, 0, -directionVec.Magnitude / 2)
		rayPart.Parent = workspace
		Debris:AddItem(rayPart, 0.25)
	end

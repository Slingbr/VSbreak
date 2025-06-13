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

if returnMultiple then
		for _ = 1, steps do
			local angleX = (math.random() - 0.5) * 2 * spreadAngle
			local angleY = (math.random() - 0.5) * 2 * spreadAngle
			local spreadRotation = CFrame.Angles(angleX, angleY, 0)

	
			local rotatedDirection = (CFrame.lookAt(Vector3.zero, direction) * spreadRotation).LookVector * distance

			if debug then
				debugDrawRay(origin, rotatedDirection)
			end

			local result = workspace:Raycast(origin, rotatedDirection, raycastParams)
			if result and result.Instance then
				local model = result.Instance:FindFirstAncestorOfClass("Model")
				if model and not alreadyHit[model] then
					local humanoid = model:FindFirstChildWhichIsA("Humanoid")
					if humanoid and humanoid.Health > 0 then
						alreadyHit[model] = true
						table.insert(results, model)
					end
				end
			end
		end
	else
		local rayDir = direction * distance
		if debug then
			debugDrawRay(origin, rayDir)
		end

		local result = workspace:Raycast(origin, rayDir, raycastParams)
		if result and result.Instance then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			if model then
				local humanoid = model:FindFirstChildWhichIsA("Humanoid")
				if humanoid and humanoid.Health > 0 then
					table.insert(results, model)
				end
			end
		end
	end

	return results
end

return RaycastHitboxModule

--[[local hitModels = RaycastHitboxModule.Raycast({
	Origin = char.Head.Position,
	Direction = (mouse.Hit.Position - char.Head.Position),
	Distance = 25,
	IgnoreSelf = char,
	Filter = {char},
	ReturnMultiple = true,
	Steps = 10,
	SpreadAngle = 15,
	Debug = true,
})
]]

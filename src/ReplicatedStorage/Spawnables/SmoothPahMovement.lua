local RunService = game:GetService("RunService")

local SmoothPathMovement = {}

local ARRIVAL_DISTANCE = 0.65
local SAMPLE_DISTANCE = 3
local MIN_SEGMENT_SAMPLES = 3
local MAX_SEGMENT_SAMPLES = 18
local ORIENTATION_SMOOTHNESS = 12

local function getInfo()
	return workspace:FindFirstChild("Info")
end

local function getGameSpeed()
	local info = getInfo()
	local gameSpeed = info and info:FindFirstChild("GameSpeed")
	if gameSpeed and gameSpeed.Value > 0 then
		return gameSpeed.Value
	end

	return 1
end

local function flatten(position: Vector3, y: number): Vector3
	return Vector3.new(position.X, y, position.Z)
end

local function getMapFolder()
	local map = workspace:FindFirstChild("Map")
	if not map then
		return workspace
	end

	local children = map:GetChildren()
	return children[1] or workspace
end

local function getRouteContainers(model: Model)
	local team = model:GetAttribute("Team")
	if team then
		return workspace:FindFirstChild(team .. "Waypoints"), workspace:FindFirstChild(team .. "Start")
	end

	local mapFolder = getMapFolder()
	return mapFolder:FindFirstChild("Waypoints"), mapFolder:FindFirstChild("Start")
end

local function getWaypointsInReverse(waypoints: Folder): { Vector3 }
	local indexedWaypoints = {}

	for _, waypoint in ipairs(waypoints:GetChildren()) do
		local index = tonumber(waypoint.Name)
		if index and waypoint:IsA("BasePart") then
			table.insert(indexedWaypoints, {
				index = index,
				position = waypoint.Position,
			})
		end
	end

	table.sort(indexedWaypoints, function(left, right)
		return left.index > right.index
	end)

	local positions = {}
	for _, waypoint in ipairs(indexedWaypoints) do
		table.insert(positions, waypoint.position)
	end

	return positions
end

local function appendPoint(points: { Vector3 }, point: Vector3)
	local previous = points[#points]
	if previous and (previous - point).Magnitude <= 0.05 then
		return
	end

	table.insert(points, point)
end

local function catmullRom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2 = t * t
	local t3 = t2 * t

	return (
		p1 * 2
			+ (p2 - p0) * t
			+ (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2
			+ (p1 * 3 - p0 - p2 * 3 + p3) * t3
	) * 0.5
end

local function buildSmoothPath(points: { Vector3 }): { Vector3 }
	if #points <= 2 then
		return points
	end

	local smoothPath = {}
	appendPoint(smoothPath, points[1])

	for index = 1, #points - 1 do
		local p0 = points[math.max(index - 1, 1)]
		local p1 = points[index]
		local p2 = points[index + 1]
		local p3 = points[math.min(index + 2, #points)]
		local segmentLength = (p2 - p1).Magnitude
		local sampleCount = math.clamp(math.ceil(segmentLength / SAMPLE_DISTANCE), MIN_SEGMENT_SAMPLES, MAX_SEGMENT_SAMPLES)

		for sample = 1, sampleCount do
			appendPoint(smoothPath, catmullRom(p0, p1, p2, p3, sample / sampleCount))
		end
	end

	return smoothPath
end

local function buildRoute(model: Model, root: BasePart): { Vector3 }
	local waypointFolder, endMarker = getRouteContainers(model)
	if not waypointFolder or not endMarker then
		return {}
	end

	local route = {}
	local flightHeight = root.Position.Y

	appendPoint(route, flatten(root.Position, flightHeight))

	for _, waypointPosition in ipairs(getWaypointsInReverse(waypointFolder)) do
		appendPoint(route, flatten(waypointPosition, flightHeight))
	end

	appendPoint(route, flatten(endMarker.Position, flightHeight))

	return buildSmoothPath(route)
end

local function updateSpeed(humanoid: Humanoid, baseWalkSpeed: number)
	humanoid.WalkSpeed = baseWalkSpeed * getGameSpeed()
end

local function ensureOriginalSpeed(model: Model, humanoid: Humanoid): number
	local originalSpeed = model:FindFirstChild("OriginalSpeed")
	if originalSpeed and originalSpeed:IsA("NumberValue") then
		return originalSpeed.Value
	end

	originalSpeed = Instance.new("NumberValue")
	originalSpeed.Name = "OriginalSpeed"
	originalSpeed.Value = humanoid.WalkSpeed
	originalSpeed.Parent = model

	return originalSpeed.Value
end

local function orientToward(model: Model, root: BasePart, targetPosition: Vector3, deltaTime: number)
	local alignOrientation = model:FindFirstChild("AlignOrientation")
	if not alignOrientation or not alignOrientation:IsA("AlignOrientation") then
		return
	end

	local rootPosition = root.Position
	local flatTarget = flatten(targetPosition, rootPosition.Y)
	local direction = flatTarget - rootPosition
	if direction.Magnitude <= 0.05 then
		return
	end

	local desiredCFrame = CFrame.lookAt(rootPosition, rootPosition + direction.Unit)
	local alpha = 1 - math.exp(-ORIENTATION_SMOOTHNESS * deltaTime)

	alignOrientation.CFrame = alignOrientation.CFrame:Lerp(desiredCFrame, alpha)
	alignOrientation.Enabled = true
end

local function shouldStop(model: Model, humanoid: Humanoid, root: BasePart)
	return not model.Parent or not root.Parent or humanoid.Health <= 0
end

local function hasReachedPathPoint(currentPosition: Vector3, previousPoint: Vector3, targetPoint: Vector3): boolean
	if (currentPosition - targetPoint).Magnitude <= ARRIVAL_DISTANCE then
		return true
	end

	local segment = targetPoint - previousPoint
	local segmentLength = segment.Magnitude
	if segmentLength <= 0.05 then
		return true
	end

	return (currentPosition - previousPoint):Dot(segment.Unit) >= segmentLength
end

function SmoothPathMovement.follow(model: Model)
	local humanoid = model:WaitForChild("Humanoid") :: Humanoid
	local root = model:WaitForChild("HumanoidRootPart") :: BasePart
	local baseWalkSpeed = ensureOriginalSpeed(model, humanoid)
	local route = buildRoute(model, root)

	if #route == 0 then
		model:Destroy()
		return
	end

	updateSpeed(humanoid, baseWalkSpeed)

	local info = getInfo()
	local gameSpeed = info and info:FindFirstChild("GameSpeed")
	local speedConnection
	if gameSpeed then
		speedConnection = gameSpeed.Changed:Connect(function()
			updateSpeed(humanoid, baseWalkSpeed)
		end)
	end

	local alignOrientation = model:FindFirstChild("AlignOrientation")
	if alignOrientation and alignOrientation:IsA("AlignOrientation") and #route >= 2 then
		alignOrientation.CFrame = CFrame.lookAt(root.Position, route[2])
		alignOrientation.Enabled = true
	end

	task.wait(0.5)

	for index = 2, #route do
		local target = route[index]
		local previousTarget = route[index - 1]

		while not shouldStop(model, humanoid, root) do
			local flatRootPosition = flatten(root.Position, target.Y)
			if hasReachedPathPoint(flatRootPosition, previousTarget, target) then
				break
			end

			humanoid:MoveTo(target)
			local deltaTime = RunService.Heartbeat:Wait()
			local lookAtIndex = math.min(index + 1, #route)
			orientToward(model, root, route[lookAtIndex], deltaTime)
		end

		if shouldStop(model, humanoid, root) then
			if speedConnection then
				speedConnection:Disconnect()
			end
			return
		end
	end

	if speedConnection then
		speedConnection:Disconnect()
	end

	if model.Parent then
		model:Destroy()
	end
end

return SmoothPathMovement

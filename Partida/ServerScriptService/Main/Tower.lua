local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ServerScriptService= game:GetService("ServerScriptService")

local events = ReplicatedStorage:WaitForChild("Events")
local animateTowerEvent = events:WaitForChild("AnimateTower")
local updateTowerSplashPosEvent = events:WaitForChild("UpdateTowerSplashPos")
local fireAbilityEvent = events:WaitForChild("FireAbility")

local functions = ReplicatedStorage:WaitForChild("Functions")
local spawnTowerFunction = functions:WaitForChild("SpawnTower")
local requestTowerFunction = functions:WaitForChild("RequestTower")
local sellTowerFunction = functions:WaitForChild("SellTower")
local changeModeFunction = functions:WaitForChild("ChangeTowerMode")

local UpgradesModule = require(ReplicatedStorage.Upgrades)
local Traits = require(ReplicatedStorage.Traits)
local ChallengeModule = require(ReplicatedStorage.Modules.ChallengeModule)
local GetUnitModel = require(ReplicatedStorage.Modules.GetUnitModel)
local FormatStats = require(ReplicatedStorage.Modules.FormatStats)
local GameBalance = require(ReplicatedStorage.Modules.GameBalance)
local TowerSpecialisation = require(ServerStorage.ServerModules.TowerSpecialisation)
local Quests = require(game.ReplicatedStorage.Configs.QuestConfig)

local PodDeployer = require(ReplicatedStorage.Modules.PodDeployer)


local requestAbilityFunction = functions:WaitForChild("RequestAbility")

local info = workspace:WaitForChild("Info")

local maxTowers
local tower = {}
local PlayerTowers = {}
local PLACEMENT_MOB_CLEARANCE = 3
local PLACEMENT_SPAWN_CLEARANCE = 18
local PLACEMENT_SPAWN_PATH_CLEARANCE = 10
local PLACEMENT_SPAWN_PATH_LENGTH = 28
local PLACEMENT_SURFACE_RAYCAST_UP = 8
local PLACEMENT_SURFACE_RAYCAST_DOWN = 80
local PLACEMENT_HEIGHT_TOLERANCE = 1.75
local PLACEMENT_MIN_SURFACE_NORMAL_Y = 0.65
local PLACEMENT_DEFAULT_FOOTPRINT_RADIUS = 1.35
local PLACEMENT_DEBUG = true

local function placementDebug(player, ...)
	if not PLACEMENT_DEBUG then
		return
	end

	local playerName = if typeof(player) == "Instance" and player:IsA("Player") then player.Name else "nil"
	print("[PlacementDebug][Server][" .. playerName .. "]", ...)
end

local function formatVector3(value)
	if typeof(value) ~= "Vector3" then
		return tostring(value)
	end

	return string.format("(%.2f, %.2f, %.2f)", value.X, value.Y, value.Z)
end

local function formatCFrame(value)
	if typeof(value) ~= "CFrame" then
		return tostring(value)
	end

	return "pos=" .. formatVector3(value.Position)
end

local function getInstancePath(instance)
	if typeof(instance) ~= "Instance" then
		return tostring(instance)
	end

	return instance:GetFullName()
end

local function isBlockedPlacementSurfaceName(instance)
	if typeof(instance) ~= "Instance" then
		return false
	end

	local lowerName = string.lower(instance.Name)
	return string.find(lowerName, "barrier") ~= nil
		or string.find(lowerName, "wall") ~= nil
		or string.find(lowerName, "bound") ~= nil
		or string.find(lowerName, "border") ~= nil
end


game.Workspace.Towers.ChildAdded:Connect(function(tower)
	if tower:FindFirstChild("Config") then
		if tower.Config:FindFirstChild("Trait") then
			if tower.Config.Trait.Value == "Cosmic Crusader" then
				game.Workspace:SetAttribute("CosmicCrusader",true)
			end
		end
	end
end)

game.Workspace.Towers.ChildRemoved:Connect(function()
	local CosmicCrusader = false
	for i, v in game.Workspace.Towers:GetChildren() do
		if v:FindFirstChild("Config") then
			if v.Config:FindFirstChild("Trait") then
				if v.Config.Trait.Value == "Cosmic Crusader" then
					CosmicCrusader = true
				end
			end
		end
	end
	game.Workspace:SetAttribute("CosmicCrusader",CosmicCrusader)
end)


--function tower.FindTarget(newTower:Model, range:number, mode:string)
--	local bestTarget = nil
--	local bestWaypoint = nil
--	local bestDistance = nil
--	local bestHealth = nil
--	local map = workspace.Map:FindFirstChildOfClass("Folder")

--	warn(mode)

--	for i, mob in workspace.Mobs:GetChildren() do

--		local newMobPositionForTower = Vector3.new(mob.HumanoidRootPart.Position.X,newTower.HumanoidRootPart.Position.Y,mob.HumanoidRootPart.Position.Z)

--		local distanceToMob = (newMobPositionForTower - newTower.HumanoidRootPart.Position).Magnitude
--		local distanceToWaypoint = nil



--		if map:FindFirstChild("Waypoints") then
--			local newMobPositionForPoint = Vector3.new(mob.HumanoidRootPart.Position.X,map.Waypoints[mob.MovingTo.Value].Position.Y,mob.HumanoidRootPart.Position.Z)
--			distanceToWaypoint = (newMobPositionForPoint - map.Waypoints[mob.MovingTo.Value].Position).Magnitude
--		else
--			local newMobPositionForPoint = Vector3.new(mob.HumanoidRootPart.Position.X,map["Waypoints"..mob.PathNumber.Value][mob.MovingTo.Value].Position,mob.HumanoidRootPart.Position.Z)
--			distanceToWaypoint = (newMobPositionForPoint - map["Waypoints"..mob.PathNumber.Value][mob.MovingTo.Value].Position).Magnitude
--		end

--		if distanceToMob <= range then
--			if mode == "Near" then
--				range = distanceToMob
--				bestTarget = mob
--			elseif mode == "First" then
--				if not bestWaypoint or mob.MovingTo.Value >= bestWaypoint then

--					if bestWaypoint and mob.MovingTo.Value > bestWaypoint then
--						bestWaypoint = mob.MovingTo.Value
--						bestDistance = distanceToWaypoint
--						bestTarget = mob
--					elseif not bestDistance or distanceToWaypoint < bestDistance then
--						bestWaypoint = bestWaypoint or mob.MovingTo.Value
--						bestDistance = distanceToWaypoint
--						bestTarget = mob
--					end
--				end
--			elseif mode == "Last" then
--				--if not bestWaypoint or mob.MovingTo.Value <= bestWaypoint then
--				--	bestWaypoint = mob.MovingTo.Value

--				--	if not bestDistance or distanceToWaypoint > bestDistance then
--				--		bestDistance = distanceToWaypoint
--				--		bestTarget = mob
--				--	end
--				--end

--				if not bestWaypoint or mob.MovingTo.Value <= bestWaypoint then

--					if bestWaypoint and mob.MovingTo.Value < bestWaypoint then
--						bestWaypoint = mob.MovingTo.Value
--						bestDistance = distanceToWaypoint
--						bestTarget = mob
--					elseif not bestDistance or distanceToWaypoint > bestDistance then
--						bestWaypoint = bestWaypoint or mob.MovingTo.Value
--						bestDistance = distanceToWaypoint
--						bestTarget = mob
--					end
--				end

--			elseif mode == "Strong" then
--				if not bestHealth or mob.Humanoid.Health > bestHealth then
--					bestHealth = mob.Humanoid.Health
--					bestTarget = mob
--				end
--			elseif mode == "Weak" then
--				if not bestHealth or mob.Humanoid.Health < bestHealth then
--					bestHealth = mob.Humanoid.Health
--					bestTarget = mob
--				end
--			end
--		end
--	end

--	return bestTarget
--end

local function getWaypointProgress(mob, map)
	if not mob:FindFirstChild("MovingTo") or not map then
		return 0
	end

	local currentWaypoint = mob.MovingTo.Value
	local distanceToWaypoint = 0

	if map:FindFirstChild("Waypoints") then
		local waypoint = map.Waypoints:FindFirstChild(tostring(currentWaypoint))
		if waypoint then
			distanceToWaypoint = (mob.HumanoidRootPart.Position - waypoint.Position).Magnitude
		end
	elseif mob:FindFirstChild("PathNumber") then
		local pathName = "Waypoints" .. mob.PathNumber.Value
		local waypointPath = map:FindFirstChild(pathName)
		if waypointPath then
			local waypoint = waypointPath:FindFirstChild(tostring(currentWaypoint))
			if waypoint then
				distanceToWaypoint = (mob.HumanoidRootPart.Position - waypoint.Position).Magnitude
			end
		end
	end

	return currentWaypoint + (1 - math.min(distanceToWaypoint / 10, 1))
end

function tower.FindTarget(newTower:Model, range:number, mode:string)
	local bestTarget = nil
	local bestValue = nil
	local map = workspace.Map:FindFirstChildOfClass("Folder")

	if not workspace.Mobs or #workspace.Mobs:GetChildren() == 0 then
		return nil
	end

	for i, mob in pairs(workspace.Mobs:GetChildren()) do
		if not mob:FindFirstChild("HumanoidRootPart") or not mob:FindFirstChild("Humanoid") then
			continue
		end

		local towerPos = newTower.HumanoidRootPart.Position
		local mobPos = mob.HumanoidRootPart.Position
		local distanceToMob = math.sqrt((mobPos.X - towerPos.X)^2 + (mobPos.Z - towerPos.Z)^2)

		if distanceToMob > range then
			continue
		end

		if mode == "Near" then
			if not bestTarget or distanceToMob < bestValue then
				bestTarget = mob
				bestValue = distanceToMob
			end

		elseif mode == "First" then
			local waypointProgress = getWaypointProgress(mob, map)
			if not bestTarget or waypointProgress > bestValue then
				bestTarget = mob
				bestValue = waypointProgress
			end

		elseif mode == "Last" then
			local waypointProgress = getWaypointProgress(mob, map)
			if not bestTarget or waypointProgress < bestValue then
				bestTarget = mob
				bestValue = waypointProgress
			end

		elseif mode == "Strong" then
			local health = mob.Humanoid.Health
			if not bestTarget or health > bestValue then
				bestTarget = mob
				bestValue = health
			end

		elseif mode == "Weak" then
			local health = mob.Humanoid.Health
			if not bestTarget or health < bestValue then
				bestTarget = mob
				bestValue = health
			end
		end
	end

	return bestTarget
end



function statusEffects(config:Configuration,target2:Model)
	if config:FindFirstChild("BurningDamage") and config:FindFirstChild("BurningDuration") then
		local burningDamage = config.BurningDamage.Value
		local burningDuration = config.BurningDuration.Value
		target2.Burn:Fire(burningDuration,burningDamage,1)
	elseif config:FindFirstChild("PoisonDamage") and config:FindFirstChild("PoisonDuration") then
		local PoisonDamage = config.PoisonDamage.Value
		local PoisonDuration = config.PoisonDuration.Value
		target2.Poison:Fire(PoisonDuration,PoisonDamage,1)
	elseif config:FindFirstChild("FreezeDamage") and config:FindFirstChild("FreezeDuration") then
		local FreezeDamage = config.FreezeDamage.Value
		local FreezeDuration = config.FreezeDuration.Value
		target2.Freeze:Fire(FreezeDuration,FreezeDamage,1)
	elseif config:FindFirstChild("CursedPercent") then
		local CursedPercent = config.CursedPercent.Value
		target2.Curse:Fire(CursedPercent)
	elseif config:FindFirstChild("BleedPercent") and config:FindFirstChild("BleedDuration") then
		local BleedPercent = config.BleedPercent.Value
		local BleedDuration = config.BleedDuration.Value
		target2.Bleed:Fire(BleedDuration,BleedPercent,1)
	end
end

function tower.Buff(tower:Model)
	for _, targets in workspace.Towers:GetChildren() do
		local config = tower.Config
		local TConfig = targets.Config
		local distance = (tower:WaitForChild("HumanoidRootPart").Position - targets:WaitForChild("HumanoidRootPart").Position).Magnitude
		local MaxDistance = config.Range.Value
	end
end

function tower.ChangeMode(player:Player, model:Model)
	if model and model:FindFirstChild("Config") then
		local targetMode = model.Config.TargetMode
		local modes = {"First", "Last", "Near", "Strong", "Weak"}
		local modeIndex = table.find(modes, targetMode.Value)

		if modeIndex < #modes then
			targetMode.Value = modes[modeIndex + 1]
		else
			targetMode.Value = modes[1]
		end

		return true
	else
		warn("Unable to change tower mode")
		return false
	end
end
changeModeFunction.OnServerInvoke = tower.ChangeMode

function tower.Sell(player:Player, model:Model)
	if model and model:FindFirstChild("Config") then
		if model.Config.Owner.Value == player.Name then

			local sellPrice = 0
			if model.Config:FindFirstChild("Upgrades") then
				for i = 1,model.Config.Upgrades.Value do
					sellPrice += UpgradesModule[model.Name].Upgrades[i].Price/2
				end
			else
				sellPrice = model.Config.Price.Value / 2
			end
			sellPrice = math.floor(sellPrice)	--Convert potential decimal to whole


			player.PlacedTowers.Value -= 1
			player.Money.Value += sellPrice --model.Config.Price.Value / 2

			--asdf
			TowerSpecialisation.clearBuffs(model)
			model:Destroy()
			return true
		end
	end

	warn("Unable to sell this tower")
	return false
end
sellTowerFunction.OnServerInvoke = tower.Sell

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function getFlatDistance(pos1, pos2)
	local delta = pos1 - pos2
	return Vector3.new(delta.X, 0, delta.Z).Magnitude
end

local function getFlatDistanceToSegment(position, segmentStart, segmentEnd)
	local point = Vector3.new(position.X, 0, position.Z)
	local startPoint = Vector3.new(segmentStart.X, 0, segmentStart.Z)
	local endPoint = Vector3.new(segmentEnd.X, 0, segmentEnd.Z)
	local segment = endPoint - startPoint
	local segmentLengthSquared = segment:Dot(segment)

	if segmentLengthSquared <= 0 then
		return (point - startPoint).Magnitude, 0
	end

	local alpha = math.clamp((point - startPoint):Dot(segment) / segmentLengthSquared, 0, 1)
	local closestPoint = startPoint + (segment * alpha)
	return (point - closestPoint).Magnitude, (closestPoint - startPoint).Magnitude
end

local function getMobRoot(model)
	if not model or not model.Parent then
		return nil
	end

	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

local function getSpawnMarkers(map)
	local markers = {}
	if not map then
		return markers
	end

	for _, descendant in ipairs(map:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local name = descendant.Name
			if name == "Start" or name == "RedStart" or name == "BlueStart" or name:match("^Start%d+$") then
				table.insert(markers, descendant)
			end
		end
	end

	return markers
end

local function getWaypointFolderForSpawn(map, spawnMarker)
	if not map or not spawnMarker then
		return nil
	end

	local waypointRoot = spawnMarker.Parent or map

	if spawnMarker.Name == "RedStart" then
		return waypointRoot:FindFirstChild("RedWaypoints")
	end

	if spawnMarker.Name == "BlueStart" then
		return waypointRoot:FindFirstChild("BlueWaypoints")
	end

	local pathNumber = spawnMarker.Name:match("^Start(%d+)$")
	if pathNumber then
		return waypointRoot:FindFirstChild("Waypoints" .. pathNumber)
	end

	return waypointRoot:FindFirstChild("Waypoints")
end

local function getFirstWaypoint(map, spawnMarker)
	local waypoints = getWaypointFolderForSpawn(map, spawnMarker)
	if not waypoints then
		return nil
	end

	local firstWaypoint = waypoints:FindFirstChild("1")
	if firstWaypoint then
		return firstWaypoint
	end

	local lowestIndex = math.huge
	for _, child in ipairs(waypoints:GetChildren()) do
		local index = tonumber(child.Name)
		if index and index < lowestIndex and child:IsA("BasePart") then
			lowestIndex = index
			firstWaypoint = child
		end
	end

	return firstWaypoint
end

local function isNearEnemySpawn(cframe, map)
	for _, spawnMarker in ipairs(getSpawnMarkers(map)) do
		local distance = getFlatDistance(spawnMarker.Position, cframe.Position)
		if distance < PLACEMENT_SPAWN_CLEARANCE then
			return true, spawnMarker, distance
		end

		local firstWaypoint = getFirstWaypoint(map, spawnMarker)
		if firstWaypoint and firstWaypoint:IsA("BasePart") then
			local segmentDistance, distanceFromSpawn = getFlatDistanceToSegment(cframe.Position, spawnMarker.Position, firstWaypoint.Position)
			if distanceFromSpawn <= PLACEMENT_SPAWN_PATH_LENGTH and segmentDistance < PLACEMENT_SPAWN_PATH_CLEARANCE then
				return true, spawnMarker, segmentDistance
			end
		end
	end

	return false
end

local function isOverlappingActiveMob(cframe)
	for _, folderName in ipairs({"Mobs", "RedMobs", "BlueMobs"}) do
		local folder = workspace:FindFirstChild(folderName)
		if not folder then
			continue
		end

		for _, mobModel in ipairs(folder:GetChildren()) do
			local humanoid = mobModel:FindFirstChildOfClass("Humanoid")
			local root = getMobRoot(mobModel)
			local distance = root and getFlatDistance(root.Position, cframe.Position) or nil
			if humanoid and humanoid.Health > 0 and root and distance < PLACEMENT_MOB_CLEARANCE then
				return true, mobModel, distance, folderName
			end
		end
	end

	return false
end

local function getTowerPlacementHeight(unitName)
	local unitModel = GetUnitModel[unitName]
	local root = unitModel and unitModel:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Size.Y * 1.5
	end

	return 3
end

local function getTowerPlacementFootprintRadius(unitName)
	local unitModel = GetUnitModel[unitName]
	local root = unitModel and unitModel:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local rootRadius = math.max(root.Size.X, root.Size.Z) * 0.5
		return math.max(PLACEMENT_DEFAULT_FOOTPRINT_RADIUS, math.min(rootRadius, 3))
	end

	return PLACEMENT_DEFAULT_FOOTPRINT_RADIUS
end

local function isAirUnit(unitName)
	local upgradeStats = UpgradesModule[unitName]
	local firstUpgrade = upgradeStats and upgradeStats.Upgrades and upgradeStats.Upgrades[1]
	return firstUpgrade and firstUpgrade.Type == "Air"
end

local function getAllowedPlacementContainerName(player: Player, unitName: string, containerName: string)
	if containerName == "GroundPlace" then
		return true
	end

	if player.Team and containerName == player.Team.Name .. "GroundPlace" then
		return true
	end

	return containerName == "AirPlace" and isAirUnit(unitName)
end

local function getAllowedPlacementContainers(player: Player, unitName: string)
	local containers = {}
	local mapRoot = workspace:FindFirstChild("Map") or workspace

	for _, descendant in ipairs(mapRoot:GetDescendants()) do
		if getAllowedPlacementContainerName(player, unitName, descendant.Name) then
			table.insert(containers, descendant)
		end
	end

	return containers
end

local function getAllowedPlacementContainerForPart(player: Player, unitName: string, part: Instance?)
	if not part then
		return nil
	end

	local parent = part.Parent
	if parent and getAllowedPlacementContainerName(player, unitName, parent.Name) then
		return parent
	end

	return nil
end

local function validatePlacementSample(player: Player, unitName: string, samplePosition: Vector3, expectedGroundY: number, raycastParams: RaycastParams)
	local rayOrigin = samplePosition + Vector3.new(0, PLACEMENT_SURFACE_RAYCAST_UP, 0)
	local rayDirection = Vector3.new(0, -(PLACEMENT_SURFACE_RAYCAST_UP + PLACEMENT_SURFACE_RAYCAST_DOWN), 0)
	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if not result or not result.Instance then
		return false, "no-placement-surface", result, nil
	end

	if isBlockedPlacementSurfaceName(result.Instance) then
		return false, "blocked-placement-surface-name", result, nil
	end

	local container = getAllowedPlacementContainerForPart(player, unitName, result.Instance)
	if not container then
		return false, "hit-not-allowed-placement-container", result, nil
	end

	if result.Normal.Y < PLACEMENT_MIN_SURFACE_NORMAL_Y then
		return false, "surface-too-steep", result, container
	end

	local heightDelta = math.abs(result.Position.Y - expectedGroundY)
	if heightDelta > PLACEMENT_HEIGHT_TOLERANCE then
		return false, "height-mismatch", result, container
	end

	return true, "ok", result, container
end

local function validatePlacementSurface(player: Player, unitName: string, cframe: CFrame)
	local containers = getAllowedPlacementContainers(player, unitName)
	if #containers == 0 then
		return false, "no-placement-containers"
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = containers

	local placementHeight = getTowerPlacementHeight(unitName)
	local expectedGroundY = cframe.Position.Y - placementHeight
	local radius = getTowerPlacementFootprintRadius(unitName)
	local diagonalRadius = radius * 0.707
	local offsets = {
		Vector3.new(0, 0, 0),
		Vector3.new(radius, 0, 0),
		Vector3.new(-radius, 0, 0),
		Vector3.new(0, 0, radius),
		Vector3.new(0, 0, -radius),
		Vector3.new(diagonalRadius, 0, diagonalRadius),
		Vector3.new(-diagonalRadius, 0, diagonalRadius),
		Vector3.new(diagonalRadius, 0, -diagonalRadius),
		Vector3.new(-diagonalRadius, 0, -diagonalRadius),
	}

	for sampleIndex, offset in ipairs(offsets) do
		local rotatedSample = cframe:PointToWorldSpace(offset)
		local samplePosition = Vector3.new(rotatedSample.X, cframe.Position.Y, rotatedSample.Z)
		local isValid, reason, result, container = validatePlacementSample(player, unitName, samplePosition, expectedGroundY, raycastParams)
		if not isValid then
			return false, reason, result, container, sampleIndex, samplePosition, expectedGroundY
		end
	end

	return true, "ok"
end

local function createplacementbox(pos, unitName, sourcePlayer)
	local offset = Vector3.new(0,-2,0)
	placementDebug(sourcePlayer, "createplacementbox:start", "unit=", unitName, "pos=", formatVector3(pos))

	local p = Instance.new("Part")

	p.Name = "PlacementBox"
	p:SetAttribute('Ignore', true)
	p.Position = pos	

	p.Anchored = true
	p.CanCollide = true
	p.Color = Color3.new(0.988235, 0, 0)
	p.Material = Enum.Material.ForceField
	p.Size = Vector3.new(2.623, 3.256, 3.256)
	p.Orientation = Vector3.new(0,90,-90)
	p.Shape = Enum.PartType.Cylinder
	p.Transparency = 1

	p.Parent = workspace.RedZones

	local p2 = Instance.new('Part')
	p2.Position = Vector3.new(0,1000000,0)
	p2.Name = unitName
	p2:SetAttribute('Ignore', true)


	local config = Instance.new('Configuration', p2)
	config.Name = 'Config'
	local OwnedBy = Instance.new('StringValue', config)
	OwnedBy.Name = 'Owner'
	OwnedBy.Value = sourcePlayer.Name

	p2.Parent = workspace.Towers

	PhysicsService:SetPartCollisionGroup(p, "Tower")
	placementDebug(sourcePlayer, "createplacementbox:created", "redZone=", getInstancePath(p), "tempTower=", getInstancePath(p2))

	return p,p2
end

function tower.Spawn(player:Player, value:StringValue, cframe:CFrame, previous:Model, isSpawning:boolean, skipDropAnimation:boolean?, bypassCostCheck:boolean?)
	if not value then
		placementDebug(player, "Spawn:reject-no-unit-value", "cframe=", formatCFrame(cframe), "previous=", getInstancePath(previous), "isSpawning=", isSpawning)
		return false
	end

	local name = value.Name
	if typeof(cframe) ~= "CFrame" then
		placementDebug(player, "Spawn:reject-invalid-cframe", "name=", name, "cframe=", tostring(cframe), "value=", getInstancePath(value))
		return false
	end

	placementDebug(player, "Spawn:start", "name=", name, "value=", getInstancePath(value), "trait=", value:GetAttribute("Trait"), "shiny=", value:GetAttribute("Shiny"), "cframe=", formatCFrame(cframe), "previous=", getInstancePath(previous), "isSpawning=", isSpawning, "skipDropAnimation=", skipDropAnimation, "bypassCostCheck=", bypassCostCheck, "money=", player.Money.Value)
	local allowedToSpawn = tower.CheckSpawn(player, value, previous, isSpawning, bypassCostCheck)
	local outofBounds = true
	local blockedByTower = nil
	local blockedByRedZone = nil
	local blockedDistance = nil

	placementDebug(player, "Spawn:CheckSpawn-result", "name=", name, "allowed=", allowedToSpawn)

	for i,v in pairs(workspace.Towers:GetChildren()) do
		local distance = getMag(v:GetPivot().Position, cframe.Position)
		if distance < 1 then
			outofBounds = false
			blockedByTower = v
			blockedDistance = distance
			break
		end
	end

	for i,v in pairs(workspace.RedZones:GetChildren()) do
		local distance = getMag(v:GetPivot().Position, cframe.Position)
		if distance < 1 then
			outofBounds = false
			blockedByRedZone = v
			blockedDistance = distance
			break
		end
	end

	placementDebug(player, "Spawn:bounds-result", "name=", name, "clearBounds=", outofBounds, "blockedByTower=", getInstancePath(blockedByTower), "blockedByRedZone=", getInstancePath(blockedByRedZone), "blockedDistance=", blockedDistance)

	local found = info:FindFirstChild('Versus')
	if not found then
		Instance.new('BoolValue', info).Name = 'Versus'
	end

	if allowedToSpawn and outofBounds then
		local validPlacementSurface, placementSurfaceReason, placementSurfaceResult, placementSurfaceContainer, placementSampleIndex, placementSamplePosition, expectedGroundY = validatePlacementSurface(player, name, cframe)
		if not validPlacementSurface then
			placementDebug(
				player,
				"Spawn:reject-invalid-placement-surface",
				"name=", name,
				"reason=", placementSurfaceReason,
				"sampleIndex=", placementSampleIndex,
				"samplePosition=", formatVector3(placementSamplePosition),
				"expectedGroundY=", expectedGroundY,
				"hit=", placementSurfaceResult and getInstancePath(placementSurfaceResult.Instance) or "nil",
				"hitPosition=", placementSurfaceResult and formatVector3(placementSurfaceResult.Position) or "nil",
				"hitNormal=", placementSurfaceResult and formatVector3(placementSurfaceResult.Normal) or "nil",
				"container=", getInstancePath(placementSurfaceContainer)
			)
			ReplicatedStorage.Events.Client.Message:FireClient(player, "Cannot place towers outside the placement area!", Color3.new(1, 0.184314, 0.0784314), "Error")
			return false
		end

		local nearSpawn, spawnMarker, spawnDistance = isNearEnemySpawn(cframe, workspace:FindFirstChild("Map") or workspace)
		if nearSpawn then
			placementDebug(player, "Spawn:reject-near-enemy-spawn", "name=", name, "marker=", getInstancePath(spawnMarker), "distance=", spawnDistance, "clearance=", PLACEMENT_SPAWN_CLEARANCE)
			ReplicatedStorage.Events.Client.Message:FireClient(player, "Cannot place towers on enemy spawn!", Color3.new(1, 0.184314, 0.0784314), "Error")
			return false
		end

		local overlappingMob, mobModel, mobDistance, mobFolderName = isOverlappingActiveMob(cframe)
		if overlappingMob then
			placementDebug(player, "Spawn:reject-overlapping-mob", "name=", name, "mob=", getInstancePath(mobModel), "mobFolder=", mobFolderName, "distance=", mobDistance, "clearance=", PLACEMENT_MOB_CLEARANCE)
			ReplicatedStorage.Events.Client.Message:FireClient(player, "Cannot place towers on top of enemies!", Color3.new(1, 0.184314, 0.0784314), "Error")
			return false
		end

		local BuffsTable = {"Damage","Range","Cooldown","Price"}
		local UnitStats = UpgradesModule[name].Upgrades

		local newTower
		local oldMode = nil
		local towerPrice = nil
		local priceMultiplier = 1

		local upgradeStats = UpgradesModule[name]

		local TowerQuantity = 0
		for _, t in game.Workspace.Towers:GetChildren() do
			if t.Config.Owner.Value == player.Name then
				if t.Name == name then
					TowerQuantity += 1
				end
			end
		end

		-- or table.find({"Waders Will"},value:GetAttribute("Trait"))
		local placeLimit = if (table.find({"Cosmic Crusader"},value:GetAttribute("Trait")) or table.find({"Waders Will"},value:GetAttribute("Trait"))) and not info.Versus.Value then 1 else upgradeStats["Place Limit"]
		placementDebug(player, "Spawn:place-limit-check", "name=", name, "placedByPlayer=", TowerQuantity, "limit=", placeLimit, "trait=", value:GetAttribute("Trait"))
		if TowerQuantity >= placeLimit then
			placementDebug(player, "Spawn:reject-place-limit", "name=", name, "placedByPlayer=", TowerQuantity, "limit=", placeLimit)
			ReplicatedStorage.Events.Client.Message:FireClient(player,"You have reached max placement for "..name.."!",Color3.new(0.780392, 0, 0),"Error")
			return
		end

		if upgradeStats then
			local tempBox, temp2 = createplacementbox(cframe.Position, name, player)
			placementDebug(player, "Spawn:temporary-placement-created", "name=", name, "tempBox=", getInstancePath(tempBox), "tempTower=", getInstancePath(temp2))

			if Traits.Traits[value:GetAttribute("Trait")] and not info.Versus.Value then
				if Traits.Traits[value:GetAttribute("Trait")]["Money"] then
					priceMultiplier = (1-(Traits.Traits[value:GetAttribute("Trait")]["Money"]/100))
				end
			end
			if info.ChallengeNumber.Value ~= -1 then
				local challengeData = ChallengeModule.Data[info.ChallengeNumber.Value]
				if challengeData and challengeData.UnitStats ~= nil then
					priceMultiplier += (challengeData.UnitStats.Price / 100)
				end
			end

			newTower = GetUnitModel[name]:Clone()
			placementDebug(player, "Spawn:clone-created", "name=", name, "clone=", getInstancePath(newTower), "versus=", workspace.Info.Versus.Value)

			if workspace.Info.Versus.Value then
				local plrTeam = player.Team.Name

				if plrTeam == 'Red' or plrTeam == 'Blue' then
					newTower:SetAttribute('Team', plrTeam)
				else
					placementDebug(player, "Spawn:reject-no-versus-team", "name=", name, "team=", player.Team and player.Team.Name or "nil")
					newTower:Destroy()
					return 'Please wait for a team'
				end
			end

			local cfg = Instance.new("Configuration")
			cfg.Name = "Config"
			cfg.Parent = newTower
			local index = 0
			for i, v in upgradeStats.Upgrades[1] do
				index += 1
				if typeof(v) == "table" then continue end
				local val = Instance.new(string.upper(string.sub(typeof(v),1,1))..string.sub(typeof(v),2,-1).."Value")
				val.Value = v
				val.Name = i
				val.Parent = newTower.Config
			end

			local val = Instance.new("StringValue")
			val.Name = "Trait"
			val.Parent = newTower.Config
			local Shiny = Instance.new("BoolValue")
			Shiny.Value = value:GetAttribute("Shiny")

			if Shiny.Value and not info.Versus.Value then
				print("Unit is shiny")
				pcall(function()
					local Shine = script.Part:Clone()
					local mainPart = newTower:FindFirstChild('HumanoidRootPart') or newTower.PrimaryPart
					Shine.Position = mainPart.Position
					Shine.Weld.Part1 = mainPart
					Shine.Parent = mainPart
				end)
			end

			Shiny.Name = "Shiny"
			Shiny.Parent = newTower.Config
			local val = Instance.new("IntValue")
			val.Value = 1
			val.Name = "Upgrades"
			val.Parent = newTower.Config

			towerPrice = upgradeStats.Upgrades[1].Price * priceMultiplier
			placementDebug(player, "Spawn:price", "name=", name, "basePrice=", upgradeStats.Upgrades[1].Price, "priceMultiplier=", priceMultiplier, "towerPrice=", towerPrice, "moneyBefore=", player.Money.Value)
			player.PlacedTowers.Value += 1
			newTower:SetAttribute("Origin", name)

			for i, v in BuffsTable do
				local buffper = Instance.new("NumberValue")
				buffper.Name = v.."BuffPercent"
				buffper.Parent = newTower.Config
				local buffdur = Instance.new("NumberValue")
				buffdur.Name = v.."BuffDuration"
				buffdur.Parent = newTower.Config
				local bufftic = Instance.new("NumberValue")
				bufftic.Name = v.."BuffTick"
				bufftic.Parent = newTower.Config
			end

			local totalDamageValue = Instance.new("NumberValue")
			totalDamageValue.Name = "TotalDamage"
			totalDamageValue.Parent = newTower.Config

			local ownerValue = Instance.new("StringValue")
			ownerValue.Name = "Owner"
			ownerValue.Value = player.Name
			ownerValue.Parent = newTower.Config

			local worthValue = Instance.new("IntValue")
			worthValue.Name = "Worth"
			worthValue.Value = towerPrice
			worthValue.Parent = newTower.Config

			local attackingValue = Instance.new("BoolValue")
			attackingValue.Name = "Attacking"
			attackingValue.Value = false
			attackingValue.Parent = newTower

			local targetMode = Instance.new("StringValue")
			targetMode.Name = "TargetMode"
			targetMode.Value = oldMode or "First"
			targetMode.Parent = newTower.Config

			local buffTower = Instance.new("BindableEvent")
			buffTower.Name = "BuffEvent"
			buffTower.Parent = newTower	
			buffTower.Event:Connect(function(buffs)
				for i, v in buffs do
					if newTower.Config:FindFirstChild(i.."BuffPercent") then
						if v["Percent"] > newTower.Config:FindFirstChild(i.."BuffPercent").Value then
							newTower.Config:FindFirstChild(i.."BuffPercent").Value = v["Percent"]
							newTower.Config:FindFirstChild(i.."BuffDuration").Value = v["Duration"]
							newTower.Config:FindFirstChild(i.."BuffTick").Value = tick()
						else
							if v["Percent"] == newTower.Config:FindFirstChild(i.."BuffPercent").Value then
								newTower.Config:FindFirstChild(i.."BuffDuration").Value = v["Duration"]
								newTower.Config:FindFirstChild(i.."BuffTick").Value = tick()
							end
						end
					end
				end
			end)

			task.spawn(function()
				while wait(0.1) do
					for i, v in BuffsTable do
						if newTower:FindFirstChild("Config") then
							if newTower.Config:FindFirstChild(v.."BuffDuration") and newTower.Config:FindFirstChild(v.."BuffTick") then
								if newTower.Config[v.."BuffTick"].Value + newTower.Config[v.."BuffDuration"].Value <= tick() then
									newTower.Config[v.."BuffDuration"].Value = 0
									newTower.Config[v.."BuffTick"].Value = 0
									newTower.Config[v.."BuffPercent"].Value = 0
								end
							end
						end
					end
				end
			end)

			newTower.HumanoidRootPart.CFrame = cframe

			local SplashPositionPart = Instance.new("Part")
			SplashPositionPart.Name = "SplashPositionPart"
			SplashPositionPart.Size = Vector3.new(0.01,0.01,0.01)
			SplashPositionPart.CanCollide = false
			SplashPositionPart.CanTouch = false
			SplashPositionPart.CanQuery = false
			SplashPositionPart.Anchored = true
			SplashPositionPart.Transparency = 1
			local newCFrame = newTower.HumanoidRootPart.CFrame*CFrame.new(0,newTower.HumanoidRootPart.Size.Y*-1.45,-upgradeStats.Upgrades[1].AOESize*1.5)
			SplashPositionPart.CFrame = CFrame.new(newCFrame.Position)
			Instance.new("Attachment",SplashPositionPart)
			SplashPositionPart.Parent = newTower

			newTower.Parent = ReplicatedStorage
			newTower.HumanoidRootPart.Anchored = true
			--newTower.HumanoidRootPart:SetNetworkOwner(nil)

			local TowerBasePart = Instance.new("Part")
			TowerBasePart.Name = "TowerBasePart"
			TowerBasePart.CanCollide = false
			TowerBasePart.CanTouch = false
			TowerBasePart.CanQuery = false
			TowerBasePart.Transparency = 1
			TowerBasePart.Anchored = true
			TowerBasePart.Position = newTower.HumanoidRootPart.Position
			TowerBasePart.Size = Vector3.new(newTower.HumanoidRootPart.Size.Y,newTower.HumanoidRootPart.Size.Y,newTower.HumanoidRootPart.Size.Y)
			TowerBasePart.Parent = newTower

			local VFXTowerBasePart = Instance.new("Part")
			VFXTowerBasePart.Name = "VFXTowerBasePart"
			VFXTowerBasePart.CanCollide = false
			VFXTowerBasePart.CanTouch = false
			VFXTowerBasePart.CanQuery = false
			VFXTowerBasePart.Transparency = 1
			VFXTowerBasePart.Anchored = true
			VFXTowerBasePart.Position = newTower.HumanoidRootPart.Position
			VFXTowerBasePart.Size = Vector3.new(newTower.HumanoidRootPart.Size.Y,newTower.HumanoidRootPart.Size.Y,newTower.HumanoidRootPart.Size.Y)
			VFXTowerBasePart.Parent = newTower



			if newTower.Config:FindFirstChild("Level") then
				newTower.Config.Level.Value = if not info.Versus.Value then value:GetAttribute("Level") else 1
			else
				local towerlevel = Instance.new("IntValue")
				towerlevel.Value = if not info.Versus.Value then value:GetAttribute("Level") else 1
				towerlevel.Name = "Level"
				towerlevel.Parent = newTower.Config
			end

			local bodyGyro = Instance.new("BodyGyro")
			bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			bodyGyro.D = 0
			bodyGyro.CFrame = newTower.HumanoidRootPart.CFrame
			bodyGyro.Parent = newTower.HumanoidRootPart

			local levelboost = 1 + newTower.Config.Level.Value*(1/50)

			for _, stat in {"Damage","Range","Cooldown"} do
				if stat == "Damage" then
					local value = ((newTower.Config[stat].Value * levelboost) * 10) / 10
					newTower.Config.Damage.Value = FormatStats.Format(value)
				else
					newTower.Config[stat].Value = UnitStats[newTower.Config.Upgrades.Value][stat]
				end
			end

			local damage = newTower.Config.Damage.Value
			if damage == 0 then damage = 50 end
			damage = GameBalance.ApplyTowerDamage(damage / 2, upgradeStats.Rarity)

			local TraitStats = Traits.Traits
			local TowerTrait = nil

			if TraitStats[value:GetAttribute("Trait")] and not info.Versus.Value then
				TowerTrait = TraitStats[newTower.Config.Trait.Value]

				if newTower.Config:FindFirstChild("Trait") then
					newTower.Config.Trait.Value = value:GetAttribute("Trait")
				else
					local towertrait = Instance.new("StringValue")
					towertrait.Value = value:GetAttribute("Trait")
					towertrait.Name = "Trait"
					towertrait.Parent = newTower.Config
				end

				for _, stat in {"Damage","Range","Cooldown"} do
					local traitMultiplier = 1
					if Traits.Traits[newTower.Config.Trait.Value] then
						if Traits.Traits[newTower.Config.Trait.Value][stat] then
							traitMultiplier = if stat ~= "Cooldown" then (1+(Traits.Traits[newTower.Config.Trait.Value][stat]/100)) else (1-(Traits.Traits[newTower.Config.Trait.Value][stat]/100))
						end
					end
					local Value = ((newTower.Config[stat].Value * traitMultiplier) * 10) / 10
					newTower.Config[stat].Value = FormatStats.Format(Value)
				end

			end

			for _, stat in {"Damage","Range","Cooldown"} do
				local Multiplier = 1
				if value:GetAttribute("Shiny") then
					Multiplier = if stat ~= "Cooldown" then (1+(15/100)) else (1-(15/100))
				end
				local Value = ((newTower.Config[stat].Value * Multiplier) * 10) / 10
				newTower.Config[stat].Value = FormatStats.Format(Value)
			end

			Traits.AddVisualAura(newTower, value:GetAttribute("Trait"))

			if not newTower.Config:FindFirstChild("CanAttack") then
				local newBool = Instance.new("BoolValue")
				newBool.Name = "CanAttack"
				newBool.Value = true
				newBool.Parent = newTower.Config
			end

			for i, object in newTower:GetDescendants() do
				if object:IsA("BasePart") then
					PhysicsService:SetPartCollisionGroup(object, "Tower")
				end
			end

			--local priceMultiplier = 1

			local Sfx = Instance.new("Sound",player.PlayerGui)
			Sfx.Name = "Upgrade"
			Sfx.SoundId = "rbxassetid://107250853953328"

			Sfx:play()

			game.Debris:AddItem(Sfx,Sfx.TimeLength)
			if not bypassCostCheck then
				player.Money.Value -= towerPrice
			end

			--PROGRESS QUEST
			Quests.UpdateProgressAll(player, "PlaceUnits", 1)

			task.spawn(function()
				if not skipDropAnimation then
					PodDeployer.deployPod(cframe.Position, player, damage)
				end
				tempBox.Name = newTower.Name
				newTower.Parent = workspace.Towers
				tempBox:Destroy()
				temp2:Destroy()
				placementDebug(player, "Spawn:parented-to-workspace", "name=", newTower.Name, "tower=", getInstancePath(newTower), "position=", formatVector3(newTower:GetPivot().Position))
				if not newTower:FindFirstChild("MainScript") then
					coroutine.wrap(tower.Attack)(newTower, player)
				end
			end)



			placementDebug(player, "Spawn:success-return", "name=", name, "tower=", getInstancePath(newTower), "moneyAfter=", player.Money.Value)
			return newTower
		else
			placementDebug(player, "Spawn:reject-missing-upgrade-stats", "name=", name)
			warn("Requested tower does not have upgrade stats:", name)
			return false
		end
	else
		placementDebug(player, "Spawn:reject-before-create", "name=", name, "allowed=", allowedToSpawn, "clearBounds=", outofBounds, "blockedByTower=", getInstancePath(blockedByTower), "blockedByRedZone=", getInstancePath(blockedByRedZone), "blockedDistance=", blockedDistance)
		warn("Requested tower does not exist:", name)
		return false
	end
end

local UpgradeStats = ReplicatedStorage.Functions.UpgradeStats

UpgradeStats.OnServerInvoke = tower.Upgrade
spawnTowerFunction.OnServerInvoke = tower.Spawn

function tower.CheckSpawn(player:Player, value:StringValue, previous:Model, isSpawning:boolean, bypassCostCheck:boolean?)
	if not value then
		placementDebug(player, "CheckSpawn:reject-no-unit-value", "previous=", getInstancePath(previous), "isSpawning=", isSpawning, "bypassCostCheck=", bypassCostCheck)
		return false
	end

	local name = value.Name
	local towerExists = GetUnitModel[name]
	local upgradeStats = UpgradesModule[name]
	placementDebug(player, "CheckSpawn:start", "name=", name, "value=", getInstancePath(value), "towerExists=", towerExists ~= nil, "hasUpgradeStats=", upgradeStats ~= nil, "trait=", value:GetAttribute("Trait"), "money=", player.Money.Value, "bypassCostCheck=", bypassCostCheck)

	if not towerExists then
		placementDebug(player, "CheckSpawn:reject-missing-model", "name=", name)
		return false
	end

	if not upgradeStats or not upgradeStats.Upgrades or not upgradeStats.Upgrades[1] then
		placementDebug(player, "CheckSpawn:reject-missing-upgrade-data", "name=", name)
		return false
	end

	local priceMultiplier = 1
	if Traits.Traits[value:GetAttribute("Trait")] then
		if Traits.Traits[value:GetAttribute("Trait")]["Money"] then
			priceMultiplier = (1-(Traits.Traits[value:GetAttribute("Trait")]["Money"]/100))
		end
	end

	if info.ChallengeNumber.Value ~= -1 then
		local challengeData = ChallengeModule.Data[info.ChallengeNumber.Value]
		if challengeData and challengeData.UnitStats ~= nil then
			priceMultiplier += (challengeData.UnitStats.Price / 100)
		end
	end

	local price = upgradeStats["Upgrades"][1].Price * priceMultiplier
	if bypassCostCheck and towerExists then
		placementDebug(player, "CheckSpawn:allowed-bypass-cost", "name=", name, "price=", price, "money=", player.Money.Value)
		return true
	end

	if towerExists then
		if price <= player.Money.Value then
			placementDebug(player, "CheckSpawn:allowed-money", "name=", name, "price=", price, "money=", player.Money.Value, "priceMultiplier=", priceMultiplier)
			return true	
		else
			placementDebug(player, "CheckSpawn:reject-not-enough-money", "name=", name, "price=", price, "money=", player.Money.Value, "priceMultiplier=", priceMultiplier)
			ReplicatedStorage.Events.Client.Message:FireClient(player,`Not Enough Money`,Color3.new(1, 0.184314, 0.0784314),"Error")
		end
	end

	return false
end

requestTowerFunction.OnServerInvoke = tower.CheckSpawn

function tower.FireAbility(player, ability, newTower)
	if newTower:FindFirstChild("Config") then
		if newTower.Config:FindFirstChild("Owner") then
			if newTower.Config.Owner.Value == player.Name then
				local module = require(ability)
				ability.Parent.AbilityUsedTime.Value = tick()
				module.fire(newTower, player)
			end
		end
	end
end

fireAbilityEvent.OnServerEvent:Connect(tower.FireAbility)

function tower.RequestAbility(plr,ability)
	if ability.CanFire.Value == true then
		coroutine.wrap(function()
			ability.CanFire.Value = false
			task.wait(ability.Cooldown.Value)
			ability.CanFire.Value = true
		end)()
		return true
	else
		return false
	end
end

functions.Upgrade.OnServerInvoke = function (player : Player,tower : Model)
	local SelectedTower = tower

	local UnitStats = UpgradesModule[SelectedTower.Name].Upgrades
	local Config = tower:FindFirstChild("Config")

	if SelectedTower and UnitStats[Config.Upgrades.Value+1] then
		local priceMultiplier = 1
		if Traits.Traits[Config.Trait.Value] then
			if Traits.Traits[Config.Trait.Value]["Money"] then
				priceMultiplier = (1-(Traits.Traits[Config.Trait.Value]["Money"]/100))
			end
		end

		if UnitStats[Config.Upgrades.Value+1].Transparency1 or UnitStats[Config.Upgrades.Value+1].Transparency0 then
			for i, v in tower:GetDescendants() do
				if table.find(UnitStats[Config.Upgrades.Value+1].Transparency1, v.Name) then
					for x, y in v:GetDescendants() do
						if y:IsA("BasePart") then
							y.Transparency = 1
						end
					end
				end
				if table.find(UnitStats[Config.Upgrades.Value+1].Transparency0, v.Name) then
					for x, y in v:GetDescendants() do
						if y:IsA("BasePart") then
							y.Transparency = 0
						end
					end
				end
			end
		end 		

		if info.ChallengeNumber.Value ~= -1 then
			local challengeData = ChallengeModule.Data[info.ChallengeNumber.Value]
			if challengeData and challengeData.UnitStats ~= nil then
				priceMultiplier += (challengeData.UnitStats.Price / 100)
			end
		end

		local price = UnitStats[Config.Upgrades.Value+1].Price * priceMultiplier
		if Config.Upgrades.Value <= UpgradesModule[SelectedTower.Name].MaxUpgrades and player.Money.Value >= price then	

			local Sfx = Instance.new("Sound",player.PlayerGui)
			Sfx.Name = "Upgrade"
			Sfx.SoundId = "rbxassetid://107250853953328"

			Sfx:play()
			game.Debris:AddItem(Sfx,Sfx.TimeLength)
			---16794350425

			Config.Upgrades.Value += 1
			if not tower:FindFirstChild("SplashPositionPart") then
				local SplashPositionPart = Instance.new("Part")
				SplashPositionPart.Name = "SplashPositionPart"
				SplashPositionPart.Size = Vector3.new(0.01,0.01,0.01)
				SplashPositionPart.CanCollide = false
				SplashPositionPart.CanTouch = false
				SplashPositionPart.CanQuery = false
				SplashPositionPart.Anchored = true
				SplashPositionPart.Transparency = 1
				SplashPositionPart.CFrame = tower.HumanoidRootPart.CFrame*CFrame.new(0,tower.HumanoidRootPart.Size.Y*-1.45,-UnitStats[Config.Upgrades.Value].AOESize*1.5)
				Instance.new("Attachment",SplashPositionPart)
				SplashPositionPart.Parent = tower
			end

			local levelboost = 1 + Config.Level.Value*(1/50)
			local hasMoney = UnitStats[Config.Upgrades.Value].Money
			for _, stat in ( hasMoney and {"Money"}) or {"Damage","Range","Cooldown"} do
				if stat == "Damage" then
					local Value = ((UnitStats[Config.Upgrades.Value][stat] * levelboost) * 10) / 10
					Config.Damage.Value = FormatStats.Format(Value)
				else
					Config[stat].Value = UnitStats[Config.Upgrades.Value][stat]
				end
			end

			if Traits.Traits[Config.Trait.Value] then
				for _, stat in {"Damage","Range","Cooldown"} do
					local traitMultiplier = 1
					if Traits.Traits[Config.Trait.Value][stat] then
						traitMultiplier = if stat ~= "Cooldown" then (1+(Traits.Traits[Config.Trait.Value][stat]/100)) else (1-(Traits.Traits[Config.Trait.Value][stat]/100))
					end
					local Value = ((Config[stat].Value * traitMultiplier) * 10) / 10
					Config[stat].Value = FormatStats.Format(Value)
				end
			end

			for _, stat in {"Damage","Range","Cooldown"} do
				local Multiplier = 1
				if Config.Shiny.Value then
					Multiplier = if stat ~= "Cooldown" then (1+(15/100)) else (1-(15/100))
				end
				local Value = (Config[stat].Value * Multiplier * 10) / 10
				Config[stat].Value = FormatStats.Format(Value)
			end

			--if UnitStats[Config.Upgrades.Value+1] and UnitStats[Config.Upgrades.Value+1].AOESize then -- x_x6n: made it so that AOE val gets updated on upgrade
			--	Config.AOESize.Value = UnitStats[Config.Upgrades.Value].AOESize
			--end


			if UnitStats[Config.Upgrades.Value].AOEType ~= Config.AOEType.Value then
				Config.AOEType.Value = UnitStats[Config.Upgrades.Value].AOEType ; Config.AOESize.Value = UnitStats[Config.Upgrades.Value].AOESize
			end

			if UnitStats[Config.Upgrades.Value].Type ~= Config.Type.Value then
				Config.Type.Value = UnitStats[Config.Upgrades.Value].Type
			end

			Config.Worth.Value += price
			player.Money.Value -= price

		else
			return "Not Enough Money"
		end
	else
		return
	end
	return UnitStats
end

requestAbilityFunction.OnServerInvoke = tower.RequestAbility

return tower 

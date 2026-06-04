-- GunFrameworkServer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local modules = ReplicatedStorage:WaitForChild("Modules")
local librariesModules = modules:WaitForChild("Libraries")
local gameModules = modules:WaitForChild("Game")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local fxFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("FX")

local BodyDamage = require(gameModules:WaitForChild("BodyDamage"))
local WeaponSettings = require(librariesModules:WaitForChild("WeaponSettings"))
local WeaponRequest = remotes:WaitForChild("WeaponRequest")
local WeaponFeedback = remotes:WaitForChild("WeaponFeedback")

local PLAYER_STATES = {}
local PLAYER_MOVE_STATES = {}
local MAX_RAY_DISTANCE = 1400
local MAX_ORIGIN_OFFSET = 140
local DEFAULT_WALK_SPEED = 16
local MAX_UNBOOSTED_WALK_SPEED = 20
local ROOT_TURN_LERP_SPEED = 30
local ROOT_TURN_DURATION = 0.25
local ROOT_TURN_TOKENS = {}
local MAX_ACCESSORY_RAYCAST_RETRIES = 20
local ATTR_FROZEN = "GS_IsFrozen"

local STRICT_CROSSHAIR_AIM = true

local DEBUG_SHOT_SYSTEM = false
local DEBUG_HIT_MARKER_LIFETIME = 0.2

local HIT_HIGHLIGHT_DURATION = 0.5
local DAMAGE_PART_DURATION = 1.2
local HIT_HIGHLIGHT_FILL = Color3.fromRGB(255, 55, 55)
local HIT_HIGHLIGHT_OUTLINE = Color3.fromRGB(150, 0, 0)

local function getDefaultWalkSpeedFromHumanoid(humanoid)
	if not humanoid then
		return DEFAULT_WALK_SPEED
	end

	local walkSpeed = humanoid.WalkSpeed
	if walkSpeed > 0 and walkSpeed <= MAX_UNBOOSTED_WALK_SPEED then
		return walkSpeed
	end

	return DEFAULT_WALK_SPEED
end

local function isPlayerFrozen(player)
	return player:GetAttribute(ATTR_FROZEN) == true
end

local function deepFind(root, dottedPath)
	local current = root
	for token in string.gmatch(dottedPath, "[^%.]+") do
		current = current and current:FindFirstChild(token)
	end
	return current
end

local function getConfig(tool)
	local cfg = WeaponSettings.GetConfigForTool(tool)
	if type(cfg) ~= "table" then
		return nil
	end

	return cfg
end

local function getShotDelay(cfg)
	local cooldown = cfg and cfg.ShotCooldown or nil
	if type(cooldown) == "number" and cooldown > 0 then
		return cooldown
	end

	return 60 / ((cfg and cfg.RoundsPerMinute) or 400)
end

local function getAimWalkSpeedMultiplier(cfg)
	local multiplier = cfg and cfg.AimWalkSpeedMultiplier or nil
	if type(multiplier) ~= "number" then
		local global = WeaponSettings.Global
		if type(global) == "table" then
			multiplier = global.AimWalkSpeedMultiplier
		end
	end

	if type(multiplier) ~= "number" then
		multiplier = 0.72
	end

	return math.clamp(multiplier, 0.15, 1)
end

local function isValidEquippedTool(player, tool)
	if not tool or not tool:IsA("Tool") then
		return false
	end

	local character = player.Character
	if not character or tool.Parent ~= character then
		return false
	end

	return tool:FindFirstChild("Handle") ~= nil
end

local function getState(player, tool, cfg)
	PLAYER_STATES[player] = PLAYER_STATES[player] or {}
	local playerState = PLAYER_STATES[player]

	local weaponState = playerState[tool]
	if not weaponState then
		weaponState = {
			ammo = cfg.MagSize or 30,
			reserve = cfg.ReserveAmmo or ((cfg.MagSize or 30) * 3),
			lastShotAt = 0,
			isReloading = false
		}
		playerState[tool] = weaponState
	end

	return weaponState
end

local function getMoveState(player, humanoid)
	local moveState = PLAYER_MOVE_STATES[player]
	if not moveState then
		moveState = {
			defaultWalkSpeed = DEFAULT_WALK_SPEED,
			isAiming = false
		}
		PLAYER_MOVE_STATES[player] = moveState
	end

	if humanoid and not moveState.isAiming then
		moveState.defaultWalkSpeed = getDefaultWalkSpeedFromHumanoid(humanoid)
	end

	return moveState
end

local function sendAmmo(player, tool, state)
	WeaponFeedback:FireClient(player, "Ammo", tool, state.ammo, state.reserve)
end

local function resolveMuzzle(tool, cfg)
	local path = cfg.Attachments and cfg.Attachments.Muzzle
	if type(path) == "string" then
		local found = deepFind(tool, path)
		if found and found:IsA("Attachment") then
			return found
		end
	end

	local fallback = tool:FindFirstChild("Muzzle", true)
	if fallback and fallback:IsA("Attachment") then
		return fallback
	end

	local handle = tool:FindFirstChild("Handle")
	if handle then
		return handle:FindFirstChildOfClass("Attachment")
	end

	return nil
end

local function emitMuzzleParticles(muzzle)
	if not muzzle then
		return
	end

	local flash = muzzle:FindFirstChild("Flash")
	local smoke = muzzle:FindFirstChild("Smoke")

	if flash and flash:IsA("ParticleEmitter") then
		flash:Emit(1)
	end

	if smoke and smoke:IsA("ParticleEmitter") then
		smoke:Emit(2)
	end
end

local function setFXCFrame(instance, cf)
	if instance:IsA("BasePart") then
		instance.CFrame = cf
	elseif instance:IsA("Model") then
		instance:PivotTo(cf)
	end
end

local function setupFXPhysics(instance)
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanCollide = false
		instance.CanQuery = false
		instance.CanTouch = false
		return
	end

	for _, d in ipairs(instance:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
end

local function setDamageAmountText(instance, amount)
	local label = instance:FindFirstChild("DamageAmount", true)
	if label and (label:IsA("TextLabel") or label:IsA("TextBox")) then
		label.Text = tostring(amount)
	end
end

local function spawnDamagePart(position, normal, damageAmount)
	local damageTemplate = fxFolder:FindFirstChild("DamagePart")
	if not damageTemplate then
		return
	end

	local fx = damageTemplate:Clone()
	fx.Parent = workspace
	setupFXPhysics(fx)

	local n = typeof(normal) == "Vector3" and normal or Vector3.new(0, 1, 0)
	if n.Magnitude < 0.001 then
		n = Vector3.new(0, 1, 0)
	end
	n = n.Unit

	setFXCFrame(fx, CFrame.lookAt(position + n * 0.08, position + n))
	setDamageAmountText(fx, damageAmount)

	Debris:AddItem(fx, DAMAGE_PART_DURATION)
end


local function cloneArray(list)
	local out = {}
	for i = 1, #list do
		out[i] = list[i]
	end
	return out
end

local function raycastIgnoringAccessories(origin, direction, baseFilter)
	local dynamicFilter = cloneArray(baseFilter)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	for _ = 1, MAX_ACCESSORY_RAYCAST_RETRIES do
		params.FilterDescendantsInstances = dynamicFilter
		local result = workspace:Raycast(origin, direction, params)
		if not result then
			return nil
		end

		local accessory = result.Instance and result.Instance:FindFirstAncestorOfClass("Accessory")
		if accessory then
			table.insert(dynamicFilter, accessory)
		else
			return result
		end
	end

	return nil
end

local function pickBodyPartForHighlight(hitPart, humanoid, group)
	local model = humanoid and humanoid.Parent
	if not model then
		return nil
	end

	if hitPart and hitPart:IsA("BasePart") and not hitPart:FindFirstAncestorOfClass("Accessory") then
		return hitPart
	end

	local partsByGroup = {
		Head = {"Head"},
		Torso = {"UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart"},
		Arm = {"RightUpperArm", "LeftUpperArm", "RightLowerArm", "LeftLowerArm", "Right Arm", "Left Arm", "RightHand", "LeftHand"},
		Leg = {"RightUpperLeg", "LeftUpperLeg", "RightLowerLeg", "LeftLowerLeg", "Right Leg", "Left Leg", "RightFoot", "LeftFoot"},
	}

	for _, partName in ipairs(partsByGroup[group] or partsByGroup.Torso) do
		local part = model:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			return part
		end
	end

	return nil
end

local function is_head_accessory(accessory: Accessory, model: Model): boolean
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return false
	end

	local handle = accessory:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return false
	end

	for _, descendant in ipairs(handle:GetDescendants()) do
		if descendant:IsA("WeldConstraint") then
			if descendant.Part0 == head or descendant.Part1 == head then
				return true
			end
		elseif descendant:IsA("Weld") or descendant:IsA("ManualWeld") or descendant:IsA("Motor6D") then
			if descendant.Part0 == head or descendant.Part1 == head then
				return true
			end
		end
	end

	for _, descendant in ipairs(handle:GetDescendants()) do
		if descendant:IsA("Attachment") then
			local matchingHeadAttachment = head:FindFirstChild(descendant.Name)
			if matchingHeadAttachment and matchingHeadAttachment:IsA("Attachment") then
				return true
			end
		end
	end

	return false
end

local function get_head_accessory_parts_for_highlight(humanoid: Humanoid): { BasePart }
	local model = humanoid.Parent
	if not model or not model:IsA("Model") then
		return {}
	end

	local parts: { BasePart } = {}
	local seen: { [BasePart]: boolean } = {}

	local function add_part(part: BasePart): ()
		if not seen[part] then
			seen[part] = true
			table.insert(parts, part)
		end
	end

	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") and is_head_accessory(child, model) then
			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant:IsA("BasePart") then
					add_part(descendant)
				end
			end
		end
	end

	return parts
end

local function spawnPartHitHighlight(hitPart, allowAccessory)
	if not hitPart or not hitPart:IsA("BasePart") then
		return
	end

	if hitPart:FindFirstAncestorOfClass("Accessory") and allowAccessory ~= true then
		return
	end

	local hl = Instance.new("Highlight")
	hl.Name = "GS_HitPartHighlight"
	hl.Adornee = hitPart
	hl.FillColor = HIT_HIGHLIGHT_FILL
	hl.OutlineColor = HIT_HIGHLIGHT_OUTLINE
	hl.FillTransparency = 0.35
	hl.OutlineTransparency = 0.15
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = workspace

	Debris:AddItem(hl, HIT_HIGHLIGHT_DURATION)
end

local function spawnServerHitMarker(position, color)
	if not DEBUG_SHOT_SYSTEM then
		return
	end

	local marker = Instance.new("Part")
	marker.Name = "GS_ServerHitMarker"
	marker.Shape = Enum.PartType.Ball
	marker.Size = Vector3.new(0.23, 0.23, 0.23)
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Material = Enum.Material.Neon
	marker.Color = color or Color3.fromRGB(255, 50, 50)
	marker.CFrame = CFrame.new(position)
	marker.Parent = workspace

	Debris:AddItem(marker, DEBUG_HIT_MARKER_LIFETIME)
end

local function spawnImpactFX(result, hitHumanoid)
	if not result then
		return
	end

	if hitHumanoid then
		local blood = fxFolder:FindFirstChild("BloodImpact")
		if blood then
			local b = blood:Clone()
			b.Parent = workspace
			setFXCFrame(b, CFrame.lookAt(result.Position, result.Position + result.Normal))
			Debris:AddItem(b, 0.45)
		end
		return
	end

	local holeTemplate
	if result.Material == Enum.Material.Glass then
		holeTemplate = fxFolder:FindFirstChild("GlassBulletHole")
	else
		holeTemplate = fxFolder:FindFirstChild("BulletHole")
	end

	if holeTemplate then
		local hole = holeTemplate:Clone()
		hole.Parent = workspace
		setFXCFrame(hole, CFrame.lookAt(result.Position, result.Position + result.Normal))
		Debris:AddItem(hole, 8)
	end

	local smokeTemplate = fxFolder:FindFirstChild("Smoke")
	if smokeTemplate then
		local smoke = smokeTemplate:Clone()
		smoke.Parent = workspace
		setFXCFrame(smoke, CFrame.lookAt(result.Position, result.Position + result.Normal))
		Debris:AddItem(smoke, 0.4)
	end
end

local function spreadDirection(direction, spreadDeg)
	if spreadDeg <= 0 then
		return direction.Unit
	end

	local rad = math.rad(spreadDeg)
	local yaw = (math.random() * 2 - 1) * rad
	local pitch = (math.random() * 2 - 1) * rad

	local base = CFrame.lookAt(Vector3.zero, direction.Unit)
	local final = (base * CFrame.Angles(pitch, yaw, 0)).LookVector
	return final.Unit
end

local function getCombatTeamName(player, model)
	if player and player.Team and not player.Neutral then
		return player.Team.Name
	end

	if model and model:IsA("Model") then
		local teamName = model:GetAttribute("MatchTeam")
		if typeof(teamName) == "string" and teamName ~= "" then
			return teamName
		end
	end

	return nil
end

local function isFriendlyFire(shooter, victimPlayer, victimModel)
	if not victimPlayer then
		return false
	end

	local shooterTeam = getCombatTeamName(shooter, shooter.Character)
	local victimTeam = getCombatTeamName(victimPlayer, victimModel)

	return shooterTeam ~= nil and shooterTeam == victimTeam
end

local function applyDamage(shooter, hitPart, cfg)
	local model = hitPart and hitPart:FindFirstAncestorOfClass("Model")
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, nil, nil, 0, nil
	end

	local victimPlayer = Players:GetPlayerFromCharacter(model)
	if victimPlayer == shooter then
		return false, nil, nil, 0, nil
	end
	if isFriendlyFire(shooter, victimPlayer, model) then
		return false, nil, nil, 0, nil
	end

	local damageCfg = cfg.Damage or {}
	local baseDamage = damageCfg.Base or 20
	local group = BodyDamage.GetGroup(hitPart, humanoid)
	local mult = BodyDamage.GetMultiplier(group, damageCfg)
	local finalDamage = math.max(1, math.floor(baseDamage * mult + 0.5))

	local oldCreator = humanoid:FindFirstChild("creator")
	if oldCreator then
		oldCreator:Destroy()
	end

	local creator = Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = shooter
	creator.Parent = humanoid
	Debris:AddItem(creator, 2)

	humanoid:TakeDamage(finalDamage)

	return true, group, humanoid, finalDamage, hitPart
end

local function getRootTurnAlign(root)
	local attachment = root:FindFirstChild("GS_ServerTurnAttachment")
	if not attachment or not attachment:IsA("Attachment") then
		attachment = Instance.new("Attachment")
		attachment.Name = "GS_ServerTurnAttachment"
		attachment.Parent = root
	end

	local align = root:FindFirstChild("GS_ServerTurnAlign")
	if not align or not align:IsA("AlignOrientation") then
		align = Instance.new("AlignOrientation")
		align.Name = "GS_ServerTurnAlign"
		align.Mode = Enum.OrientationAlignmentMode.OneAttachment
		align.Attachment0 = attachment
		align.MaxTorque = 1000000
		align.MaxAngularVelocity = 120
		align.Responsiveness = ROOT_TURN_LERP_SPEED
		align.RigidityEnabled = false
		align.Enabled = false
		align.Parent = root
	end

	align.Attachment0 = attachment
	align.Responsiveness = ROOT_TURN_LERP_SPEED
	return align
end

local function smoothAlignRootToDirection(root, direction)
	local flatDirection = Vector3.new(direction.X, 0, direction.Z)
	if flatDirection.Magnitude < 0.001 then
		return
	end
	flatDirection = flatDirection.Unit

	local token = {}
	ROOT_TURN_TOKENS[root] = token

	local align = getRootTurnAlign(root)
	align.CFrame = CFrame.lookAt(Vector3.zero, flatDirection)
	align.Enabled = true

	task.delay(ROOT_TURN_DURATION, function()
		if ROOT_TURN_TOKENS[root] == token then
			if align.Parent then
				align.Enabled = false
			end
			ROOT_TURN_TOKENS[root] = nil
		end
	end)
end

local function getShotDirection(cfg, direction, isAiming)
	if STRICT_CROSSHAIR_AIM and cfg.PerfectAccuracy ~= false then
		return direction.Unit
	end

	local spreadConfig = cfg.Spread or {}
	local spreadDeg = spreadConfig.Default or 1.2
	if isAiming then
		spreadDeg = spreadConfig.Aimed or spreadConfig.Locked or spreadDeg
	else
		spreadDeg = spreadConfig.Free or spreadDeg
	end

	return spreadDirection(direction.Unit, spreadDeg)
end

WeaponRequest.OnServerEvent:Connect(function(player, action, tool, payload)
	if action == "SetAiming" then
		local aiming = false
		if type(payload) == "table" then
			aiming = payload.aiming == true
		elseif payload == true then
			aiming = true
		end

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		local moveState = getMoveState(player, humanoid)

		if isPlayerFrozen(player) then
			moveState.isAiming = false
			return
		end

		if aiming then
			if not isValidEquippedTool(player, tool) then
				return
			end

			local cfg = getConfig(tool)
			if not cfg then
				return
			end

			if not moveState.isAiming then
				moveState.defaultWalkSpeed = getDefaultWalkSpeedFromHumanoid(humanoid)
			end

			humanoid.WalkSpeed = moveState.defaultWalkSpeed * getAimWalkSpeedMultiplier(cfg)
			moveState.isAiming = true
		else
			if moveState.isAiming then
				humanoid.WalkSpeed = moveState.defaultWalkSpeed
			end
			moveState.isAiming = false
			moveState.defaultWalkSpeed = getDefaultWalkSpeedFromHumanoid(humanoid)
		end
		return
	end

	if not isValidEquippedTool(player, tool) then
		return
	end

	local cfg = getConfig(tool)
	if not cfg then
		return
	end

	local state = getState(player, tool, cfg)

	if action == "Equip" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local moveState = getMoveState(player, humanoid)
			if moveState.isAiming and not isPlayerFrozen(player) then
				humanoid.WalkSpeed = moveState.defaultWalkSpeed
			end
			moveState.isAiming = false
			moveState.defaultWalkSpeed = getDefaultWalkSpeedFromHumanoid(humanoid)
		end

		sendAmmo(player, tool, state)
		return
	end

	if action == "Reload" then
		if state.isReloading then
			return
		end
		if state.ammo >= (cfg.MagSize or 30) then
			return
		end
		if state.reserve <= 0 then
			return
		end

		state.isReloading = true
		local reloadTime = cfg.ReloadTime or 1.5

		WeaponFeedback:FireClient(player, "ReloadStarted", tool, reloadTime)

		task.delay(reloadTime, function()
			if not PLAYER_STATES[player] then
				return
			end
			if not PLAYER_STATES[player][tool] then
				return
			end

			local missing = (cfg.MagSize or 30) - state.ammo
			local toLoad = math.min(missing, state.reserve)

			state.ammo += toLoad
			state.reserve -= toLoad
			state.isReloading = false

			sendAmmo(player, tool, state)
			WeaponFeedback:FireClient(player, "ReloadFinished", tool)
		end)

		return
	end

	if action ~= "Fire" then
		return
	end

	if state.isReloading then
		return
	end

	local now = os.clock()
	local shotDelay = getShotDelay(cfg)
	if now - state.lastShotAt < shotDelay then
		return
	end

	if state.ammo <= 0 then
		WeaponFeedback:FireClient(player, "DryFire", tool)
		return
	end

	if type(payload) ~= "table" then
		return
	end

	local origin = payload.origin
	local direction = payload.direction
	local isAiming = payload.isAiming == true
	local shotId = nil

	if type(payload.shotId) == "number" then
		shotId = math.floor(payload.shotId)
	end

	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end
	if direction.Magnitude < 0.001 then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local moveState = getMoveState(player, humanoid)
		if not moveState.isAiming and humanoid.WalkSpeed > MAX_UNBOOSTED_WALK_SPEED then
			humanoid.WalkSpeed = moveState.defaultWalkSpeed
		end
	end

	local originOffset = (origin - root.Position).Magnitude
	local clampedOrigin = false

	if originOffset > MAX_ORIGIN_OFFSET then
		origin = root.Position + Vector3.new(0, 1.5, 0)
		clampedOrigin = true
	end

	local shotDir = getShotDirection(cfg, direction, isAiming)
	smoothAlignRootToDirection(root, shotDir)

	state.lastShotAt = now
	state.ammo -= 1
	sendAmmo(player, tool, state)

	local range = math.min(cfg.Range or 500, MAX_RAY_DISTANCE)

	local baseFilter = {character, tool}

	local aimResult = raycastIgnoringAccessories(origin, shotDir * range, baseFilter)
	local aimPoint = aimResult and aimResult.Position or (origin + shotDir * range)

	local muzzle = resolveMuzzle(tool, cfg)
	local muzzlePos = (muzzle and muzzle.WorldPosition) or tool.Handle.Position

	local muzzleDirVec = aimPoint - muzzlePos
	local muzzleDir = shotDir
	if muzzleDirVec.Magnitude > 0.001 then
		muzzleDir = muzzleDirVec.Unit
	end

	local result = raycastIgnoringAccessories(muzzlePos, muzzleDir * range, baseFilter)

	local hitPos = muzzlePos + muzzleDir * range
	local hitNormal = -muzzleDir
	local hitHumanoid = false
	local hitGroup = nil

	if result then
		hitPos = result.Position
		hitNormal = result.Normal

		local didDamage, group, humanoidHit, damageDealt, damagedPart = applyDamage(player, result.Instance, cfg)
		hitHumanoid = didDamage
		hitGroup = group

		spawnImpactFX(result, humanoidHit ~= nil)

		if didDamage then
			local highlightPart = pickBodyPartForHighlight(damagedPart, humanoidHit, group)
			spawnPartHitHighlight(highlightPart)

			if group == "Head" and humanoidHit then
				for _, accessoryPart in ipairs(get_head_accessory_parts_for_highlight(humanoidHit)) do
					spawnPartHitHighlight(accessoryPart, true)
				end
			end

			spawnDamagePart(result.Position, result.Normal, damageDealt)
		end
	end

	emitMuzzleParticles(muzzle)

	WeaponFeedback:FireAllClients("ShotFX", player, tool, muzzlePos, hitPos, hitNormal, hitHumanoid)

	if DEBUG_SHOT_SYSTEM then
		if result then
			spawnServerHitMarker(result.Position, Color3.fromRGB(255, 70, 70))
		else
			spawnServerHitMarker(hitPos, Color3.fromRGB(255, 220, 60))
		end

		WeaponFeedback:FireClient(player, "ShotDebug", {
			shotId = shotId,
			clampedOrigin = clampedOrigin,
			originOffset = originOffset,
			serverOrigin = origin,
			serverDirection = shotDir,
			hit = result ~= nil,
			hitPosition = hitPos,
			hitNormal = hitNormal,
			hitInstance = result and result.Instance and result.Instance:GetFullName() or "",
			range = range
		})
	end

	if hitHumanoid and hitGroup then
		WeaponFeedback:FireClient(player, "HitConfirm", tool, hitGroup)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	PLAYER_STATES[player] = nil
	PLAYER_MOVE_STATES[player] = nil
end)

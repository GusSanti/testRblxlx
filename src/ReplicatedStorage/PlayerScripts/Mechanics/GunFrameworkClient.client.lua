-- GunFrameworkClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local WeaponRequest = remotes:WaitForChild("WeaponRequest")
local WeaponFeedback = remotes:WaitForChild("WeaponFeedback")

local modules = ReplicatedStorage:WaitForChild("Modules")
local librariesModules = modules:WaitForChild("Libraries")
local WeaponSettings = require(librariesModules:WaitForChild("WeaponSettings"))
local WeaponAnimations = require(librariesModules:WaitForChild("WeaponAnimation"))
local WeaponSounds = require(librariesModules:WaitForChild("WeaponSounds"))

local assets = ReplicatedStorage:WaitForChild("Assets")
local propsFolder = assets:FindFirstChild("Props")
local userGameSettings = UserSettings():GetService("UserGameSettings")

local SHOULDER_RIGHT = "RIGHT"
local SHOULDER_LEFT = "LEFT"
local RENDER_STEP_NAME = "GS_GunFrameworkClientUpdate"

local ATTR_ACTIVE = "GS_WeaponEquipped"
local ATTR_AIMING = "GS_IsAiming"
local ATTR_FROZEN = "GS_IsFrozen"
local ATTR_MOVEMENT_BASE_WALK_SPEED = "GS_MovementBaseWalkSpeed"
local ATTR_MOVEMENT_IS_RUNNING = "GS_IsRunning"
local ATTR_STOP_RUN_TOKEN = "GS_StopRunToken"

local RELOAD_AMMO_TEMPLATE_NAME = "9mm Ammo"
local RELOAD_AMMO_VISUAL_NAME = "_ReloadAmmoVisual"
local RELOAD_AMMO_SHOW_MARKER = "ShowAmmo"
local RELOAD_AMMO_HIDE_MARKER = "HideAmmo"
local DEFAULT_WALK_SPEED = 16
local MAX_UNBOOSTED_WALK_SPEED = 20
local BODY_TURN_AFTER_SHOT_TIME = 0.32
local DEFAULT_BODY_TURN_LERP_SPEED = 30

local DEBUG_SHOT_SYSTEM = false
local DEBUG_COMBAT = true
local DEBUG_SHOT_RAY_LENGTH = 120
local DEBUG_SHOT_RAY_LIFETIME = 0.08
local DEBUG_MAX_SHOT_CACHE = 40
local SOUND_EVENT_BY_LEGACY_NAME = {
	FireSound = "Fire",
	ReloadSound = "Reload",
	EmptySound = "Empty",
	EquipSound = "Equip",
}

local function ensureAnimator(targetHumanoid)
	local currentAnimator = targetHumanoid:FindFirstChildOfClass("Animator")
	if currentAnimator then
		return currentAnimator
	end

	currentAnimator = Instance.new("Animator")
	currentAnimator.Parent = targetHumanoid
	return currentAnimator
end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = ensureAnimator(humanoid)

local boundTools = {}
local containerConnections = {}

local active = {
	tool = nil,
	weaponKey = nil,
	config = nil,
	soundProfile = nil,
	tracks = nil,
	ammo = 0,
	reserve = 0,
	reloading = false,
	lastShotAt = 0,
	isAiming = false,
	shoulderSide = SHOULDER_RIGHT,
	reloadVisual = nil,
	reloadMarkerConnections = {},
	poseTrack = nil,
	isMoving = false,
	equipEndsAt = 0,
	baseWalkSpeed = humanoid.WalkSpeed,
	aimWalkSpeedApplied = false,
	baseAutoRotate = humanoid.AutoRotate,
	aimAutoRotateApplied = false,
	nextShoulderSwapAt = 0,
	desiredRotationType = Enum.RotationType.MovementRelative,
	cameraOffsetCurrent = Vector3.zero,
	cameraFovCurrent = camera.FieldOfView,
	baseFov = camera.FieldOfView,
	bodyTurnTargetDirection = nil,
	bodyTurnTargetExpiresAt = 0,
	bodyTurnAttachment = nil,
	bodyTurnAlign = nil,
	triggerHeld = false,
	shotSequence = 0,
	debugShotCache = {}
}

local crosshairGui
local crosshairDot
local lastDebugByKey = {}

local function debug_log(message)
	if not DEBUG_COMBAT then
		return
	end

	print("[GunFrameworkClient] " .. message)
end

local function debug_throttled(key, interval, message)
	if not DEBUG_COMBAT then
		return
	end

	local now = os.clock()
	local last = lastDebugByKey[key]
	if last and now - last < interval then
		return
	end

	lastDebugByKey[key] = now
	debug_log(message)
end

local function describeTool(tool)
	if not tool then
		return "nil"
	end
	if typeof(tool) ~= "Instance" then
		return tostring(tool)
	end

	local parentName = if tool.Parent then tool.Parent.Name else "nil"
	local weaponKey = tool:GetAttribute("WeaponKey")
	local weaponId = tool:GetAttribute("WeaponId")

	return string.format(
		"%s parent=%s weaponKey=%s weaponId=%s hasHandle=%s",
		tool.Name,
		parentName,
		tostring(weaponKey),
		tostring(weaponId),
		tostring(tool:FindFirstChild("Handle") ~= nil)
	)
end

local function createCrosshair()
	if crosshairGui then
		return
	end

	crosshairGui = Instance.new("ScreenGui")
	crosshairGui.Name = "GunCrosshair"
	crosshairGui.ResetOnSpawn = false
	crosshairGui.IgnoreGuiInset = true
	crosshairGui.Enabled = false

	pcall(function()
		crosshairGui.ScreenInsets = Enum.ScreenInsets.None
	end)
	pcall(function()
		crosshairGui.ClipToDeviceSafeArea = false
	end)

	crosshairGui.Parent = player:WaitForChild("PlayerGui")

	crosshairDot = Instance.new("Frame")
	crosshairDot.Name = "Dot"
	crosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshairDot.Position = UDim2.fromScale(0.5, 0.5)
	crosshairDot.Size = UDim2.fromOffset(7, 7)
	crosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	crosshairDot.BorderSizePixel = 0
	crosshairDot.Parent = crosshairGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = crosshairDot
end

createCrosshair()

debug_log("Script iniciado; aguardando binding de armas.")

if player:GetAttribute(ATTR_ACTIVE) == nil then
	player:SetAttribute(ATTR_ACTIVE, false)
end

if player:GetAttribute(ATTR_AIMING) == nil then
	player:SetAttribute(ATTR_AIMING, false)
end

local function deepFind(root, dottedPath)
	local current = root
	for token in string.gmatch(dottedPath, "[^%.]+") do
		current = current and current:FindFirstChild(token)
	end
	return current
end

local function getConfig(tool)
	local cfg, weaponKey = WeaponSettings.GetConfigForTool(tool)
	if type(cfg) ~= "table" then
		return nil, nil
	end

	return cfg, weaponKey
end

local function getCameraConfig()
	local global = WeaponSettings.Global
	if type(global) == "table" and type(global.Camera) == "table" then
		return global.Camera
	end
	return nil
end

local function toVector3(v, fallback)
	if typeof(v) == "Vector3" then
		return v
	end
	return fallback
end

local function getShoulderSign()
	if active.shoulderSide == SHOULDER_LEFT then
		return -1
	end
	return 1
end

local function updateMouseBehavior()
	if not active.tool then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		return
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

local function isPlayerFrozen()
	return player:GetAttribute(ATTR_FROZEN) == true
end

local function setDesiredRotationType(rotationType)
	active.desiredRotationType = rotationType
	pcall(function()
		userGameSettings.RotationType = rotationType
	end)
end

local function enforceDesiredRotationType()
	if userGameSettings.RotationType == active.desiredRotationType then
		return
	end

	pcall(function()
		userGameSettings.RotationType = active.desiredRotationType
	end)
end

local function getAimWalkSpeedMultiplier()
	local global = WeaponSettings.Global
	local multiplier = active.config and active.config.AimWalkSpeedMultiplier or nil

	if type(multiplier) ~= "number" and type(global) == "table" then
		multiplier = global.AimWalkSpeedMultiplier
	end

	if type(multiplier) ~= "number" then
		local cameraCfg = getCameraConfig()
		multiplier = cameraCfg and cameraCfg.AimWalkSpeedMultiplier or nil
	end

	return math.clamp(type(multiplier) == "number" and multiplier or 0.72, 0.15, 1)
end

local function getMovementBaseWalkSpeed()
	if not humanoid then
		return DEFAULT_WALK_SPEED
	end

	local attributeSpeed = humanoid:GetAttribute(ATTR_MOVEMENT_BASE_WALK_SPEED)
	if type(attributeSpeed) == "number" and attributeSpeed > 0 then
		return attributeSpeed
	end

	local currentSpeed = humanoid.WalkSpeed
	if humanoid:GetAttribute(ATTR_MOVEMENT_IS_RUNNING) == true and currentSpeed > DEFAULT_WALK_SPEED then
		return DEFAULT_WALK_SPEED
	end

	if currentSpeed > MAX_UNBOOSTED_WALK_SPEED then
		return DEFAULT_WALK_SPEED
	end

	if currentSpeed <= 0 and active.baseWalkSpeed > 0 then
		return active.baseWalkSpeed
	end

	return currentSpeed
end

local function applyAimWalkSpeed()
	if not humanoid then
		return
	end

	if active.isAiming and active.tool then
		if not active.aimWalkSpeedApplied then
			active.baseWalkSpeed = getMovementBaseWalkSpeed()
			active.aimWalkSpeedApplied = true
		end
		humanoid.WalkSpeed = active.baseWalkSpeed * getAimWalkSpeedMultiplier()
	else
		if active.aimWalkSpeedApplied then
			humanoid.WalkSpeed = active.baseWalkSpeed
			active.aimWalkSpeedApplied = false
		else
			active.baseWalkSpeed = humanoid.WalkSpeed
		end
	end
end

local function applyAimAutoRotate()
	if not humanoid then
		return
	end

	local shotTurnActive = active.bodyTurnTargetDirection ~= nil and os.clock() <= active.bodyTurnTargetExpiresAt
	if active.tool and (active.isAiming or shotTurnActive) then
		if not active.aimAutoRotateApplied then
			active.baseAutoRotate = humanoid.AutoRotate
			active.aimAutoRotateApplied = true
		end
		humanoid.AutoRotate = false
	else
		if active.aimAutoRotateApplied then
			humanoid.AutoRotate = active.baseAutoRotate
			active.aimAutoRotateApplied = false
		else
			active.baseAutoRotate = humanoid.AutoRotate
		end
	end
end

local function expAlpha(speed, dt)
	return 1 - math.exp(-math.max(speed, 0.001) * dt)
end

local function getBodyTurnLerpSpeed()
	local cameraCfg = getCameraConfig() or {}
	local speed = cameraCfg.BodyTurnLerpSpeed or cameraCfg.AimTurnLerpSpeed

	if type(speed) ~= "number" then
		speed = DEFAULT_BODY_TURN_LERP_SPEED
	end

	return math.clamp(speed, 1, 90)
end

local function getFlatDirection(direction)
	if typeof(direction) ~= "Vector3" then
		return nil
	end

	local flatDirection = Vector3.new(direction.X, 0, direction.Z)
	if flatDirection.Magnitude < 0.001 then
		return nil
	end

	return flatDirection.Unit
end

local function setBodyTurnTarget(direction, duration)
	local flatDirection = getFlatDirection(direction)
	if not flatDirection then
		return
	end

	active.bodyTurnTargetDirection = flatDirection
	active.bodyTurnTargetExpiresAt = os.clock() + (duration or BODY_TURN_AFTER_SHOT_TIME)
end

local function getBodyTurnAlign()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local attachment = active.bodyTurnAttachment
	if not attachment or attachment.Parent ~= root then
		attachment = root:FindFirstChild("GS_AimTurnAttachment")
		if not attachment or not attachment:IsA("Attachment") then
			attachment = Instance.new("Attachment")
			attachment.Name = "GS_AimTurnAttachment"
			attachment.Parent = root
		end
		active.bodyTurnAttachment = attachment
	end

	local align = active.bodyTurnAlign
	if not align or align.Parent ~= root then
		align = root:FindFirstChild("GS_AimTurnAlign")
		if not align or not align:IsA("AlignOrientation") then
			align = Instance.new("AlignOrientation")
			align.Name = "GS_AimTurnAlign"
			align.Mode = Enum.OrientationAlignmentMode.OneAttachment
			align.Attachment0 = attachment
			align.MaxTorque = 1000000
			align.MaxAngularVelocity = 120
			align.RigidityEnabled = false
			align.Enabled = false
			align.Parent = root
		end
		active.bodyTurnAlign = align
	end

	align.Attachment0 = attachment
	return align
end

local function setBodyTurnAlignEnabled(enabled)
	local align = active.bodyTurnAlign
	if align then
		align.Enabled = enabled
	end
end

local function updateBodyTurn(_dt)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local targetDirection = nil
	if active.tool and active.isAiming then
		targetDirection = getFlatDirection(camera.CFrame.LookVector)
	elseif active.bodyTurnTargetDirection and os.clock() <= active.bodyTurnTargetExpiresAt then
		targetDirection = active.bodyTurnTargetDirection
	else
		active.bodyTurnTargetDirection = nil
	end

	if not targetDirection then
		setBodyTurnAlignEnabled(false)
		applyAimAutoRotate()
		return
	end

	applyAimAutoRotate()

	local align = getBodyTurnAlign()
	if align then
		align.Responsiveness = getBodyTurnLerpSpeed()
		align.CFrame = CFrame.lookAt(Vector3.zero, targetDirection)
		align.Enabled = true
	end
end

local function setAiming(aiming, suppressRemote)
	aiming = aiming == true
	if aiming and not active.tool then
		debug_throttled("aim_without_tool", 0.5, "Tentativa de mirar sem arma ativa.")
		return
	end
	if aiming and isPlayerFrozen() then
		debug_throttled("aim_frozen", 0.5, "Tentativa de mirar enquanto o player esta congelado.")
		return
	end
	if active.isAiming == aiming then
		return
	end

	active.isAiming = aiming
	debug_log(("Aiming alterado para %s com tool=%s"):format(tostring(aiming), describeTool(active.tool)))
	setDesiredRotationType(Enum.RotationType.MovementRelative)

	applyAimAutoRotate()
	applyAimWalkSpeed()
	player:SetAttribute(ATTR_AIMING, aiming)
	updateMouseBehavior()

	if not suppressRemote then
		WeaponRequest:FireServer("SetAiming", active.tool, {
			aiming = aiming,
			direction = camera.CFrame.LookVector
		})
	end
end

local function toggleShoulderSide()
	if not active.tool then
		return
	end
	if os.clock() < active.nextShoulderSwapAt then
		return
	end
	active.nextShoulderSwapAt = os.clock() + 0.08

	if active.shoulderSide == SHOULDER_RIGHT then
		active.shoulderSide = SHOULDER_LEFT
	else
		active.shoulderSide = SHOULDER_RIGHT
	end
end

local function getCameraTargets()
	if not active.tool then
		return Vector3.zero, active.baseFov
	end

	local cameraCfg = getCameraConfig() or {}
	local lockedOffset = toVector3(cameraCfg.LockedOffset, Vector3.new(2.1, 0.85, 0))
	local aimedOffset = toVector3(cameraCfg.AimedOffset, Vector3.new(
		math.max(0.95, math.abs(lockedOffset.X) * 0.68),
		lockedOffset.Y * 0.9,
		lockedOffset.Z
		))

	local defaultFov = cameraCfg.DefaultFov
	if type(defaultFov) ~= "number" then
		defaultFov = active.baseFov
	end

	local aimedFov = cameraCfg.AimedFov
	if type(aimedFov) ~= "number" then
		aimedFov = math.max(45, defaultFov - 12)
	end

	local baseOffset = active.isAiming and aimedOffset or lockedOffset
	local shoulderSign = getShoulderSign()
	local targetOffset = Vector3.new(
		math.abs(baseOffset.X) * shoulderSign,
		baseOffset.Y,
		baseOffset.Z
	)

	local targetFov = active.isAiming and aimedFov or defaultFov
	return targetOffset, targetFov
end

local function getCameraLerpSpeeds()
	local cameraCfg = getCameraConfig() or {}
	local offsetTweenTime = cameraCfg.OffsetTweenTime
	if type(offsetTweenTime) ~= "number" then
		offsetTweenTime = 0.14
	end
	offsetTweenTime = math.max(offsetTweenTime, 0.03)

	local fovTweenTime = cameraCfg.FovTweenTime
	if type(fovTweenTime) ~= "number" then
		fovTweenTime = offsetTweenTime
	end
	fovTweenTime = math.max(fovTweenTime, 0.03)

	local shoulderSwapSpeed = cameraCfg.ShoulderSwapLerpSpeed
	if type(shoulderSwapSpeed) ~= "number" then
		shoulderSwapSpeed = (1 / offsetTweenTime) * 1.35
	end

	return 1 / offsetTweenTime, shoulderSwapSpeed, 1 / fovTweenTime
end

local function updateCameraRig(dt)
	if not humanoid then
		return
	end

	local targetOffset, targetFov = getCameraTargets()
	local offsetSpeed, shoulderSwapSpeed, fovSpeed = getCameraLerpSpeeds()

	local currentOffset = active.cameraOffsetCurrent
	local useSpeed = offsetSpeed
	if targetOffset.X ~= 0 and (currentOffset.X * targetOffset.X < 0) then
		useSpeed = shoulderSwapSpeed
	end

	local offsetAlpha = expAlpha(useSpeed, dt)
	active.cameraOffsetCurrent = currentOffset:Lerp(targetOffset, offsetAlpha)
	humanoid.CameraOffset = Vector3.zero

	local fovAlpha = expAlpha(fovSpeed, dt)
	active.cameraFovCurrent += (targetFov - active.cameraFovCurrent) * fovAlpha
	camera.FieldOfView = active.cameraFovCurrent

	if active.cameraOffsetCurrent.Magnitude > 0.0001 then
		local cf = camera.CFrame
		local shiftedPos = cf.Position
			+ cf.RightVector * active.cameraOffsetCurrent.X
			+ cf.UpVector * active.cameraOffsetCurrent.Y
			+ cf.LookVector * active.cameraOffsetCurrent.Z
		camera.CFrame = CFrame.lookAt(shiftedPos, shiftedPos + cf.LookVector, cf.UpVector)
	end
end

local function normalizeAssetId(idValue)
	if type(idValue) == "number" then
		if idValue <= 0 then
			return nil
		end
		return "rbxassetid://" .. tostring(math.floor(idValue))
	end

	if type(idValue) ~= "string" then
		return nil
	end

	if idValue == "" then
		return nil
	end

	if string.match(idValue, "^rbxassetid://%d+$") then
		return idValue
	end

	local numeric = tonumber(idValue)
	if numeric and numeric > 0 then
		return "rbxassetid://" .. tostring(math.floor(numeric))
	end

	return nil
end

local function getSoundDefinition(tool, soundName)
	local eventName = SOUND_EVENT_BY_LEGACY_NAME[soundName] or soundName
	local profile = nil

	if active.tool == tool and active.soundProfile then
		profile = active.soundProfile
	else
		local weaponKey = WeaponSettings.ResolveTool(tool)
		if weaponKey then
			profile = WeaponSounds.GetProfile(weaponKey)
		end
	end

	if type(profile) ~= "table" then
		profile = WeaponSounds.Default
	end

	local definition = profile and profile[eventName] or nil
	if type(definition) == "table" then
		return definition
	end

	if type(WeaponSounds.Default) == "table" then
		return WeaponSounds.Default[eventName]
	end

	return nil
end

local function playSound(tool, soundName, allowOverlap)
	if not tool then
		return
	end

	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return
	end

	local legacySound = handle:FindFirstChild(soundName)
	if legacySound and legacySound:IsA("Sound") then
		if allowOverlap then
			local cloned = legacySound:Clone()
			cloned.Name = soundName .. "_Temp"
			cloned.Parent = handle
			cloned:Play()
			Debris:AddItem(cloned, math.max(cloned.TimeLength, 0.1) + 0.5)
			return
		end

		legacySound:Play()
		return
	end

	local definition = getSoundDefinition(tool, soundName)
	if type(definition) ~= "table" then
		return
	end

	local soundId = normalizeAssetId(definition.Id)
	if not soundId then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = soundName .. "_Dynamic"
	sound.SoundId = soundId
	sound.Volume = tonumber(definition.Volume) or 1
	sound.PlaybackSpeed = tonumber(definition.PlaybackSpeed) or 1
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMaxDistance = tonumber(definition.MaxDistance) or 90
	sound.RollOffMinDistance = tonumber(definition.MinDistance) or 5
	sound.Parent = handle
	sound:Play()

	local cleanupAfter = math.max(sound.TimeLength / math.max(sound.PlaybackSpeed, 0.05), 0.1) + 0.4
	Debris:AddItem(sound, cleanupAfter)
end

local function playMuzzleFX(tool, cfg)
	local muzzle
	local path = cfg.Attachments and cfg.Attachments.Muzzle
	if type(path) == "string" then
		muzzle = deepFind(tool, path)
	end

	if not muzzle or not muzzle:IsA("Attachment") then
		muzzle = tool:FindFirstChild("Muzzle", true)
	end
	if not muzzle or not muzzle:IsA("Attachment") then
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

local function disconnectConnections(conns)
	if not conns then
		return
	end

	for i = #conns, 1, -1 do
		local c = conns[i]
		if c then
			c:Disconnect()
		end
		conns[i] = nil
	end
end

local function getReloadAmmoTemplate()
	if propsFolder then
		local t = propsFolder:FindFirstChild(RELOAD_AMMO_TEMPLATE_NAME)
		if t then
			return t
		end
	end

	local fallback = ReplicatedStorage:FindFirstChild(RELOAD_AMMO_TEMPLATE_NAME)
	if fallback then
		return fallback
	end

	return nil
end

local function cloneReloadVisualSource(template)
	if template:IsA("Tool") then
		local h = template:FindFirstChild("Handle")
		if h and h:IsA("BasePart") then
			local cloned = h:Clone()
			cloned.Name = RELOAD_AMMO_VISUAL_NAME
			return cloned
		end
		return nil
	end

	local cloned = template:Clone()
	cloned.Name = RELOAD_AMMO_VISUAL_NAME
	return cloned
end

local function getReloadVisualPart(instance)
	if not instance then
		return nil
	end

	if instance:IsA("BasePart") then
		return instance
	end

	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
	end

	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function getOffHandPart()
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
		return character and character:FindFirstChild("Left Arm")
	end

	return (character and character:FindFirstChild("LeftHand")) or (character and character:FindFirstChild("Left Arm"))
end

local function clearReloadVisual()
	if active.reloadVisual then
		active.reloadVisual:Destroy()
		active.reloadVisual = nil
	end
end

local function showReloadVisual()
	if not active.reloading then
		return
	end
	if active.reloadVisual then
		return
	end

	local template = getReloadAmmoTemplate()
	if not template then
		return
	end

	local hand = getOffHandPart()
	if not hand or not hand:IsA("BasePart") then
		return
	end

	local visual = cloneReloadVisualSource(template)
	if not visual then
		return
	end

	visual.Parent = character

	local visualPart = getReloadVisualPart(visual)
	if not visualPart or not visualPart:IsA("BasePart") then
		visual:Destroy()
		return
	end

	local parts = {}

	if visual:IsA("Model") then
		for _, d in ipairs(visual:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
	elseif visual:IsA("BasePart") then
		table.insert(parts, visual)
	else
		for _, d in ipairs(visual:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
	end

	for _, part in ipairs(parts) do
		part.Anchored = false
		part.CanCollide = false
		part.Massless = true
	end

	local attachCF = hand.CFrame * CFrame.new(0, -0.1, -0.25)
	if visual:IsA("Model") then
		visual:PivotTo(attachCF)
	else
		visualPart.CFrame = attachCF
	end

	if visual:IsA("Model") then
		for _, part in ipairs(parts) do
			if part ~= visualPart then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = visualPart
				weld.Part1 = part
				weld.Parent = visualPart
			end
		end
	end

	local handWeld = Instance.new("WeldConstraint")
	handWeld.Part0 = hand
	handWeld.Part1 = visualPart
	handWeld.Parent = visualPart

	active.reloadVisual = visual
end

local function bindReloadMarkers()
	disconnectConnections(active.reloadMarkerConnections)

	local reloadTrack = active.tracks and active.tracks.Reload
	if not reloadTrack then
		return
	end

	local okShow, showSignal = pcall(function()
		return reloadTrack:GetMarkerReachedSignal(RELOAD_AMMO_SHOW_MARKER)
	end)
	if okShow and showSignal then
		table.insert(active.reloadMarkerConnections, showSignal:Connect(function()
			if active.reloading then
				showReloadVisual()
			end
		end))
	end

	local okHide, hideSignal = pcall(function()
		return reloadTrack:GetMarkerReachedSignal(RELOAD_AMMO_HIDE_MARKER)
	end)
	if okHide and hideSignal then
		table.insert(active.reloadMarkerConnections, hideSignal:Connect(function()
			clearReloadVisual()
		end))
	end
end

local function stopPoseTracks(fadeTime)
	if not active.tracks then
		active.poseTrack = nil
		return
	end

	local fade = fadeTime or 0.08
	local holdTrack = active.tracks.Hold
	local idleTrack = active.tracks.Idle
	local walkTrack = active.tracks.Walk

	if holdTrack and holdTrack.IsPlaying then
		holdTrack:Stop(fade)
	end
	if idleTrack and idleTrack.IsPlaying then
		idleTrack:Stop(fade)
	end
	if walkTrack and walkTrack.IsPlaying then
		walkTrack:Stop(fade)
	end

	active.poseTrack = nil
end

local function getHorizontalSpeed()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return 0
	end

	local v = root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude
end

local function updateMovementState()
	if not active.tool or not humanoid or humanoid.Health <= 0 then
		active.isMoving = false
		return
	end

	if humanoid.FloorMaterial == Enum.Material.Air then
		active.isMoving = false
		return
	end

	local inputMag = humanoid.MoveDirection.Magnitude
	local speed = getHorizontalSpeed()

	if active.isMoving then
		active.isMoving = inputMag > 0.03 and speed > 0.15
	else
		active.isMoving = inputMag > 0.08 and speed > 0.35
	end
end

local function getDesiredPoseTrack()
	if not active.tool or not active.tracks then
		return nil
	end

	if active.reloading then
		return nil
	end

	if os.clock() < (active.equipEndsAt or 0) then
		return nil
	end

	local holdTrack = active.tracks.Hold
	local idleTrack = active.tracks.Idle or holdTrack
	local walkTrack = active.tracks.Walk

	if walkTrack then
		if active.isMoving then
			return walkTrack
		end
		return idleTrack or walkTrack
	end

	return idleTrack
end

local function updatePoseTrack(force)
	local desired = getDesiredPoseTrack()

	if not desired then
		if active.poseTrack and active.poseTrack.IsPlaying then
			active.poseTrack:Stop(0.08)
		end
		active.poseTrack = nil
		return
	end

	if not force and active.poseTrack == desired and desired.IsPlaying then
		return
	end

	stopPoseTracks(0.08)

	desired.Looped = true
	desired:Play(0.08)
	active.poseTrack = desired
end

local function stopTracks(tracks)
	if not tracks then
		return
	end

	for _, tr in pairs(tracks) do
		if tr and tr.IsPlaying then
			tr:Stop(0.1)
		end
	end
end

local function coerceAnimationId(value)
	if type(value) == "number" then
		if value <= 0 then
			return nil
		end
		return "rbxassetid://" .. tostring(math.floor(value))
	end

	if type(value) ~= "string" then
		return nil
	end

	if value == "" then
		return nil
	end

	if string.match(value, "^rbxassetid://%d+$") then
		return value
	end

	local numeric = tonumber(value)
	if numeric and numeric > 0 then
		return "rbxassetid://" .. tostring(math.floor(numeric))
	end

	return nil
end

local function loadTrackFromId(animationId)
	local assetId = coerceAnimationId(animationId)
	if not assetId then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = assetId

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	animation:Destroy()

	if ok then
		return track
	end

	return nil
end

local function pickAnimationId(animationData, cfg, oneHandKey, twoHandKey)
	if type(animationData) ~= "table" then
		return nil
	end

	local profile = cfg and string.lower(tostring(cfg.AnimationProfile or "2hand")) or "2hand"
	local preferOneHand = profile == "1hand" or profile == "onehand"

	local first = preferOneHand and oneHandKey or twoHandKey
	local second = preferOneHand and twoHandKey or oneHandKey

	return animationData[first] or animationData[second]
end

local function loadTracks(tool, cfg, weaponKey)
	local resolvedKey = weaponKey or WeaponSettings.ResolveTool(tool)
	if not resolvedKey then
		return {}
	end

	local animationData = WeaponAnimations[resolvedKey]
	if type(animationData) ~= "table" then
		return {}
	end

	local tracks = {}
	local idleAnimId = pickAnimationId(animationData, cfg, "idle1hand", "idle2hand")
	local fireAnimId = pickAnimationId(animationData, cfg, "fire1hand", "fire2hand")
	local reloadAnimId = animationData.reload

	local idleTrack = loadTrackFromId(idleAnimId)
	if idleTrack then
		tracks.Hold = idleTrack
		tracks.Idle = idleTrack
	end

	local walkAnimId = cfg and cfg.WalkAnimationId or nil
	if walkAnimId and walkAnimId ~= idleAnimId then
		tracks.Walk = loadTrackFromId(walkAnimId)
	end

	tracks.Recoil = loadTrackFromId(fireAnimId)
	tracks.Reload = loadTrackFromId(reloadAnimId)

	return tracks
end

local function updateCrosshair()
	if not crosshairGui or not crosshairGui.Enabled then
		return
	end

	crosshairDot.Position = UDim2.fromScale(0.5, 0.5)
end

local function getViewportCenter()
	local viewport = camera.ViewportSize
	return viewport.X * 0.5, viewport.Y * 0.5
end

local function getShotRay()
	local centerX, centerY = getViewportCenter()
	local unitRay = camera:ViewportPointToRay(centerX, centerY, 0)

	local origin = camera.CFrame.Position
	local direction = unitRay.Direction
	if direction.Magnitude < 0.001 then
		direction = camera.CFrame.LookVector
	end

	return origin, direction.Unit, centerX, centerY
end

local function debugDrawRay(origin, direction)
	if not DEBUG_SHOT_SYSTEM then
		return
	end

	local length = DEBUG_SHOT_RAY_LENGTH
	local p = Instance.new("Part")
	p.Name = "GS_ClientDebugRay"
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(0, 255, 140)
	p.Size = Vector3.new(0.06, 0.06, length)
	p.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -length * 0.5)
	p.Parent = workspace

	Debris:AddItem(p, DEBUG_SHOT_RAY_LIFETIME)
end

local function cacheShotDebug(shotId, centerX, centerY, origin, direction)
	if not DEBUG_SHOT_SYSTEM then
		return
	end

	active.debugShotCache[shotId] = {
		sentAt = os.clock(),
		centerX = centerX,
		centerY = centerY,
		origin = origin,
		direction = direction
	}

	local count = 0
	for _ in pairs(active.debugShotCache) do
		count += 1
	end

	if count > DEBUG_MAX_SHOT_CACHE then
		local oldestId = nil
		local oldestTime = math.huge
		for id, item in pairs(active.debugShotCache) do
			if item.sentAt < oldestTime then
				oldestTime = item.sentAt
				oldestId = id
			end
		end
		if oldestId then
			active.debugShotCache[oldestId] = nil
		end
	end
end

local function localRecoil()
	if not active.config then
		return
	end

	local recoil = active.config.Recoil or {}
	local pitch = math.rad(recoil.Pitch or 1)
	local yaw = math.rad((math.random() * 2 - 1) * (recoil.Yaw or 0.3))

	camera.CFrame = camera.CFrame * CFrame.Angles(pitch, yaw, 0)
end

local function stopRunningForShot()
	local token = player:GetAttribute(ATTR_STOP_RUN_TOKEN)
	if type(token) ~= "number" then
		token = 0
	end

	player:SetAttribute(ATTR_STOP_RUN_TOKEN, token + 1)
end

local function getFireMode()
	if not active.config then
		return "semi"
	end

	local mode = string.lower(tostring(active.config.FireMode or "semi"))
	if mode == "automatic" then
		mode = "auto"
	end
	return mode
end

local function isAutomaticMode()
	return getFireMode() == "auto"
end

local function tryShoot()
	if not active.tool or not active.config then
		debug_throttled("shoot_without_tool", 0.5, ("tryShoot abortado; tool=%s config=%s"):format(describeTool(active.tool), tostring(active.config ~= nil)))
		return
	end
	if active.reloading then
		debug_throttled("shoot_reloading", 0.5, "tryShoot abortado; arma esta recarregando.")
		return
	end

	local now = os.clock()
	local shotDelay = active.config.ShotCooldown
	if type(shotDelay) ~= "number" or shotDelay <= 0 then
		shotDelay = 60 / (active.config.RoundsPerMinute or 400)
	end
	if now - active.lastShotAt < shotDelay then
		return
	end

	if active.ammo <= 0 then
		debug_log("tryShoot sem municao para " .. describeTool(active.tool))
		playSound(active.tool, "EmptySound")
		return
	end

	active.lastShotAt = now

	stopRunningForShot()

	local origin, direction, centerX, centerY = getShotRay()
	setBodyTurnTarget(direction, BODY_TURN_AFTER_SHOT_TIME)

	active.shotSequence += 1
	local shotId = active.shotSequence

	cacheShotDebug(shotId, centerX, centerY, origin, direction)
	debugDrawRay(origin, direction)

	playMuzzleFX(active.tool, active.config)
	playSound(active.tool, "FireSound", true)
	localRecoil()

	if active.tracks and active.tracks.Recoil then
		active.tracks.Recoil:Play(0.03)
	end

	debug_log(
		("Enviando Fire para o servidor: tool=%s shotId=%d ammo=%d aiming=%s")
			:format(describeTool(active.tool), shotId, active.ammo, tostring(active.isAiming))
	)
	WeaponRequest:FireServer("Fire", active.tool, {
		origin = origin,
		direction = direction,
		isAiming = active.isAiming,
		shotId = shotId
	})
end

local function tryReload()
	if not active.tool or not active.config then
		return
	end
	if active.reloading then
		return
	end
	if active.ammo >= (active.config.MagSize or 30) then
		return
	end
	if active.reserve <= 0 then
		return
	end

	WeaponRequest:FireServer("Reload", active.tool)
end

local function equipTool(tool)
	local cfg, weaponKey = getConfig(tool)
	if not cfg then
		debug_log("equipTool abortado; configuracao nao encontrada para " .. describeTool(tool))
		return
	end

	debug_log(("Equipando tool=%s resolvedKey=%s"):format(describeTool(tool), tostring(weaponKey)))

	if active.tool and active.tool ~= tool then
		stopTracks(active.tracks)
		clearReloadVisual()
		disconnectConnections(active.reloadMarkerConnections)
	end

	active.tool = tool
	active.weaponKey = weaponKey
	active.config = cfg
	active.soundProfile = WeaponSounds.GetProfile(weaponKey)
	active.tracks = loadTracks(tool, cfg, weaponKey)
	active.reloading = false
	active.poseTrack = nil
	active.isMoving = false
	active.equipEndsAt = 0
	active.triggerHeld = false
	bindReloadMarkers()

	player:SetAttribute(ATTR_ACTIVE, true)

	setAiming(false, true)
	setBodyTurnAlignEnabled(false)
	setDesiredRotationType(Enum.RotationType.MovementRelative)
	updateMouseBehavior()

	if crosshairGui then
		crosshairGui.Enabled = true
	end

	playSound(tool, "EquipSound")
	updateMovementState()
	updatePoseTrack(true)

	WeaponRequest:FireServer("Equip", tool)
end

local function unequipTool(tool)
	if active.tool ~= tool then
		return
	end

	debug_log("Desequipando tool=" .. describeTool(tool))

	setAiming(false)
	stopTracks(active.tracks)
	stopPoseTracks(0.06)
	clearReloadVisual()
	disconnectConnections(active.reloadMarkerConnections)

	active.tool = nil
	active.weaponKey = nil
	active.config = nil
	active.soundProfile = nil
	active.tracks = nil
	active.reloading = false
	active.ammo = 0
	active.reserve = 0
	active.poseTrack = nil
	active.isMoving = false
	active.equipEndsAt = 0
	active.bodyTurnTargetDirection = nil
	active.bodyTurnTargetExpiresAt = 0
	active.triggerHeld = false

	player:SetAttribute(ATTR_ACTIVE, false)
	player:SetAttribute(ATTR_AIMING, false)
	setDesiredRotationType(Enum.RotationType.MovementRelative)

	if crosshairGui then
		crosshairGui.Enabled = false
	end

	applyAimAutoRotate()
	applyAimWalkSpeed()
	setBodyTurnAlignEnabled(false)
	updateMouseBehavior()
end

local function disconnectTool(tool)
	local conns = boundTools[tool]
	if not conns then
		return
	end

	for _, c in ipairs(conns) do
		c:Disconnect()
	end

	boundTools[tool] = nil
end

local function clearToolBindings()
	for tool in pairs(boundTools) do
		disconnectTool(tool)
	end
end

local function bindTool(tool)
	if boundTools[tool] then
		return
	end
	if not tool:IsA("Tool") then
		return
	end

	local resolvedWeaponKey = WeaponSettings.ResolveTool(tool)
	debug_log(("bindTool encontrado: %s resolvedKey=%s"):format(describeTool(tool), tostring(resolvedWeaponKey)))
	if not resolvedWeaponKey then
		debug_log("bindTool ignorado; WeaponSettings nao reconheceu a tool " .. describeTool(tool))
		return
	end

	local conns = {}

	conns[#conns + 1] = tool.Equipped:Connect(function()
		debug_log("Evento Equipped recebido para " .. describeTool(tool))
		equipTool(tool)
	end)

	conns[#conns + 1] = tool.Unequipped:Connect(function()
		debug_log("Evento Unequipped recebido para " .. describeTool(tool))
		unequipTool(tool)
	end)

	-- Fallback para touch/controller.
	conns[#conns + 1] = tool.Activated:Connect(function()
		if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
			tryShoot()
		end
	end)

	conns[#conns + 1] = tool.AncestryChanged:Connect(function(_, parent)
		if not parent then
			debug_log("Tool removida da hierarquia: " .. describeTool(tool))
			if active.tool == tool then
				unequipTool(tool)
			end
			disconnectTool(tool)
		end
	end)

	boundTools[tool] = conns
end

local function clearContainerConnections()
	for _, c in ipairs(containerConnections) do
		c:Disconnect()
	end
	table.clear(containerConnections)
end

local function bindContainer(container)
	debug_log("Bindando container de armas: " .. container:GetFullName())
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") then
			bindTool(child)
		end
	end

	local conn = container.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			debug_log("Nova tool detectada em " .. container:GetFullName() .. ": " .. describeTool(child))
			bindTool(child)
		end
	end)

	table.insert(containerConnections, conn)
end

local function onCharacterAdded(newCharacter)
	debug_log("CharacterAdded recebido no GunFrameworkClient: " .. newCharacter:GetFullName())
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	animator = ensureAnimator(humanoid)
	camera = workspace.CurrentCamera or camera

	if active.tool then
		unequipTool(active.tool)
	end

	clearReloadVisual()
	disconnectConnections(active.reloadMarkerConnections)
	setBodyTurnAlignEnabled(false)

	humanoid.AutoRotate = true
	active.baseWalkSpeed = humanoid.WalkSpeed
	active.aimWalkSpeedApplied = false
	active.baseAutoRotate = humanoid.AutoRotate
	active.aimAutoRotateApplied = false
	active.isAiming = false
	active.shoulderSide = SHOULDER_RIGHT
	active.nextShoulderSwapAt = 0
	active.bodyTurnTargetDirection = nil
	active.bodyTurnTargetExpiresAt = 0
	active.bodyTurnAttachment = nil
	active.bodyTurnAlign = nil
	active.weaponKey = nil
	active.soundProfile = nil
	active.triggerHeld = false
	active.shotSequence = 0
	active.debugShotCache = {}
	setDesiredRotationType(Enum.RotationType.MovementRelative)

	active.cameraOffsetCurrent = Vector3.zero
	humanoid.CameraOffset = Vector3.zero

	active.baseFov = camera.FieldOfView
	active.cameraFovCurrent = camera.FieldOfView

	player:SetAttribute(ATTR_ACTIVE, false)
	player:SetAttribute(ATTR_AIMING, false)

	clearToolBindings()
	clearContainerConnections()

	local backpack = player:WaitForChild("Backpack")
	bindContainer(backpack)
	bindContainer(character)

	updateMouseBehavior()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCamera = workspace.CurrentCamera
	if not newCamera then
		return
	end

	camera = newCamera
	active.baseFov = camera.FieldOfView
	active.cameraFovCurrent = camera.FieldOfView
end)

player.CharacterAdded:Connect(onCharacterAdded)
onCharacterAdded(character)

UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton2
		or input.KeyCode == Enum.KeyCode.LeftShift
	then
		debug_log(
			("InputBegan type=%s key=%s processed=%s activeTool=%s mouseBehavior=%s rotationType=%s")
				:format(
					tostring(input.UserInputType),
					tostring(input.KeyCode),
					tostring(processed),
					describeTool(active.tool),
					tostring(UserInputService.MouseBehavior),
					tostring(userGameSettings.RotationType)
				)
		)
	end

	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		tryReload()
		return
	end

	if input.KeyCode == Enum.KeyCode.E then
		toggleShoulderSide()
		return
	end
end)

UserInputService.WindowFocusReleased:Connect(function()
	setAiming(false)
	active.triggerHeld = false
end)

RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 2, function(dt)
	if isPlayerFrozen() and active.isAiming then
		setAiming(false, true)
	end

	local wantsAim = active.tool ~= nil
		and not isPlayerFrozen()
		and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	if wantsAim ~= active.isAiming then
		setAiming(wantsAim)
	end

	-- Primeiro atualiza câmera/rotação do frame atual
	enforceDesiredRotationType()
	updateBodyTurn(dt)
	updateCameraRig(dt)
	updateCrosshair()

	-- Só depois dispara, para usar a câmera final que o jogador está vendo
	local triggerDown = active.tool ~= nil and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	if triggerDown then
		if isAutomaticMode() then
			tryShoot()
		elseif not active.triggerHeld then
			tryShoot()
		end
	end
	active.triggerHeld = triggerDown

	updateMovementState()
	updatePoseTrack(false)
end)

WeaponFeedback.OnClientEvent:Connect(function(action, p1, p2, p3)
	debug_throttled("feedback_" .. tostring(action), 0.15, "WeaponFeedback recebido: " .. tostring(action))

	if action == "Ammo" then
		local tool = p1
		if active.tool == tool then
			active.ammo = p2 or 0
			active.reserve = p3 or 0
			debug_log(("Municao sincronizada para %s: ammo=%d reserve=%d"):format(describeTool(tool), active.ammo, active.reserve))
		end
		return
	end

	if action == "ShotDebug" then
		local data = p1
		if type(data) ~= "table" then
			return
		end

		local shotId = data.shotId
		local hitPos = data.hitPosition
		if typeof(hitPos) ~= "Vector3" then
			return
		end

		local viewportPoint, onScreen = camera:WorldToViewportPoint(hitPos)
		local cx, cy = getViewportCenter()
		local dx = viewportPoint.X - cx
		local dy = viewportPoint.Y - cy

		local clamped = data.clampedOrigin == true and "YES" or "NO"
		local off = tonumber(data.originOffset) or 0
		local partName = tostring(data.hitInstance or "")

		warn(string.format(
			"[GS DEBUG] shot=%s clamped=%s originOffset=%.2f dx=%.2f dy=%.2f onScreen=%s hit=%s",
			tostring(shotId),
			clamped,
			off,
			dx,
			dy,
			tostring(onScreen),
			partName
			))
		return
	end

	if action == "DryFire" then
		local tool = p1
		if active.tool == tool then
			debug_log("Servidor retornou DryFire para " .. describeTool(tool))
			playSound(tool, "EmptySound")
		end
		return
	end

	if action == "ReloadStarted" then
		local tool = p1
		if active.tool == tool then
			debug_log("Servidor confirmou inicio de reload para " .. describeTool(tool))
			active.reloading = true
			playSound(tool, "ReloadSound")

			stopPoseTracks(0.05)

			if active.tracks and active.tracks.Reload then
				active.tracks.Reload:Play(0.05)
			end

			clearReloadVisual()
			showReloadVisual()
		end
		return
	end

	if action == "ReloadFinished" then
		local tool = p1
		if active.tool == tool then
			debug_log("Servidor confirmou fim de reload para " .. describeTool(tool))
			active.reloading = false
			clearReloadVisual()
			updateMovementState()
			updatePoseTrack(true)
		end
		return
	end

	if action == "ShotFX" then
		local shooterPlayer = p1
		local shooterTool = p2

		if shooterPlayer ~= player and shooterTool and shooterTool:IsA("Tool") then
			local cfg = getConfig(shooterTool)
			if cfg then
				playMuzzleFX(shooterTool, cfg)
			end
			playSound(shooterTool, "FireSound", true)
		end
		return
	end
end)

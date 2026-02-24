------------------//SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")

------------------//MODULES
local DataUtility = require(ReplicatedStorage.Modules.Utility.DataUtility)
local RockModule = require(ReplicatedStorage.Modules.Game:WaitForChild("RockModule"))
local CameraShaker = require(ReplicatedStorage.Modules.Libraries.CameraShaker)
local PopupModule = require(ReplicatedStorage.Modules.Libraries.PopupModule)
local WorldConfig = require(ReplicatedStorage.Modules.Datas.WorldConfig)
local NotificationUtility = require(ReplicatedStorage.Modules.Utility.NotificationUtility)
local SoundController = require(ReplicatedStorage.Modules.Utility.SoundUtility)
local SoundData = require(ReplicatedStorage.Modules.Datas.SoundData)

------------------//CONFIG
local CONFIG = {
	-- CONSTANTS & SYSTEM
	RENDER_STEP = "PogoLogic",
	DEFAULT_GRAVITY = 196.2,
	ANIM_ID = "rbxassetid://105821789218134",
	PASS_AUTO = 1699595369,
	PASS_EASY = 1701310636,
	POWER_SCALE = 0.6,

	-- SMOOTHING
	SMOOTH_DIST = 25,
	SMOOTH_BAR = 45,
	SMOOTH_PERFECT = 20,
	SMOOTH_VIGNETTE = 10,
	SMOOTH_FOV = 12,

	-- RAYCAST
	RAY_LEN = 500,
	RAY_LAND_THRESH = 3.0,
	RAY_VEL_THRESH = 8,
	RAY_FRAMES = 2,
	RAY_OFFSET = 1.2,

	-- SETTINGS (GAMEPLAY)
	base_jump_power = 120,-- template(ignore)
	combo_bonus_power = 8,
	max_combo_power_cap = 250,
	gravity_mult = 1.4, -- extra 
	miss_penalty_duration = 2,
	stun_duration = 1.5,
	stun_walkspeed = 6,
	perfect_zone_percent = 0.3,
	forward_base_mult = 0.35,
	forward_combo_mult = 0.04,
	forward_max_speed = 60,
	forward_perfect_bonus = 1.3,

	-- [NOVA MECÂNICA: AIR VELOCITY]
	air_mobility = 60, -- "AirVelocity": O quão rápido ele muda de direção no ar (Quanto maior, mais responsivo)
	air_max_speed = 70, -- Limite de velocidade horizontal para não quebrar o jogo

	fov_base = 70,
	fov_max = 110,
	visual_max_height = 100,

	-- CRATER VFX
	crater_enabled = true,
	crater_force_scale = 0.25,
	crater_min_impact = 40,
	crater_radius_min = 4.0,
	crater_radius_max = 7.5,
	crater_depth_min = 0.8,
	crater_depth_max = 1.5,
	critical_vfx_mult = 1.4,
	crater_min_voxel = 3,
	crater_reset_time = 3,
	crater_fly_percent = 0.4,
	crater_fly_cap = 8,
	crater_debris_time = 4,
	crater_vanish_delay = 0.06,
	crater_velocity = 35,
	crater_up_boost = 45,
}

------------------//VARIABLES
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")
local pogoEvent = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("PogoEvent")

local playerGui = player:WaitForChild("PlayerGui")
local uiRoot = playerGui:WaitForChild("UI")
local hud = uiRoot:WaitForChild("GameHUD")
local bottomBar = hud:WaitForChild("BottomBarFR")
local jumpButton = bottomBar:WaitForChild("JumpBT")
local autoJumpButton = bottomBar:WaitForChild("AutoJumpBT")

local vignette = hud:WaitForChild("Vignette")
local whiteVignette = hud:WaitForChild("WhiteVignette")
local barContainer = hud:WaitForChild("BarContainer")
local barFill = barContainer:WaitForChild("BarFill")
local perfectZone = barContainer:WaitForChild("PerfectZone")
local promptLabel = barContainer:WaitForChild("PromptLabel")

local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local humanoidStateConn = nil
local camShake = nil

local last_falling_velocity = 0
local last_ground_distance = 0
local smooth_ground_distance = 0
local last_ground_hit_pos = nil
local last_ground_hit_normal = nil

local is_jump_held = false
local auto_jump_active = false
local has_auto_jump_pass = false
local gravityApplied = false

local jumpAnimation = nil
local jumpTrack = nil
local animToken = 0
local animHeartbeatConn = nil

local auto_jump_start_time = os.clock()
local is_afk_mode = false
local raycastParams = RaycastParams.new()

-- DEBUG VARIABLES --
local debug_last_jump_start = os.clock()

local state = {
	is_grounded = true,
	current_combo = 0,
	distance_to_ground = 0,
	raw_ground_distance = 0,
	can_rebound = false,
	queued_jump = false,
	visual_bar_pct = 0,
	visual_perfect_size = 0,
	visual_white_vignette = 1,
	current_jump_peak = 50,
	last_jump_time = 0,
	jump_grace_time = 0,
	cooldown_end_time = 0,
	is_stunned = false,
	original_walkspeed = 16,
	visual_fov = camera.FieldOfView,
	is_falling = false,
	was_airborne = false,
	landed_frames = 0,
	on_block_zone = false,
}

------------------//FUNCTIONS

local function get_layer_by_height(character: Model): any
	if not character then return nil end
	local rp = character:FindFirstChild("HumanoidRootPart")
	if not rp then return nil end

	local currentY = rp.Position.Y
	local worldId = DataUtility.client.get("CurrentWorld") or 1
	local worldData = WorldConfig.GetWorld(worldId)

	if worldData and worldData.layers then
		for _, layer in ipairs(worldData.layers) do
			if currentY <= layer.maxHeight and currentY > layer.minHeight then
				return layer
			end
		end
		return worldData.layers[1]
	end

	return nil
end

local function apply_rebirth_upgrades()
	local ownedUpgrades = DataUtility.client.get("OwnedRebirthUpgrades") or {}

	local hasGamepass = false
	pcall(function()
		hasGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, CONFIG.PASS_EASY)
	end)

	if table.find(ownedUpgrades, "SoftLanding") or hasGamepass then
		CONFIG.perfect_zone_percent = 0.5
	else
		CONFIG.perfect_zone_percent = 0.3
	end

	if humanoid and humanoid.Parent then
		if table.find(ownedUpgrades, "SpeedBoots") then
			state.original_walkspeed = 24
		else
			state.original_walkspeed = 16
		end

		if not state.is_stunned then
			humanoid.WalkSpeed = state.original_walkspeed
		end
	end
end

local function exp_lerp(a, b, speed, dt)
	local alpha = 1 - math.exp(-speed * dt)
	return a + (b - a) * alpha
end

local function apply_gravity_from_settings()
	workspace.Gravity = CONFIG.DEFAULT_GRAVITY
end

local function update_local_settings(newSettings)
	if not newSettings then return end
	for key, value in pairs(newSettings) do
		CONFIG[key] = value
	end
end

local function setup_camera_shaker()
	if camShake then camShake:Stop() end
	camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
		camera.CFrame = camera.CFrame * shakeCFrame
	end)
	camShake:Start()
end

local function update_raycast_filter()
	local filter = { character }
	local debrisFolder = workspace:FindFirstChild("Debris")
	if debrisFolder then
		table.insert(filter, debrisFolder)
	end
	raycastParams.FilterDescendantsInstances = filter
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
end

local function single_ray(origin, direction)
	local hit = workspace:Raycast(origin, direction, raycastParams)
	if hit then
		return hit.Distance, hit
	end
	return math.huge, nil
end

local function raycast_ground()
	if not rootPart or not rootPart.Parent or not humanoid or not humanoid.Parent then
		return last_ground_distance
	end

	update_raycast_filter()

	local rootPos = rootPart.Position
	local rootHalf = rootPart.Size.Y * 0.5
	local hipOffset = humanoid.HipHeight + rootHalf
	local downDir = Vector3.new(0, -CONFIG.RAY_LEN, 0)

	local centerDist, centerHit = single_ray(rootPos, downDir)

	local offsets = {
		Vector3.new(CONFIG.RAY_OFFSET, 0, 0),
		Vector3.new(-CONFIG.RAY_OFFSET, 0, 0),
		Vector3.new(0, 0, CONFIG.RAY_OFFSET),
		Vector3.new(0, 0, -CONFIG.RAY_OFFSET),
	}

	local bestDist = centerDist
	local bestHit = centerHit

	for _, offset in offsets do
		local dist, hit = single_ray(rootPos + offset, downDir)
		if dist < bestDist then
			bestDist = dist
			bestHit = hit
		end
	end

	if bestHit then
		last_ground_hit_pos = bestHit.Position
		last_ground_hit_normal = bestHit.Normal

		local hitPart = bestHit.Instance
		local isBlockZone = false
		if hitPart then
			local check = hitPart
			while check and check ~= workspace do
				if check:GetAttribute("Block") then
					isBlockZone = true
					break
				end
				check = check.Parent
			end
		end
		state.on_block_zone = isBlockZone

		local dist = bestDist - hipOffset
		dist = math.max(dist, 0)
		last_ground_distance = dist
		return dist
	end

	state.on_block_zone = false
	last_ground_distance = CONFIG.RAY_LEN
	return CONFIG.RAY_LEN
end

local function calculate_peak_height(velocity)
	local g = workspace.Gravity
	if g <= 0 then g = 196.2 end
	return (velocity ^ 2) / (2 * g)
end

local function stop_jump_anim()
	animToken += 1
	if animHeartbeatConn then
		animHeartbeatConn:Disconnect()
		animHeartbeatConn = nil
	end
	if jumpTrack then
		jumpTrack:Stop(0.1)
	end
end

local function play_jump_anim_forward()
	if not jumpTrack then return end
	animToken += 1
	local token = animToken

	if animHeartbeatConn then
		animHeartbeatConn:Disconnect()
		animHeartbeatConn = nil
	end

	if not jumpTrack.IsPlaying then
		jumpTrack:Play(0.1)
	end

	jumpTrack:AdjustSpeed(1)
	jumpTrack.TimePosition = math.max(jumpTrack.TimePosition, 0)

	animHeartbeatConn = RunService.Heartbeat:Connect(function()
		if not jumpTrack or token ~= animToken then return end
		local len = jumpTrack.Length
		if len and len > 0 then
			if jumpTrack.TimePosition >= (len - 0.03) then
				jumpTrack.TimePosition = math.max(len - 0.001, 0)
				jumpTrack:AdjustSpeed(0)
			end
		end
	end)
end

local function play_jump_anim_reverse()
	if not jumpTrack then return end
	animToken += 1
	local token = animToken

	if animHeartbeatConn then
		animHeartbeatConn:Disconnect()
		animHeartbeatConn = nil
	end

	if not jumpTrack.IsPlaying then
		jumpTrack:Play(0.1)
	end

	local len = jumpTrack.Length
	if len and len > 0 then
		if jumpTrack.TimePosition <= 0.02 then
			jumpTrack.TimePosition = math.max(len - 0.001, 0)
		end
	end

	jumpTrack:AdjustSpeed(-1)

	animHeartbeatConn = RunService.Heartbeat:Connect(function()
		if not jumpTrack or token ~= animToken then return end
		if jumpTrack.TimePosition <= 0.02 then
			jumpTrack.TimePosition = 0
			jumpTrack:AdjustSpeed(0)
		end
	end)
end

local function trigger_landing_vfx(impactForce, isCritical)
	if not CONFIG.crater_enabled then return end
	if is_afk_mode then return end
	if not last_ground_hit_pos or not last_ground_hit_normal then return end

	local layerData = get_layer_by_height(character)
	if not layerData then return end

	local resistance = layerData.minBreakForce or 40
	local rawForce = math.abs(impactForce)
	if rawForce < resistance then return end

	local effectiveForce = math.max(0, rawForce - resistance)
	local tBase = math.clamp(effectiveForce / 200, 0, 1)

	local tExtended = 0
	if effectiveForce > 200 then
		tExtended = math.log(1 + (effectiveForce - 200) / 150)
	end

	local tTotal = tBase + tExtended
	local tCurve = tBase ^ 0.65

	local critMult = 1.0
	if isCritical then
		critMult = CONFIG.critical_vfx_mult + (tTotal * 0.2)
	end

	local radius = CONFIG.crater_radius_min
		+ (CONFIG.crater_radius_max - CONFIG.crater_radius_min) * tCurve
		+ (tExtended * 3.0)
	radius *= critMult

	local centerCFrame = CFrame.new(last_ground_hit_pos + Vector3.new(0, 1.5, 0))

	local minRocks = 4 + math.floor(4 * tCurve) + math.floor(tExtended * 2)
	local maxRocks = 6 + math.floor(6 * tCurve) + math.floor(tExtended * 3)

	if isCritical then
		minRocks = math.floor(minRocks * 1.4)
		maxRocks = math.floor(maxRocks * 1.4)
	end

	minRocks = math.min(minRocks, 18)
	maxRocks = math.min(maxRocks, 25)

	RockModule.Crater(centerCFrame, radius, minRocks, maxRocks, false)

	if tBase > 0.15 or isCritical then
		local debrisBase = 3 + math.floor(4 * tCurve)
		local debrisExtra = math.floor(tExtended * 2)
		local numExplosion = debrisBase + debrisExtra
		if isCritical then numExplosion = math.floor(numExplosion * 1.3) end
		numExplosion = math.min(numExplosion, 16)

		local szMin = 0.3 + (tCurve * 0.2) + (tExtended * 0.1)
		local szMax = 0.8 + (tCurve * 1.0) + (tExtended * 0.5)
		if isCritical then
			szMin *= 1.2
			szMax *= 1.3
		end

		RockModule.Explosion(centerCFrame, numExplosion, szMin, szMax, false)

		if tTotal > 0.7 or isCritical then
			local secondaryCount = math.floor(numExplosion * 0.3)
			secondaryCount = math.min(secondaryCount, 8)

			local spread = radius * 0.4
			local offsetX = (math.random() - 0.5) * spread * 2
			local offsetZ = (math.random() - 0.5) * spread * 2
			local secondaryCFrame = centerCFrame + Vector3.new(offsetX, 0, offsetZ)

			RockModule.Explosion(secondaryCFrame, secondaryCount, szMin * 0.5, szMax * 0.6, false)
		end
	end

	if tExtended > 1.0 then
		local extraRows = math.min(math.floor(tExtended * 0.5), 2)
		if extraRows > 0 then
			local rowRadius = radius + 3
			local rowRocksMin = math.min(math.floor(minRocks * 0.4), 8)
			local rowRocksMax = math.min(math.floor(maxRocks * 0.4), 12)
			for row = 1, extraRows do
				task.delay(row * 0.08, function()
					local r = rowRadius + (row * 2.5)
					RockModule.Crater(centerCFrame, r, rowRocksMin, rowRocksMax, false)
				end)
			end
		end
	end
end

local function apply_stun()
	if state.is_stunned then return end
	state.is_stunned = true

	if pogoEvent then pogoEvent:FireServer("Stunned", {}) end

	PopupModule.Create(rootPart, "CRASH!", Color3.fromRGB(255, 50, 50), {
		IsCritical = true,
		Direction = Vector3.new(0, 2, 0),
	})

	local attr = player:GetAttribute("Multiplier")
	local multi = (attr and attr > 0 and attr or 1)

	local maxShakeMagnitude = 6
	local maxShakeRoughness = 12
	local maxDuration = 1.5

	local magnitude = math.clamp(3.5 * (multi * 0.2), 3, maxShakeMagnitude)
	local roughness = math.clamp(8 * multi, 2, maxShakeRoughness)

	if camShake then
		camShake:ShakeOnce(magnitude, roughness, 0.1, maxDuration)
	end

	humanoid.WalkSpeed = CONFIG.stun_walkspeed

	task.delay(CONFIG.stun_duration, function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = state.original_walkspeed
		end
		state.is_stunned = false
		if pogoEvent then pogoEvent:FireServer("Land", { status = "Idle" }) end
	end)
end

local function lock_text_visuals()
	promptLabel.Visible = true
	vignette.ImageColor3 = Color3.new(0, 0, 0)
	whiteVignette.ImageColor3 = Color3.new(1, 1, 1)
end

local function get_move_direction()
	local moveDir = humanoid.MoveDirection
	local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z)

	if flatDir.Magnitude > 0.1 then
		return flatDir.Unit
	end

	local lookVector = rootPart.CFrame.LookVector
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)

	if flatLook.Magnitude > 0.1 then
		return flatLook.Unit
	end

	return Vector3.new(0, 0, -1)
end

local function apply_forward_momentum(finalPower, isPerfect)
	if not rootPart or not rootPart.Parent then return end

	local moveDir = get_move_direction()

	local forwardSpeed = finalPower * CONFIG.forward_base_mult
	local comboBonus = state.current_combo * CONFIG.forward_combo_mult * finalPower
	forwardSpeed += comboBonus

	if isPerfect then
		forwardSpeed *= CONFIG.forward_perfect_bonus
	end

	forwardSpeed = math.min(forwardSpeed, CONFIG.forward_max_speed)

	local humanoidMoveDir = humanoid.MoveDirection
	local isMoving = Vector3.new(humanoidMoveDir.X, 0, humanoidMoveDir.Z).Magnitude > 0.1

	if not isMoving then
		forwardSpeed *= 0.15
	end

	local currentVel = rootPart.AssemblyLinearVelocity
	local horizontalBoost = moveDir * forwardSpeed

	rootPart.AssemblyLinearVelocity = Vector3.new(
		currentVel.X + horizontalBoost.X,
		currentVel.Y,
		currentVel.Z + horizontalBoost.Z
	)
end

local function perform_jump(isPerfectRebound, isChained)
	if not rootPart or not rootPart.Parent or not humanoid or not humanoid.Parent then return end
	if state.is_stunned then return end
	if state.on_block_zone then return end

	if not isPerfectRebound then
		local currentJumps = player:GetAttribute("Jumps") or 0
		player:SetAttribute("Jumps", (currentJumps) + 1)
	end

	SoundController.PlaySFX(SoundData.SFX.Jump, rootPart)

	state.last_jump_time = os.clock()
	debug_last_jump_start = state.last_jump_time
	state.jump_grace_time = os.clock() + 0.25 
	state.is_falling = false
	state.was_airborne = false
	state.landed_frames = 0

	play_jump_anim_forward()

	local scaledBasePower = CONFIG.base_jump_power * CONFIG.POWER_SCALE
	local finalPower = 0

	local comboBonus = state.current_combo * CONFIG.combo_bonus_power

	if isPerfectRebound then
		finalPower = scaledBasePower * 1.4
	else
		finalPower = scaledBasePower + comboBonus
		local visualBar = math.clamp(state.visual_bar_pct, 0, 1)
		local timingMultiplier = 1.5 - visualBar
		finalPower *= timingMultiplier
	end

	local scaledBase = CONFIG.base_jump_power * CONFIG.POWER_SCALE
	local maxComboExtra = CONFIG.max_combo_power_cap
	local basePlusCap = scaledBase + maxComboExtra
	finalPower = math.min(finalPower, basePlusCap)

	local velocityLimited = finalPower / math.sqrt(CONFIG.gravity_mult)
	state.current_jump_peak = math.max(calculate_peak_height(velocityLimited), 10)

	local currentVel = rootPart.AssemblyLinearVelocity

	-- 1. Forçar posição para cima (Quebra o atrito imediatamente)
	rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 0.4, 0)

	-- 2. Aplicar a velocidade
	local targetVel = Vector3.new(currentVel.X, velocityLimited, currentVel.Z)
	rootPart.AssemblyLinearVelocity = targetVel

	-- 3. Forçar o estado Jumping
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	-- 4. Trava de Segurança (Force Sustain Loop)
	task.spawn(function()
		local startTime = os.clock()
		local duration = 0.1 -- 6 Frames de proteção

		while (os.clock() - startTime) < duration do
			local dt = RunService.Heartbeat:Wait()
			if rootPart and rootPart.AssemblyLinearVelocity.Y < (velocityLimited * 0.8) then
				local fixVel = rootPart.AssemblyLinearVelocity
				rootPart.AssemblyLinearVelocity = Vector3.new(fixVel.X, velocityLimited, fixVel.Z)
			end
		end
	end)

	apply_forward_momentum(finalPower, isPerfectRebound)

	state.is_grounded = false

	local TutorialEvent = ReplicatedStorage.Modules.Utility:FindFirstChild("TutorialEvent")

	if isPerfectRebound then
		if TutorialEvent then TutorialEvent:Fire("PerfectJump") end

		state.current_combo += 1
		local comboColor = Color3.fromRGB(255, 200, 50)
		local isHighCombo = false
		if state.current_combo >= 5 then
			comboColor = Color3.fromRGB(255, 100, 255)
			isHighCombo = true
		end

		PopupModule.Create(rootPart, "x" .. state.current_combo, comboColor, {
			Direction = Vector3.new(math.random(-2, 2), 2, 0),
			Spread = 1,
			IsCritical = isHighCombo,
		})

		whiteVignette.ImageColor3 = Color3.new(1, 1, 1)
		state.visual_white_vignette = 0.2

		if pogoEvent then
			pogoEvent:FireServer("Rebound", {
				combo = state.current_combo,
				isCritical = true,
				impactForce = math.abs(last_falling_velocity),
			})
		end
	else
		if TutorialEvent then TutorialEvent:Fire("Jump") end

		if state.current_combo > 0 then
			PopupModule.Create(rootPart, "x0", Color3.fromRGB(255, 80, 80), {
				Direction = Vector3.new(0, 2, 0),
				Spread = 1,
				IsCritical = false,
			})
		end

		state.current_combo = 0
		if pogoEvent then
			pogoEvent:FireServer("Jump", { impactForce = math.abs(last_falling_velocity) })
		end
	end

	state.can_rebound = false
	state.queued_jump = false
	state.visual_perfect_size = 0
	perfectZone.Visible = false
	barFill.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
end

local function land()
	local timeSinceJump = os.clock() - debug_last_jump_start

	local visualImpact = last_falling_velocity * 0.8
	state.is_falling = false

	stop_jump_anim()

	local currentVel = rootPart.AssemblyLinearVelocity
	local horizSpeed = Vector3.new(currentVel.X, 0, currentVel.Z).Magnitude

	if state.queued_jump and not state.is_stunned and not state.on_block_zone then
		perform_jump(true, true)
		trigger_landing_vfx(math.abs(last_falling_velocity), true)
		return
	elseif (is_jump_held or (auto_jump_active and has_auto_jump_pass)) and not state.is_stunned and not state.on_block_zone then
		perform_jump(false, true)
		trigger_landing_vfx(math.abs(last_falling_velocity), false)
		return
	end

	if state.is_grounded then return end

	if state.on_block_zone then
		state.is_grounded = true
		state.can_rebound = false
		state.queued_jump = false
		state.current_combo = 0
		state.cooldown_end_time = 0
		if pogoEvent then pogoEvent:FireServer("Land", { status = "Blocked", impactForce = math.abs(last_falling_velocity) }) end
		return
	end

	trigger_landing_vfx(math.abs(last_falling_velocity), false)

	local landingForce = math.abs(last_falling_velocity)

	if last_falling_velocity < -40 then
		apply_stun()
		if pogoEvent then pogoEvent:FireServer("Land", { status = "Stunned", impactForce = landingForce }) end
	else
		if pogoEvent then pogoEvent:FireServer("Land", { status = "Cooldown", impactForce = landingForce }) end
	end

	state.is_grounded = true
	state.can_rebound = false
	state.current_combo = 0
	state.cooldown_end_time = os.clock() + CONFIG.miss_penalty_duration
end

local function handle_input()
	local now = os.clock()
	if state.is_stunned then return end
	if state.on_block_zone then return end

	if state.is_grounded then
		if now < state.cooldown_end_time then return end
		perform_jump(false, false)
		return
	end

	if state.can_rebound then
		state.queued_jump = true
		barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end
end

------------------//MAIN FUNCTIONS

local function check_grounded(dt)
	local rawDist = state.raw_ground_distance
	local velY = rootPart.AssemblyLinearVelocity.Y
	local absVelY = math.abs(velY)

	local nearGround = rawDist < CONFIG.RAY_LAND_THRESH
	local lowVerticalVel = absVelY < CONFIG.RAY_VEL_THRESH

	if nearGround and lowVerticalVel then
		state.landed_frames += 1
	else
		state.landed_frames = 0
	end

	return state.landed_frames >= CONFIG.RAY_FRAMES
end

local function update_loop(dt)
	if not rootPart or not rootPart.Parent or not humanoid or not humanoid.Parent then return end

	if auto_jump_active then
		if (os.clock() - auto_jump_start_time) > 300 then
			if not is_afk_mode then
				is_afk_mode = true
				NotificationUtility:Warning("You seem AFK. Destruction VFX disabled for performance.", 5)
			end
		end
	else
		auto_jump_start_time = os.clock()
		if is_afk_mode then
			is_afk_mode = false
			NotificationUtility:Success("Welcome back! VFX Enabled.", 4)
		end
	end

	local velocity = rootPart.AssemblyLinearVelocity
	local speedTotal = velocity.Magnitude
	local now = os.clock()

	local rawDist = raycast_ground()
	state.raw_ground_distance = rawDist

	smooth_ground_distance = exp_lerp(smooth_ground_distance, rawDist, CONFIG.SMOOTH_DIST, dt)
	state.distance_to_ground = smooth_ground_distance

	if not state.is_grounded then
		state.was_airborne = true

		-- [NOVA LÓGICA DE PARKOUR: AIR VELOCITY]
		-- Controla o movimento aéreo baseado no input do jogador
		local moveDir = humanoid.MoveDirection
		if moveDir.Magnitude > 0.1 then
			-- Pega a velocidade horizontal atual
			local flatVel = Vector3.new(velocity.X, 0, velocity.Z)

			-- Calcula a direção desejada multiplicada pela velocidade atual (para manter momento) 
			-- ou pela velocidade base se estiver parado
			local speed = math.max(flatVel.Magnitude, 20) 
			speed = math.min(speed, CONFIG.air_max_speed) -- Cap na velocidade

			local targetVel = moveDir * speed

			-- Interpola suavemente a velocidade atual para a nova direção (Isso cria a curva)
			-- O fator dt * CONFIG.air_mobility define quão fechada é a curva
			local newFlatVel = flatVel:Lerp(targetVel, dt * (CONFIG.air_mobility / 10))

			-- Aplica mantendo o Y (gravidade) intocado
			rootPart.AssemblyLinearVelocity = Vector3.new(newFlatVel.X, velocity.Y, newFlatVel.Z)
		end
		-- [FIM DA LÓGICA DE AIR VELOCITY]

		if now > state.jump_grace_time then
			if check_grounded(dt) then
				land()
			end
		end
	else
		state.was_airborne = false
		state.landed_frames = 0
	end

	if state.is_grounded and not state.on_block_zone and (is_jump_held or (auto_jump_active and has_auto_jump_pass)) and not state.is_stunned then
		if now >= state.cooldown_end_time then perform_jump(false, true) end
	end

	if velocity.Y < 0 then
		last_falling_velocity = velocity.Y
		if not state.is_grounded and not state.is_falling and velocity.Y < -5 then
			state.is_falling = true
			play_jump_anim_reverse()
		end
	else
		if not state.is_grounded then
			state.is_falling = false
		end
	end

	local targetFov = CONFIG.fov_base
	local targetBarPct = 0
	local targetPerfectSize = 0
	local targetScale = 1

	barFill.BackgroundTransparency = 0
	perfectZone.BackgroundTransparency = 0

	barContainer.Rotation = exp_lerp(barContainer.Rotation, 0, CONFIG.SMOOTH_BAR, dt)

	local targetVignetteTransparency = 1
	if velocity.Y > 10 then
		local speedFactor = math.clamp((velocity.Y - 10) / 100, 0, 0.6)
		targetVignetteTransparency = 1 - speedFactor
	end
	vignette.ImageTransparency = exp_lerp(vignette.ImageTransparency, targetVignetteTransparency, CONFIG.SMOOTH_VIGNETTE, dt)

	local targetWhiteTransparency = 1
	local targetWhiteColor = Color3.new(1, 1, 1)

	if auto_jump_active then
		targetWhiteTransparency = 0.5
		targetWhiteColor = Color3.fromRGB(50, 255, 100)
	end

	whiteVignette.ImageColor3 = whiteVignette.ImageColor3:Lerp(targetWhiteColor, dt * 5)
	state.visual_white_vignette = exp_lerp(state.visual_white_vignette, targetWhiteTransparency, CONFIG.SMOOTH_VIGNETTE, dt)
	whiteVignette.ImageTransparency = state.visual_white_vignette

	if state.is_grounded then
		if state.on_block_zone then
			promptLabel.Text = "BLOCKED!"
			targetScale = 1
			targetBarPct = 1
			barFill.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		elseif now < state.cooldown_end_time or state.is_stunned then
			promptLabel.Text = "JUMP!"
			targetScale = 1
			local remaining = state.cooldown_end_time - now
			local duration = state.is_stunned and CONFIG.stun_duration or CONFIG.miss_penalty_duration
			targetBarPct = math.clamp(remaining / duration, 0, 1)
			barFill.BackgroundColor3 = Color3.fromRGB(110, 125, 145)
		else
			promptLabel.Text = "JUMP!"
			targetScale = 1
			targetBarPct = 0
			if auto_jump_active then
				barFill.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
			else
				barFill.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
			end
		end
	else
		local safePeak = math.max(state.current_jump_peak, 5)
		targetBarPct = math.clamp(smooth_ground_distance / safePeak, 0, 1)
		targetPerfectSize = CONFIG.perfect_zone_percent

		if velocity.Y > 0 then
			promptLabel.Text = "WAIT..."
			targetScale = 1.0

			if auto_jump_active then
				barFill.BackgroundColor3 = is_jump_held and Color3.fromRGB(30, 180, 60) or Color3.fromRGB(50, 255, 100)
			else
				barFill.BackgroundColor3 = is_jump_held and Color3.fromRGB(0, 60, 180) or Color3.fromRGB(0, 190, 255)
			end

		elseif velocity.Y < -5 then
			local inWindow = targetBarPct <= CONFIG.perfect_zone_percent

			if inWindow then
				state.can_rebound = true
				promptLabel.Text = "TAP NOW!"
				barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

				local pulse = (math.sin(now * 20) * 0.05) + 1.3
				targetScale = pulse
			else
				state.can_rebound = false
				state.queued_jump = false
				promptLabel.Text = "PREPARE..."

				local tensionFactor = math.clamp(1 - targetBarPct, 0, 1)
				targetScale = 1 + (tensionFactor * 0.15)

				if auto_jump_active then
					barFill.BackgroundColor3 = is_jump_held and Color3.fromRGB(30, 180, 60) or Color3.fromRGB(50, 255, 100)
				else
					barFill.BackgroundColor3 = is_jump_held and Color3.fromRGB(0, 60, 180) or Color3.fromRGB(0, 190, 255)
				end
			end
		else
			promptLabel.Text = "WAIT..."
			targetScale = 1.0
			state.can_rebound = false

			if auto_jump_active then
				barFill.BackgroundColor3 = is_jump_held and Color3.fromRGB(30, 180, 60) or Color3.fromRGB(50, 255, 100)
			else
				barFill.BackgroundColor3 = is_jump_held and Color3.fromRGB(0, 60, 180) or Color3.fromRGB(0, 190, 255)
			end
		end
	end

	local containerScale = barContainer:FindFirstChild("UIScale")
	if not containerScale then
		containerScale = Instance.new("UIScale")
		containerScale.Parent = barContainer
	end
	containerScale.Scale = exp_lerp(containerScale.Scale, targetScale, 20, dt)

	state.visual_bar_pct = exp_lerp(state.visual_bar_pct, targetBarPct, CONFIG.SMOOTH_BAR, dt)
	barFill.Size = UDim2.new(math.clamp(state.visual_bar_pct, 0, 1), 0, 1, 0)

	state.visual_perfect_size = exp_lerp(state.visual_perfect_size, targetPerfectSize, CONFIG.SMOOTH_PERFECT, dt)
	local clampedPerfectSize = math.min(state.visual_perfect_size, state.visual_bar_pct)

	if not state.is_grounded and clampedPerfectSize > 0.001 then
		perfectZone.Size = UDim2.new(clampedPerfectSize, 0, 1, 0)
		perfectZone.Visible = true
		perfectZone.BackgroundColor3 = Color3.fromRGB(100, 220, 255)
	else
		perfectZone.Visible = false
	end

	if speedTotal > 10 then
		local percent = math.clamp(speedTotal / 200, 0, 1)
		targetFov = CONFIG.fov_base + (CONFIG.fov_max - CONFIG.fov_base) * percent
	end
	state.visual_fov = exp_lerp(state.visual_fov, targetFov, CONFIG.SMOOTH_FOV, dt)
	camera.FieldOfView = state.visual_fov
end

local function bind_character(newCharacter)
	character = newCharacter
	rootPart = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")

	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0

	update_raycast_filter()
	apply_rebirth_upgrades()

	task.spawn(function()
		pcall(function()
			local touchGui = playerGui:WaitForChild("TouchGui", 5)
			if touchGui then
				local touchFrame = touchGui:FindFirstChild("TouchControlFrame")
				if touchFrame then
					local jumpBtn = touchFrame:FindFirstChild("JumpButton")
					if jumpBtn then
						jumpBtn.Visible = false
					end
				end
			end
		end)
	end)

	state.is_grounded = true
	state.current_combo = 0
	state.distance_to_ground = 0
	state.raw_ground_distance = 0
	state.can_rebound = false
	state.queued_jump = false
	state.visual_bar_pct = 0
	state.visual_perfect_size = 0
	state.visual_white_vignette = 1
	state.last_jump_time = 0
	state.jump_grace_time = 0
	state.cooldown_end_time = 0
	state.is_stunned = false
	state.current_jump_peak = CONFIG.visual_max_height
	state.is_falling = false
	state.was_airborne = false
	state.landed_frames = 0
	state.on_block_zone = false

	last_falling_velocity = 0
	last_ground_distance = 0
	smooth_ground_distance = 0
	last_ground_hit_pos = nil
	last_ground_hit_normal = nil

	lock_text_visuals()
	setup_camera_shaker()

	gravityApplied = false
	apply_gravity_from_settings()

	animToken += 1
	if animHeartbeatConn then
		animHeartbeatConn:Disconnect()
		animHeartbeatConn = nil
	end

	if jumpTrack then
		jumpTrack:Stop(0)
		jumpTrack = nil
	end

	jumpAnimation = Instance.new("Animation")
	jumpAnimation.AnimationId = CONFIG.ANIM_ID
	jumpTrack = humanoid:LoadAnimation(jumpAnimation)
	jumpTrack.Looped = false
	jumpTrack.Priority = Enum.AnimationPriority.Action

	if humanoidStateConn then
		humanoidStateConn:Disconnect()
		humanoidStateConn = nil
	end

	humanoidStateConn = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			land()
		elseif newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
			state.is_grounded = false
			state.landed_frames = 0
		end
	end)
end

------------------//INIT

task.wait(2)

DataUtility.client.ensure_remotes()

local initialSettings = DataUtility.client.get("PogoSettings")
update_local_settings(initialSettings)
apply_gravity_from_settings()

DataUtility.client.bind("PogoSettings", function(newSettings)
	update_local_settings(newSettings)
end)

DataUtility.client.bind("PogoSettings.base_jump_power", function(newPower)
	CONFIG.base_jump_power = newPower
end)

DataUtility.client.bind("PogoSettings.gravity_mult", function(newMult)
	CONFIG.gravity_mult = newMult
	gravityApplied = false
end)

DataUtility.client.bind("OwnedRebirthUpgrades", function()
	apply_rebirth_upgrades()
end)

barFill.AnchorPoint = Vector2.new(0, 0)
barFill.Position = UDim2.new(0, 0, 0, 0)
barFill.Size = UDim2.new(0, 0, 1, 0)

perfectZone.AnchorPoint = Vector2.new(0, 0)
perfectZone.Position = UDim2.new(0, 0, 0, 0)
perfectZone.Size = UDim2.new(0, 0, 1, 0)

lock_text_visuals()

last_ground_distance = CONFIG.visual_max_height
smooth_ground_distance = CONFIG.visual_max_height

bind_character(character)

player.CharacterAdded:Connect(function(newCharacter)
	bind_character(newCharacter)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, wasPurchased)
	if plr == player and wasPurchased then
		if passId == CONFIG.PASS_AUTO then
			has_auto_jump_pass = true
			if autoJumpButton then autoJumpButton.Visible = true end
		elseif passId == CONFIG.PASS_EASY then
			CONFIG.perfect_zone_percent = 0.5
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.Touch then
		is_jump_held = true
		handle_input()
	end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.Touch then
		is_jump_held = false
	end
end)

if jumpButton then
	jumpButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			is_jump_held = true
			handle_input()
		end
	end)

	jumpButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			is_jump_held = false
		end
	end)
end

if autoJumpButton then
	autoJumpButton.MouseButton1Click:Connect(function()
		if not has_auto_jump_pass then
			MarketplaceService:PromptGamePassPurchase(player, CONFIG.PASS_AUTO)
			return
		end

		auto_jump_active = not auto_jump_active

		local targetSize = auto_jump_active and UDim2.new(1.2, 0, 1.2, 0) or UDim2.new(1, 0, 1, 0)
		TweenService:Create(autoJumpButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = targetSize,
		}):Play()
	end)
end

task.spawn(function()
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, CONFIG.PASS_AUTO)
	end)

	if success and owns then
		has_auto_jump_pass = true
		if autoJumpButton then
			autoJumpButton.Visible = true
		end
	end
end)

RunService:BindToRenderStep(CONFIG.RENDER_STEP, Enum.RenderPriority.Camera.Value + 1, update_loop)
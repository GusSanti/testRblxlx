local Players: Players = game:GetService("Players")
local UserInputService: UserInputService = game:GetService("UserInputService")
local RunService: RunService = game:GetService("RunService")
local TweenService: TweenService = game:GetService("TweenService")
local Debris: Debris = game:GetService("Debris")

local MATCH_WORKSPACE_ATTRIBUTE_NAME = "IsMatch"
local ATTR_AIMING = "GS_IsAiming"
local ATTR_MOVEMENT_BASE_WALK_SPEED = "GS_MovementBaseWalkSpeed"
local ATTR_MOVEMENT_IS_RUNNING = "GS_IsRunning"
local ATTR_STOP_RUN_TOKEN = "GS_StopRunToken"
local ROLL_KEY = Enum.KeyCode.LeftControl
local RUN_KEY = Enum.KeyCode.LeftShift
local CROUCH_KEY = Enum.KeyCode.C
local ROLL_SPEED = 38
local ROLL_DURATION = 0.34
local ROLL_COOLDOWN = 1.5
local RUN_SPEED = 26
local CROUCH_SPEED = 8
local RUN_ANIMATION_ID = "rbxassetid://128856433555607"
local CROUCH_IDLE_ANIMATION_ID = "rbxassetid://116962240298946"
local CROUCH_WALK_ANIMATION_ID = "rbxassetid://96711343176078"
local AFTERIMAGE_COUNT = 4
local AFTERIMAGE_LIFETIME = 0.18

local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local character: Model? = nil
local humanoid: Humanoid? = nil
local rootPart: BasePart? = nil
local rollAttachment: Attachment? = nil
local alignAttachment: Attachment? = nil
local alignOrientation: AlignOrientation? = nil
local rollTrail: Trail? = nil
local rollParticle: ParticleEmitter? = nil
local rollSound: Sound? = nil
local runAnimation: Animation? = nil
local runAnimationTrack: AnimationTrack? = nil
local crouchIdleAnimation: Animation? = nil
local crouchWalkAnimation: Animation? = nil
local crouchIdleTrack: AnimationTrack? = nil
local crouchWalkTrack: AnimationTrack? = nil

local rollGui: ScreenGui? = nil
local rollButton: TextButton? = nil
local cooldownOverlay: Frame? = nil

local isRolling = false
local isRunKeyDown = false
local isCrouchKeyDown = false
local isRunning = false
local isCrouching = false
local baseWalkSpeed = 16
local cooldownEndsAt = 0
local bodyCollisionCache: { [BasePart]: boolean } = {}
local isMatchActive = false

local function is_mobile_device(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
end

local function is_aiming(): boolean
	if player:GetAttribute(ATTR_AIMING) ~= true then
		return false
	end

	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

local function sync_movement_attributes(): ()
	local currentHumanoid = humanoid

	if not currentHumanoid then
		return
	end

	currentHumanoid:SetAttribute(ATTR_MOVEMENT_BASE_WALK_SPEED, baseWalkSpeed)
	currentHumanoid:SetAttribute(ATTR_MOVEMENT_IS_RUNNING, isRunning)
end

local function set_base_walk_speed(speed: number): ()
	baseWalkSpeed = speed
	sync_movement_attributes()
end

local function set_running(running: boolean): ()
	isRunning = running
	sync_movement_attributes()
end

local function get_horizontal_vector(vector: Vector3): Vector3
	local horizontal = Vector3.new(vector.X, 0, vector.Z)

	if horizontal.Magnitude <= 0.001 then
		return Vector3.new(0, 0, -1)
	end

	return horizontal.Unit
end

local function get_camera_basis(): (Vector3, Vector3)
	local currentRootPart = rootPart
	local currentCamera = workspace.CurrentCamera

	if not currentCamera then
		if currentRootPart then
			return get_horizontal_vector(currentRootPart.CFrame.LookVector), get_horizontal_vector(currentRootPart.CFrame.RightVector)
		end

		return Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)
	end

	local forward = get_horizontal_vector(currentCamera.CFrame.LookVector)
	local right = get_horizontal_vector(currentCamera.CFrame.RightVector)
	return forward, right
end

local function get_roll_direction(): Vector3
	local currentHumanoid = humanoid

	if not currentHumanoid then
		return Vector3.new(0, 0, -1)
	end

	local forward, right = get_camera_basis()
	local moveDirection = currentHumanoid.MoveDirection

	if moveDirection.Magnitude < 0.1 then
		return forward
	end

	local inputDirection = get_horizontal_vector(moveDirection)
	local x = inputDirection:Dot(right)
	local z = inputDirection:Dot(forward)

	if math.abs(x) >= math.abs(z) then
		if x >= 0 then
			return right
		end

		return -right
	end

	if z >= 0 then
		return forward
	end

	return -forward
end

local function stop_run_animation(): ()
	local track = runAnimationTrack

	if track and track.IsPlaying then
		track:Stop(0.12)
	end
end

local function stop_crouch_animations(): ()
	local idleTrack = crouchIdleTrack
	local walkTrack = crouchWalkTrack

	if idleTrack and idleTrack.IsPlaying then
		idleTrack:Stop(0.12)
	end

	if walkTrack and walkTrack.IsPlaying then
		walkTrack:Stop(0.12)
	end
end

local function update_movement_state(): ()
	local currentHumanoid = humanoid

	if not currentHumanoid then
		return
	end

	if currentHumanoid.Health <= 0 then
		if isRunning or isCrouching then
			currentHumanoid.WalkSpeed = baseWalkSpeed
		end
		set_running(false)
		isCrouching = false
		stop_run_animation()
		stop_crouch_animations()
		return
	end

	if isRolling then
		stop_run_animation()
		stop_crouch_animations()
		return
	end

	local aiming = is_aiming()
	local canRun = isMatchActive and isRunKeyDown and not aiming

	if canRun then
		if not isRunning then
			if not isCrouching then
				set_base_walk_speed(currentHumanoid.WalkSpeed)
			end
			set_running(true)
		end

		if isCrouching then
			isCrouching = false
			stop_crouch_animations()
		end

		currentHumanoid.WalkSpeed = RUN_SPEED

		local track = runAnimationTrack
		if track then
			if currentHumanoid.MoveDirection.Magnitude > 0.1 then
				if not track.IsPlaying then
					track:Play(0.12, 1, 1)
				end
			else
				if track.IsPlaying then
					track:Stop(0.12)
				end
			end
		end

		return
	end

	if isRunning then
		if not aiming then
			currentHumanoid.WalkSpeed = baseWalkSpeed
		end
		set_running(false)
	end

	stop_run_animation()

	local canCrouch = isCrouchKeyDown

	if canCrouch then
		if not isCrouching then
			set_base_walk_speed(currentHumanoid.WalkSpeed)
			isCrouching = true
		end

		currentHumanoid.WalkSpeed = CROUCH_SPEED

		local moving = currentHumanoid.MoveDirection.Magnitude > 0.1
		local idleTrack = crouchIdleTrack
		local walkTrack = crouchWalkTrack

		if moving then
			if idleTrack and idleTrack.IsPlaying then
				idleTrack:Stop(0.12)
			end

			if walkTrack and not walkTrack.IsPlaying then
				walkTrack:Play(0.12, 1, 1)
			end
		else
			if walkTrack and walkTrack.IsPlaying then
				walkTrack:Stop(0.12)
			end

			if idleTrack and not idleTrack.IsPlaying then
				idleTrack:Play(0.12, 1, 1)
			end
		end
	else
		if isCrouching then
			currentHumanoid.WalkSpeed = baseWalkSpeed
			isCrouching = false
		end

		stop_crouch_animations()
	end
end

local function stop_running_from_weapon(): ()
	local currentHumanoid = humanoid

	isRunKeyDown = false

	if currentHumanoid and isRunning then
		currentHumanoid.WalkSpeed = baseWalkSpeed
	end

	set_running(false)
	stop_run_animation()
	update_movement_state()
end

local function set_character_collision(enabled: boolean): ()
	local currentCharacter = character
	local currentRootPart = rootPart

	if not currentCharacter or not currentRootPart then
		return
	end

	if enabled then
		for part, oldValue in bodyCollisionCache do
			if part and part.Parent then
				part.CanCollide = oldValue
			end
		end

		table.clear(bodyCollisionCache)
		return
	end

	table.clear(bodyCollisionCache)

	for _, desc in currentCharacter:GetDescendants() do
		if desc:IsA("BasePart") and desc ~= currentRootPart then
			bodyCollisionCache[desc] = desc.CanCollide
			desc.CanCollide = false
		end
	end

	sync_movement_attributes()
end

local function spawn_afterimage(): ()
	local currentCharacter = character
	local currentRootPart = rootPart

	if not currentCharacter or not currentRootPart then
		return
	end

	local afterModel = Instance.new("Model")
	afterModel.Name = "RollAfterImage"
	afterModel.Parent = workspace

	for _, desc in currentCharacter:GetDescendants() do
		if desc:IsA("BasePart") and desc ~= currentRootPart then
			local ghostPart = Instance.new("Part")
			ghostPart.Name = "Ghost"
			ghostPart.Anchored = true
			ghostPart.CanCollide = false
			ghostPart.CanTouch = false
			ghostPart.CastShadow = false
			ghostPart.Material = Enum.Material.Neon
			ghostPart.Color = Color3.fromRGB(230, 240, 255)
			ghostPart.Transparency = 0.48
			ghostPart.Size = desc.Size
			ghostPart.CFrame = desc.CFrame
			ghostPart.Parent = afterModel

			for _, child in desc:GetChildren() do
				if child:IsA("SpecialMesh") or child:IsA("DataModelMesh") then
					child:Clone().Parent = ghostPart
				end
			end
		end
	end

	for _, ghost in afterModel:GetDescendants() do
		if ghost:IsA("BasePart") then
			local tween = TweenService:Create(
				ghost,
				TweenInfo.new(AFTERIMAGE_LIFETIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				{ Transparency = 1 }
			)
			tween:Play()
		end
	end

	Debris:AddItem(afterModel, AFTERIMAGE_LIFETIME + 0.05)
end

local function set_button_cooldown_state(): ()
	local button = rollButton
	local overlay = cooldownOverlay

	if not button or not overlay then
		return
	end

	if not isMatchActive then
		overlay.Visible = false
		button.Active = false
		button.AutoButtonColor = false
		return
	end

	if os.clock() >= cooldownEndsAt then
		overlay.Visible = false
		button.Active = true
		button.AutoButtonColor = true
		return
	end

	local remaining = math.max(0, cooldownEndsAt - os.clock())
	local alpha = math.clamp(remaining / ROLL_COOLDOWN, 0, 1)
	overlay.Visible = true
	overlay.BackgroundTransparency = 0.2 + (1 - alpha) * 0.65
	button.Active = false
	button.AutoButtonColor = false
end

local function setup_mobile_button(): ()
	if rollGui then
		rollGui:Destroy()
		rollGui = nil
		rollButton = nil
		cooldownOverlay = nil
	end

	if not is_mobile_device() then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "RollGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	rollGui = gui

	local button = Instance.new("TextButton")
	button.Name = "RollButton"
	button.Size = UDim2.new(0, 78, 0, 78)
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.15, 0, 0.79, 0)
	button.Text = "Roll"
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundColor3 = Color3.fromRGB(105, 110, 120)
	button.BorderSizePixel = 0
	button.Parent = gui
	rollButton = button

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(1, 0)
	buttonCorner.Parent = button

	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Thickness = 3
	buttonStroke.Color = Color3.fromRGB(58, 62, 70)
	buttonStroke.Parent = button

	local overlay = Instance.new("Frame")
	overlay.Name = "Cooldown"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	overlay.BackgroundTransparency = 0.8
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Parent = button
	cooldownOverlay = overlay

	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(1, 0)
	overlayCorner.Parent = overlay

	gui.Enabled = isMatchActive
end

local function setup_movement_animations_for_character(currentHumanoid: Humanoid): ()
	if runAnimationTrack then
		runAnimationTrack:Stop(0)
		runAnimationTrack:Destroy()
		runAnimationTrack = nil
	end

	if crouchIdleTrack then
		crouchIdleTrack:Stop(0)
		crouchIdleTrack:Destroy()
		crouchIdleTrack = nil
	end

	if crouchWalkTrack then
		crouchWalkTrack:Stop(0)
		crouchWalkTrack:Destroy()
		crouchWalkTrack = nil
	end

	if runAnimation then
		runAnimation:Destroy()
		runAnimation = nil
	end

	if crouchIdleAnimation then
		crouchIdleAnimation:Destroy()
		crouchIdleAnimation = nil
	end

	if crouchWalkAnimation then
		crouchWalkAnimation:Destroy()
		crouchWalkAnimation = nil
	end

	local animator = currentHumanoid:FindFirstChildOfClass("Animator") :: Animator?

	if not animator then
		local newAnimator = Instance.new("Animator")
		newAnimator.Parent = currentHumanoid
		animator = newAnimator
	end

	local runAnim = Instance.new("Animation")
	runAnim.Name = "RunAnimation"
	runAnim.AnimationId = RUN_ANIMATION_ID
	runAnim.Parent = currentHumanoid
	runAnimation = runAnim

	local runTrack = animator:LoadAnimation(runAnim)
	runTrack.Priority = Enum.AnimationPriority.Action
	runTrack.Looped = true
	runAnimationTrack = runTrack

	local crouchIdleAnim = Instance.new("Animation")
	crouchIdleAnim.Name = "CrouchIdleAnimation"
	crouchIdleAnim.AnimationId = CROUCH_IDLE_ANIMATION_ID
	crouchIdleAnim.Parent = currentHumanoid
	crouchIdleAnimation = crouchIdleAnim

	local idleTrack = animator:LoadAnimation(crouchIdleAnim)
	idleTrack.Priority = Enum.AnimationPriority.Action
	idleTrack.Looped = true
	crouchIdleTrack = idleTrack

	local crouchWalkAnim = Instance.new("Animation")
	crouchWalkAnim.Name = "CrouchWalkAnimation"
	crouchWalkAnim.AnimationId = CROUCH_WALK_ANIMATION_ID
	crouchWalkAnim.Parent = currentHumanoid
	crouchWalkAnimation = crouchWalkAnim

	local walkTrack = animator:LoadAnimation(crouchWalkAnim)
	walkTrack.Priority = Enum.AnimationPriority.Action
	walkTrack.Looped = true
	crouchWalkTrack = walkTrack

	set_base_walk_speed(currentHumanoid.WalkSpeed)
	isRunKeyDown = false
	isCrouchKeyDown = false
	set_running(false)
	isCrouching = false
	sync_movement_attributes()
end

local function setup_roll_effects_for_character(targetCharacter: Model): ()
	local currentHumanoid = targetCharacter:WaitForChild("Humanoid") :: Humanoid
	local currentRootPart = targetCharacter:WaitForChild("HumanoidRootPart") :: BasePart

	humanoid = currentHumanoid
	rootPart = currentRootPart

	setup_movement_animations_for_character(currentHumanoid)

	local oldRollAttachment = currentRootPart:FindFirstChild("RollAttachment")
	if oldRollAttachment and oldRollAttachment:IsA("Attachment") then
		oldRollAttachment:Destroy()
	end

	local oldAlignAttachment = currentRootPart:FindFirstChild("RollAlignAttachment")
	if oldAlignAttachment and oldAlignAttachment:IsA("Attachment") then
		oldAlignAttachment:Destroy()
	end

	local oldAlign = currentRootPart:FindFirstChild("RollAlign")
	if oldAlign and oldAlign:IsA("AlignOrientation") then
		oldAlign:Destroy()
	end

	local oldTrail = currentRootPart:FindFirstChild("RollTrail")
	if oldTrail and oldTrail:IsA("Trail") then
		oldTrail:Destroy()
	end

	local oldTrailA0 = currentRootPart:FindFirstChild("RollTrailA0")
	if oldTrailA0 and oldTrailA0:IsA("Attachment") then
		oldTrailA0:Destroy()
	end

	local oldTrailA1 = currentRootPart:FindFirstChild("RollTrailA1")
	if oldTrailA1 and oldTrailA1:IsA("Attachment") then
		oldTrailA1:Destroy()
	end

	local oldSound = currentRootPart:FindFirstChild("RollSound")
	if oldSound and oldSound:IsA("Sound") then
		oldSound:Destroy()
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "RollAttachment"
	attachment.Parent = currentRootPart
	rollAttachment = attachment

	local a0 = Instance.new("Attachment")
	a0.Name = "RollTrailA0"
	a0.Position = Vector3.new(0, -2, 0)
	a0.Parent = currentRootPart

	local a1 = Instance.new("Attachment")
	a1.Name = "RollTrailA1"
	a1.Position = Vector3.new(0, 2, 0)
	a1.Parent = currentRootPart

	local trail = Instance.new("Trail")
	trail.Name = "RollTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.24
	trail.MinLength = 0.04
	trail.Color = ColorSequence.new(Color3.fromRGB(220, 235, 255))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Enabled = false
	trail.Parent = currentRootPart
	rollTrail = trail

	local particle = Instance.new("ParticleEmitter")
	particle.Name = "RollParticle"
	particle.Texture = "rbxasset://textures/particles/smoke_main.dds"
	particle.Color = ColorSequence.new(Color3.fromRGB(215, 235, 255))
	particle.Lifetime = NumberRange.new(0.14, 0.26)
	particle.Rate = 65
	particle.Speed = NumberRange.new(3, 7)
	particle.SpreadAngle = Vector2.new(35, 35)
	particle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(1, 2.4),
	})
	particle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	particle.Enabled = false
	particle.Parent = attachment
	rollParticle = particle

	local sound = Instance.new("Sound")
	sound.Name = "RollSound"
	sound.SoundId = "rbxassetid://104492907784363"
	sound.Volume = 0.32
	sound.Parent = currentRootPart
	rollSound = sound

	local alignAttach = Instance.new("Attachment")
	alignAttach.Name = "RollAlignAttachment"
	alignAttach.Parent = currentRootPart
	alignAttachment = alignAttach

	local align = Instance.new("AlignOrientation")
	align.Name = "RollAlign"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = alignAttach
	align.MaxTorque = 1000000
	align.MaxAngularVelocity = 10000
	align.Responsiveness = 140
	align.Enabled = false
	align.Parent = currentRootPart
	alignOrientation = align
end

local function perform_roll(): ()
	local currentHumanoid = humanoid
	local currentRootPart = rootPart
	local currentAttachment = rollAttachment
	local currentAlign = alignOrientation

	if not currentHumanoid or not currentRootPart or not currentAttachment or not currentAlign then
		return
	end

	if currentHumanoid.Health <= 0 then
		return
	end

	if isRolling then
		return
	end

	if not isMatchActive then
		return
	end

	if os.clock() < cooldownEndsAt then
		return
	end

	isRolling = true
	cooldownEndsAt = os.clock() + ROLL_COOLDOWN

	local direction = get_roll_direction()
	currentAlign.CFrame = CFrame.lookAt(Vector3.zero, direction)
	currentAlign.Enabled = true

	local originalWalkSpeed = currentHumanoid.WalkSpeed
	local originalAutoRotate = currentHumanoid.AutoRotate
	currentHumanoid.WalkSpeed = 0
	currentHumanoid.AutoRotate = false

	stop_run_animation()
	stop_crouch_animations()
	set_character_collision(false)

	if rollSound then
		rollSound:Play()
	end

	if rollParticle then
		rollParticle.Enabled = true
	end

	if rollTrail then
		rollTrail.Enabled = true
	end

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "RollVelocity"
	velocity.Attachment0 = currentAttachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
	velocity.LineDirection = direction
	velocity.LineVelocity = ROLL_SPEED
	velocity.MaxForce = 100000
	velocity.Parent = currentRootPart

	task.spawn(function()
		local interval = ROLL_DURATION / AFTERIMAGE_COUNT

		for _ = 1, AFTERIMAGE_COUNT do
			spawn_afterimage()
			task.wait(interval)
		end
	end)

	task.wait(ROLL_DURATION)

	velocity:Destroy()
	currentAlign.Enabled = false
	currentHumanoid.WalkSpeed = originalWalkSpeed
	currentHumanoid.AutoRotate = originalAutoRotate
	set_character_collision(true)

	if rollParticle then
		rollParticle.Enabled = false
	end

	if rollTrail then
		rollTrail.Enabled = false
	end

	isRolling = false
	set_button_cooldown_state()
	update_movement_state()
end

local function on_character_added(newCharacter: Model): ()
	character = newCharacter
	setup_roll_effects_for_character(newCharacter)
	bodyCollisionCache = {}
	isRolling = false
end

local function on_input_began(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then
		return
	end

	if input.KeyCode == ROLL_KEY then
		perform_roll()
	end

	if input.KeyCode == RUN_KEY then
		isRunKeyDown = true
		update_movement_state()
	end

	if input.KeyCode == CROUCH_KEY then
		isCrouchKeyDown = true
		update_movement_state()
	end
end

local function on_input_ended(input: InputObject): ()
	if input.KeyCode == RUN_KEY then
		isRunKeyDown = false
		update_movement_state()
	end

	if input.KeyCode == CROUCH_KEY then
		isCrouchKeyDown = false
		update_movement_state()
	end
end

local function bind_mobile_button(): ()
	local button = rollButton

	if not button then
		return
	end

	button.MouseButton1Click:Connect(function()
		perform_roll()
	end)

	button.MouseButton1Down:Connect(function()
		button:TweenSize(UDim2.new(0, 72, 0, 72), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.08, true)
	end)

	button.MouseButton1Up:Connect(function()
		button:TweenSize(UDim2.new(0, 78, 0, 78), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.08, true)
	end)
end

local function sync_match_from_workspace(): ()
	isMatchActive = workspace:GetAttribute(MATCH_WORKSPACE_ATTRIBUTE_NAME) == true

	if rollGui then
		rollGui.Enabled = isMatchActive
	end

	set_button_cooldown_state()
	update_movement_state()
end

UserInputService.InputBegan:Connect(on_input_began)
UserInputService.InputEnded:Connect(on_input_ended)
player:GetAttributeChangedSignal(ATTR_AIMING):Connect(update_movement_state)
player:GetAttributeChangedSignal(ATTR_STOP_RUN_TOKEN):Connect(stop_running_from_weapon)

player.CharacterAdded:Connect(on_character_added)

if player.Character then
	on_character_added(player.Character)
else
	on_character_added(player.CharacterAdded:Wait())
end

setup_mobile_button()
bind_mobile_button()

workspace:GetAttributeChangedSignal(MATCH_WORKSPACE_ATTRIBUTE_NAME):Connect(sync_match_from_workspace)
sync_match_from_workspace()

RunService.RenderStepped:Connect(function()
	set_button_cooldown_state()
	update_movement_state()
end)

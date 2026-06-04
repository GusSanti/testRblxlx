local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local ATTR_ACTIVE = "GS_WeaponEquipped"
local ATTR_AIMING = "GS_IsAiming"

local CONFIG = {
	MaxMoveTiltDeg = 4,
	MoveTiltSmooth = 9,
	MoveTiltDeadzone = 0.05,
	MoveTiltSign = -1,
	NeckYawDeg = 38,
	WaistYawDeg = 26,
	NeckPitchDeg = 20,
	WaistPitchDeg = 14,
	NeckYawDegAim = 14,
	WaistYawDegAim = 10,
	NeckPitchDegAim = 24,
	WaistPitchDegAim = 16,
	FreeYawLimitDeg = 90,
	FollowSpeed = 12,
	FollowSpeedAim = 20,
	ReturnSpeed = 7
}

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local neck
local waist

local weaponActive = false
local isAiming = false

local neckYaw = 0
local neckPitch = 0
local waistYaw = 0
local waistPitch = 0

local roll = 0
local targetRoll = 0

local appliedWeaponActive
local appliedIsAiming

local function clamp01(v)
	return math.clamp(v, 0, 1)
end

local function signedYaw(fromVec, toVec)
	local a = Vector3.new(fromVec.X, 0, fromVec.Z)
	local b = Vector3.new(toVec.X, 0, toVec.Z)

	if a.Magnitude < 0.001 or b.Magnitude < 0.001 then
		return 0
	end

	a = a.Unit
	b = b.Unit

	local crossY = a:Cross(b).Y
	local dot = math.clamp(a:Dot(b), -1, 1)
	return math.atan2(crossY, dot)
end

local function getCamera()
	return workspace.CurrentCamera
end

local function findMotorByParts(part0Name, part1Name)
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part0 and d.Part1 and d.Part0.Name == part0Name and d.Part1.Name == part1Name then
			return d
		end
	end
	return nil
end

local function refreshRigJoints()
	neck = nil
	waist = nil

	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		neck = findMotorByParts("UpperTorso", "Head") or character:FindFirstChild("Neck", true)
		waist = findMotorByParts("LowerTorso", "UpperTorso") or findMotorByParts("UpperTorso", "LowerTorso") or character:FindFirstChild("Waist", true)
	end

	if neck and not neck:IsA("Motor6D") then
		neck = nil
	end
	if waist and not waist:IsA("Motor6D") then
		waist = nil
	end
end

local function resetLook()
	neckYaw = 0
	neckPitch = 0
	waistYaw = 0
	waistPitch = 0

	if neck then
		neck.Transform = CFrame.new()
	end
	if waist then
		waist.Transform = CFrame.new()
	end
end

local function syncFromAttributes()
	weaponActive = player:GetAttribute(ATTR_ACTIVE) == true
	isAiming = player:GetAttribute(ATTR_AIMING) == true
end

local function applyStateIfNeeded()
	if appliedWeaponActive == weaponActive and appliedIsAiming == isAiming then
		return
	end

	if not weaponActive then
		targetRoll = 0
	end

	appliedWeaponActive = weaponActive
	appliedIsAiming = isAiming
end

local function updateMoveTilt(dt)
	local cam = getCamera()
	if not cam then
		return
	end

	local side = 0
	-- Não aplica tilt lateral enquanto está mirando para não dar sensação de desvio.
	if weaponActive and not isAiming then
		local move = humanoid.MoveDirection
		if move.Magnitude > 0.001 then
			local localMove = cam.CFrame:VectorToObjectSpace(move)
			side = math.clamp(localMove.X, -1, 1)
			if math.abs(side) < CONFIG.MoveTiltDeadzone then
				side = 0
			end
		end
	end

	targetRoll = CONFIG.MoveTiltSign * side * math.rad(CONFIG.MaxMoveTiltDeg)
	local alpha = clamp01(CONFIG.MoveTiltSmooth * dt)
	roll = roll + (targetRoll - roll) * alpha

	cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, roll)
end

local function updateUpperBody(dt)
	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end

	local neckYawTarget = 0
	local neckPitchTarget = 0
	local waistYawTarget = 0
	local waistPitchTarget = 0
	local speed = CONFIG.ReturnSpeed

	local cam = getCamera()
	if weaponActive and cam then
		local camLook = cam.CFrame.LookVector
		local pitchRaw = math.asin(math.clamp(camLook.Y, -1, 1))
		local pitchAlpha = math.clamp(pitchRaw / math.rad(75), -1, 1)

		local maxNeckPitch = isAiming and CONFIG.NeckPitchDegAim or CONFIG.NeckPitchDeg
		local maxWaistPitch = isAiming and CONFIG.WaistPitchDegAim or CONFIG.WaistPitchDeg
		neckPitchTarget = pitchAlpha * math.rad(maxNeckPitch)
		waistPitchTarget = pitchAlpha * math.rad(maxWaistPitch)

		local rawYaw = signedYaw(root.CFrame.LookVector, camLook)
		local maxYaw = isAiming and math.rad(170) or math.rad(CONFIG.FreeYawLimitDeg)
		if math.abs(rawYaw) <= maxYaw then
			local yawAlpha = rawYaw / maxYaw
			local maxNeckYaw = isAiming and CONFIG.NeckYawDegAim or CONFIG.NeckYawDeg
			local maxWaistYaw = isAiming and CONFIG.WaistYawDegAim or CONFIG.WaistYawDeg
			neckYawTarget = yawAlpha * math.rad(maxNeckYaw)
			waistYawTarget = yawAlpha * math.rad(maxWaistYaw)
		end

		speed = isAiming and CONFIG.FollowSpeedAim or CONFIG.FollowSpeed
	end

	local alpha = clamp01(speed * dt)
	neckYaw = neckYaw + (neckYawTarget - neckYaw) * alpha
	neckPitch = neckPitch + (neckPitchTarget - neckPitch) * alpha
	waistYaw = waistYaw + (waistYawTarget - waistYaw) * alpha
	waistPitch = waistPitch + (waistPitchTarget - waistPitch) * alpha

	if neck then
		neck.Transform = CFrame.Angles(-neckPitch, neckYaw, 0)
	end
	if waist then
		waist.Transform = CFrame.Angles(-waistPitch, waistYaw, 0)
	end
end

local function onCharacterAdded(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")

	refreshRigJoints()
	resetLook()

	appliedWeaponActive = nil
	appliedIsAiming = nil
	targetRoll = 0
	roll = 0

	syncFromAttributes()
	applyStateIfNeeded()
end

if player:GetAttribute(ATTR_ACTIVE) == nil then
	player:SetAttribute(ATTR_ACTIVE, false)
end

if player:GetAttribute(ATTR_AIMING) == nil then
	player:SetAttribute(ATTR_AIMING, false)
end

syncFromAttributes()
refreshRigJoints()
resetLook()
applyStateIfNeeded()

player.CharacterAdded:Connect(onCharacterAdded)

player:GetAttributeChangedSignal(ATTR_ACTIVE):Connect(function()
	syncFromAttributes()
	applyStateIfNeeded()
end)

player:GetAttributeChangedSignal(ATTR_AIMING):Connect(function()
	syncFromAttributes()
	applyStateIfNeeded()
end)

RunService:BindToRenderStep(
	("GS_CameraImmersion_%d"):format(player.UserId),
	Enum.RenderPriority.Camera.Value + 1,
	function(dt)
		syncFromAttributes()
		applyStateIfNeeded()
		updateMoveTilt(dt)
	end
)

if RunService.PreSimulation then
	RunService.PreSimulation:Connect(function(dt)
		updateUpperBody(dt)
	end)
else
	RunService.Stepped:Connect(function(_, dt)
		updateUpperBody(dt)
	end)
end
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local DASH_ACTION = "PlayerDash"
local DASH_COOLDOWN = 1
local DASH_DURATION = 0.18
local DASH_SPEED = 80
local DASH_FORCE = 100000

local lastDashTime = 0

local function getFlatDirection(vector)
	local flatDirection = Vector3.new(vector.X, 0, vector.Z)
	if flatDirection.Magnitude <= 0.05 then
		return nil
	end

	return flatDirection.Unit
end

local function getDashDirection(character, humanoid)
	local moveDirection = getFlatDirection(humanoid.MoveDirection)
	if moveDirection then
		return moveDirection
	end

	local camera = workspace.CurrentCamera
	local cameraDirection = camera and getFlatDirection(camera.CFrame.LookVector)
	if cameraDirection then
		return cameraDirection
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	return rootPart and getFlatDirection(rootPart.CFrame.LookVector) or Vector3.new(0, 0, -1)
end

local function dash()
	if UserInputService:GetFocusedTextBox() then
		return
	end

	local now = os.clock()
	if now - lastDashTime < DASH_COOLDOWN then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 or humanoid.Sit then
		return
	end

	lastDashTime = now

	local oldDashVelocity = rootPart:FindFirstChild("DashVelocity")
	if oldDashVelocity then
		oldDashVelocity:Destroy()
	end

	local dashVelocity = Instance.new("BodyVelocity")
	dashVelocity.Name = "DashVelocity"
	dashVelocity.MaxForce = Vector3.new(DASH_FORCE, 0, DASH_FORCE)
	dashVelocity.P = DASH_FORCE
	dashVelocity.Velocity = getDashDirection(character, humanoid) * DASH_SPEED
	dashVelocity.Parent = rootPart

	Debris:AddItem(dashVelocity, DASH_DURATION)
end

ContextActionService:BindAction(DASH_ACTION, function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		dash()
	end

	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonL2)

ContextActionService:SetTitle(DASH_ACTION, "Dash")
ContextActionService:SetPosition(DASH_ACTION, UDim2.new(1, -110, 1, -210))

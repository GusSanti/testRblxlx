local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")

local NotificationController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utility"):WaitForChild("NotificationUtility"))
local PETS_DATA_MODULE = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Datas"):WaitForChild("PetsData"))
local RARITYS_DATA_MODULE = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Datas"):WaitForChild("RaritysData"))
local EGGS_DATA_MODULE = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Datas"):WaitForChild("EggData"))

local ASSETS_FOLDER = ReplicatedStorage:WaitForChild("Assets")
local EFFECTS_FOLDER = ASSETS_FOLDER:WaitForChild("Effects")
local EGGS_ANIMATION_FOLDER = ASSETS_FOLDER:WaitForChild("Egg")

local REMOTE_NAME = "EggGachaRemote"
local CHECK_FUNDS_REMOTE_NAME = "CheckEggFundsRemote"

local FASTER_HATCH_GAMEPASS_ID = 1702677369

local ANIM_SETTINGS = {
	DistanceStart = 10.5,
	DistanceClose = 5.5,

	ScriptableOffset = 5,

	HoverSpeed = 2,
	HoverAmp = 0.15,

	EggScale = 0.85,
	PetScale = 1.0,

	EggVerticalOffset = -0.5,
	PetVerticalOffset = 0
}

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local gachaRemote = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild(REMOTE_NAME)
local checkFundsRemote = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild(CHECK_FUNDS_REMOTE_NAME)

local isOpening = false
local renderConnection = nil

local gachaState = {
	Object = nil,
	CurrentDistance = ANIM_SETTINGS.DistanceStart,
	BaseRotation = 0,
	ShakeIntensity = 0,
	IsPet = false,
	HoverAlpha = 0,
	FixedCameraCF = CFrame.new(),
	OriginalSize = Vector3.new(1, 1, 1)
}

local function toggleAllPrompts(status)
	for _, v in pairs(Workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then
			v.Enabled = status
		end
	end
end

local function checkFasterHatch()
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, FASTER_HATCH_GAMEPASS_ID)
	end)
	return success and hasPass
end

local function spawnParticles(part, rarityColor, isExplosion)
	if not part then return end

	local template = EFFECTS_FOLDER:FindFirstChild("Sparkles")
	if template then
		local visuals = template:Clone()
		visuals.Parent = part
		for _, desc in pairs(visuals:GetDescendants()) do
			if desc:IsA("ParticleEmitter") then
				desc.Color = ColorSequence.new(rarityColor)
				if isExplosion then
					desc:Emit(80)
				else
					desc.Enabled = true
				end
			end
		end
		if isExplosion then Debris:AddItem(visuals, 3) end
	end
end

local function flashScreen(color, duration)
	local gui = Instance.new("ScreenGui")
	gui.IgnoreGuiInset = true
	gui.Parent = Player.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = color or Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0
	frame.Parent = gui

	local tween = TweenService:Create(frame, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	tween:Play()
	tween.Completed:Connect(function() gui:Destroy() end)
end

local function togglePlayerControl(lock)
	local char = Player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.Anchored = lock
		if lock then
			local offsetCamCF = Camera.CFrame * CFrame.new(0, 0, ANIM_SETTINGS.ScriptableOffset)
			Camera.CFrame = offsetCamCF
			gachaState.FixedCameraCF = offsetCamCF

			Camera.CameraType = Enum.CameraType.Scriptable

			char.Humanoid.WalkSpeed = 0
			char.Humanoid.JumpPower = 0
		else
			Camera.CameraType = Enum.CameraType.Custom

			char.Humanoid.WalkSpeed = 16
			char.Humanoid.JumpPower = 50
		end
	end
end

local function startRenderLoop()
	if renderConnection then renderConnection:Disconnect() end
	local startTime = os.clock()

	renderConnection = RunService.RenderStepped:Connect(function(dt)
		if not gachaState.Object or not gachaState.Object.Parent then return end

		local timeNow = os.clock() - startTime

		gachaState.HoverAlpha = gachaState.HoverAlpha + (dt * ANIM_SETTINGS.HoverSpeed)
		local hoverY = math.sin(gachaState.HoverAlpha) * ANIM_SETTINGS.HoverAmp

		local shakeOffset = Vector3.new(0,0,0)
		local shakeAngle = CFrame.new()

		if gachaState.ShakeIntensity > 0 then
			local i = gachaState.ShakeIntensity
			shakeOffset = Vector3.new(
				(math.random() - 0.5) * 0.3 * i,
				(math.random() - 0.5) * 0.3 * i,
				0
			)
			shakeAngle = CFrame.Angles(
				math.rad((math.random() - 0.5) * 5 * i),
				math.rad((math.random() - 0.5) * 5 * i),
				math.rad((math.random() - 0.5) * 8 * i)
			)
		end

		local rotationCF = CFrame.Angles(0, math.rad(gachaState.BaseRotation), 0)

		if not gachaState.IsPet then
			rotationCF = rotationCF * CFrame.Angles(0, 0, math.rad(math.sin(timeNow * 4) * 3))
		end

		local currentVerticalOffset = gachaState.IsPet and ANIM_SETTINGS.PetVerticalOffset or ANIM_SETTINGS.EggVerticalOffset

		local finalCF = gachaState.FixedCameraCF 
			* CFrame.new(0, 0, -gachaState.CurrentDistance) 
			* CFrame.new(0, hoverY + currentVerticalOffset, 0)
			* CFrame.new(shakeOffset)
			* rotationCF
			* shakeAngle

		gachaState.Object.CFrame = finalCF

		local baseScale = gachaState.IsPet and ANIM_SETTINGS.PetScale or ANIM_SETTINGS.EggScale
		local squash = 1 + (math.sin(timeNow * 12) * 0.02 * gachaState.ShakeIntensity)

		local finalScale = baseScale * squash
		if finalScale <= 0.01 then finalScale = 0.01 end

		gachaState.Object.Size = gachaState.OriginalSize * finalScale
	end)
end

local function cleanup()
	isOpening = false
	if renderConnection then renderConnection:Disconnect() end
	if gachaState.Object then gachaState.Object:Destroy() end

	togglePlayerControl(false)
	toggleAllPrompts(true)

	TweenService:Create(Camera, TweenInfo.new(0.6), {FieldOfView = 70}):Play()
end

local function getAnimationEggName(eggName)
	local searchName = eggName .. " Egg"
	local foundEgg = EGGS_ANIMATION_FOLDER:FindFirstChild(searchName)
	if foundEgg then
		return foundEgg.Name
	end

	if EGGS_ANIMATION_FOLDER:FindFirstChild(eggName) then
		return eggName
	end

	for _, egg in ipairs(EGGS_ANIMATION_FOLDER:GetChildren()) do
		if egg.Name:find(eggName) then
			if string.find(egg.Name, "Golden") and not string.find(eggName, "Golden") then
				continue
			end
			return egg.Name
		end
	end

	return searchName
end

local function playGachaSequence(eggName)
	toggleAllPrompts(false)
	Player:SetAttribute("EggAnimationFinished", false)
	Player:SetAttribute("LastEggPurchase", eggName)

	local petNameResult = nil
	local petData = nil
	local rarityColor = Color3.new(1,1,1)

	local isFaster = checkFasterHatch()
	local speedMult = isFaster and 0.5 or 1.2

	local animEggName = getAnimationEggName(eggName)
	local eggModelSource = EGGS_ANIMATION_FOLDER:FindFirstChild(animEggName)

	if not eggModelSource then
		NotificationController:Error("Egg model not found: " .. animEggName)
		cleanup()
		return
	end

	for _, v in eggModelSource:GetDescendants() do
		if v:IsA("ParticleEmitter") then 
			v:Emit(v:GetAttribute("EmitCount")) 
		end 
	end

	togglePlayerControl(true)

	local visualEgg = eggModelSource:Clone()
	visualEgg.CanCollide = false
	visualEgg.Anchored = true
	visualEgg.Parent = Camera

	gachaState.Object = visualEgg
	gachaState.OriginalSize = visualEgg.Size
	gachaState.CurrentDistance = ANIM_SETTINGS.DistanceStart
	gachaState.BaseRotation = 180 
	gachaState.ShakeIntensity = 0
	gachaState.IsPet = false
	gachaState.HoverAlpha = 0

	startRenderLoop()

	task.spawn(function()
		local success, result = pcall(function()
			return gachaRemote:InvokeServer(eggName)
		end)

		petNameResult = success and result or "ERROR"
	end)

	local distValue = Instance.new("NumberValue")
	distValue.Value = gachaState.CurrentDistance
	distValue.Changed:Connect(function(v) gachaState.CurrentDistance = v end)
	TweenService:Create(distValue, TweenInfo.new(1.5 * speedMult, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Value = ANIM_SETTINGS.DistanceClose}):Play()

	local shakeValue = Instance.new("NumberValue")
	shakeValue.Value = 0
	shakeValue.Changed:Connect(function(v) gachaState.ShakeIntensity = v end)

	TweenService:Create(shakeValue, TweenInfo.new(2.5 * speedMult, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Value = 1.0}):Play()

	local timeout = 0
	while not petNameResult and timeout < 8 do
		task.wait(0.1)
		timeout += 0.1
	end

	if petNameResult == "ERROR" or not petNameResult then
		NotificationController:Error("Failed to open egg!")
		if distValue then distValue:Destroy() end
		if shakeValue then shakeValue:Destroy() end
		cleanup()
		return
	end

	petData = PETS_DATA_MODULE.GetPetData(petNameResult)

	if not petData then
		cleanup()
		return
	end

	local rarityInfo = RARITYS_DATA_MODULE[petData.Raritys]
	rarityColor = rarityInfo and rarityInfo.Color or Color3.new(1,1,1)

	TweenService:Create(shakeValue, TweenInfo.new(0.5 * speedMult, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Value = 5.0}):Play()
	TweenService:Create(Camera, TweenInfo.new(0.5 * speedMult, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = 45}):Play()

	task.wait(0.5 * speedMult)

	flashScreen(Color3.new(1,1,1), 0.5 * speedMult)
	spawnParticles(visualEgg, rarityColor, true)

	visualEgg:Destroy()
	shakeValue:Destroy()
	distValue:Destroy()

	if not petData.MeshPart then
		cleanup()
		return
	end

	local visualPet = petData.MeshPart:Clone()
	visualPet.CanCollide = false
	visualPet.Anchored = true
	visualPet.Parent = Camera

	gachaState.Object = visualPet
	gachaState.OriginalSize = visualPet.Size
	gachaState.IsPet = true
	gachaState.ShakeIntensity = 0 
	gachaState.BaseRotation = 180
	gachaState.CurrentDistance = ANIM_SETTINGS.DistanceClose

	visualPet.Size = gachaState.OriginalSize * 0.01

	local popSpeed = 0.045 / (isFaster and 2 or 1)
	for i = 0, 1, popSpeed do 
		local overshoot = 1.2
		local period = 0.3
		local decay = 6.0

		local scale = 1 + overshoot * math.pow(2, -decay * i) * math.sin((i - period / 4) * (2 * math.pi) / period)
		if i < 0.05 then scale = i * 20 end

		visualPet.Size = gachaState.OriginalSize * (ANIM_SETTINGS.PetScale * scale)
		RunService.RenderStepped:Wait()
	end
	visualPet.Size = gachaState.OriginalSize * ANIM_SETTINGS.PetScale

	spawnParticles(visualPet, rarityColor, false)

	NotificationController:Show({
		message = "You hatched a " .. petData.DisplayName .. "!",
		type = "success",
		icon = "🎉",
		sound = true
	})

	Player:SetAttribute("EggAnimationFinished", true) 

	local rotationValue = Instance.new("NumberValue")
	rotationValue.Value = 180
	rotationValue.Changed:Connect(function(v) gachaState.BaseRotation = v end)
	TweenService:Create(rotationValue, TweenInfo.new(4 * speedMult, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Value = 180 + 360}):Play()

	task.wait(2.5 * speedMult) 

	local exitSpeed = 0.08 * (isFaster and 2 or 1)
	for i = 1, 0, -exitSpeed do
		local s = math.max(0.01, ANIM_SETTINGS.PetScale * i)
		visualPet.Size = gachaState.OriginalSize * s
		RunService.RenderStepped:Wait()
	end

	rotationValue:Destroy()
	cleanup()
end

local function validateEggFunds(eggName)
	local success, result = pcall(function()
		return checkFundsRemote:InvokeServer(eggName)
	end)

	if not success then return false, "Connection Error" end
	if not result.success then
		if result.reason == "InsufficientFunds" then
			return false, "Not enough coins!", "error"
		end
		return false, result.reason or "Error", "error"
	end
	return true
end

local function onEggTriggered(eggName)
	if isOpening then return end

	local canBuy, msg, typeInfo = validateEggFunds(eggName)
	if not canBuy then
		NotificationController:Show({message = msg, type = typeInfo, duration = 3})
		return
	end

	isOpening = true
	task.spawn(function() playGachaSequence(eggName) end)
end

local function setupPrompt(prompt)
	local eggName = prompt:GetAttribute("EggReference")

	if not eggName then
		if EGGS_DATA_MODULE[prompt.Parent.Name] then
			eggName = prompt.Parent.Name
		elseif prompt.Parent.Parent and EGGS_DATA_MODULE[prompt.Parent.Parent.Name] then
			eggName = prompt.Parent.Parent.Name
		end
	end

	if eggName and EGGS_DATA_MODULE[eggName] then
		if prompt:GetAttribute("Connected") then return end
		prompt:SetAttribute("Connected", true)

		prompt.Triggered:Connect(function(player)
			onEggTriggered(eggName)
		end)
	end
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
	if descendant:IsA("ProximityPrompt") then
		setupPrompt(descendant)
	end
end

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ProximityPrompt") then
		setupPrompt(descendant)
	end
end)
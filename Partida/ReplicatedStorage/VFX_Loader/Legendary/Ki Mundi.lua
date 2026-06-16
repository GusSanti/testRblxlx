-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

-- CONSTANTS
local VFX = ReplicatedStorage:WaitForChild("VFX")
local VFX_MODULES = ReplicatedStorage:WaitForChild("VFXModules")
local MODULES = ReplicatedStorage:WaitForChild("Modules")

-- VARIABLES
local UnitSoundEffectLib = require(VFX_MODULES:WaitForChild("UnitSoundEffectLib"))
local VFX_Helper = require(MODULES:WaitForChild("VFX_Helper"))
local GameSpeed = Workspace:WaitForChild("Info"):WaitForChild("GameSpeed")
local vfxFolder = Workspace:WaitForChild("VFX")

local module = {}

-- FUNCTIONS
module["Ki Mundi Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local KiMundiFolder = VFX.LEGA["Ki Mundi"].First
	local characterModel = HRP and HRP.Parent
	if not characterModel then return end

	local Range = characterModel.Config:WaitForChild("Range").Value
	local targetHRP = target and target:FindFirstChild("HumanoidRootPart")
	local originalPivot = characterModel:GetPivot()
	local returnDelay = 0.1 / speed
	local attackCommitted = false

	local function emitTeleportEffect(atCFrame)
		local teleportEffect = KiMundiFolder:FindFirstChild("teleport")
		if not teleportEffect then return end

		local clone = teleportEffect:Clone()
		clone.Transparency = 1
		clone.Anchored = true
		clone.CanCollide = false
		clone.CFrame = atCFrame + Vector3.new(0, -0.5, 0)
		clone.Parent = vfxFolder
		Debris:AddItem(clone, 1 / speed)
		VFX_Helper.EmitAllParticles(clone)
	end

	task.wait(0.1 / speed)
	if not HRP or not HRP.Parent then return end

	local handleR = characterModel:FindFirstChild("Right Arm") and characterModel["Right Arm"]:FindFirstChild("Handle")
	if handleR and handleR:FindFirstChild("Trail") then
		handleR.Trail.Enabled = true
	end

	task.wait(0.75 / speed)
	if not HRP or not HRP.Parent or not targetHRP then return end
	characterModel.Attacking.Value = true
	attackCommitted = true
	local vfxTemplate = KiMundiFolder.First:Clone()

	local function bindAttachment(attName, targetPart, isPierce)
		local att = vfxTemplate:FindFirstChild(attName)
		if att then
			att.Parent = targetPart
			if isPierce then
				local relativeDir = targetPart.CFrame:PointToObjectSpace(targetHRP.Position)
				att.CFrame = CFrame.lookAt(Vector3.zero, relativeDir)
			else
				att.CFrame = CFrame.new()
			end
			Debris:AddItem(att, 4 / speed)
		end
		return att
	end

	local popAtt = bindAttachment("Pop", HRP, false)
	local pierceAtt = bindAttachment("pierce", HRP, true)

	local impactAtt = bindAttachment("Impact", targetHRP, false)
	local slashAtt = bindAttachment("Slash", targetHRP, false)

	local meshModel = vfxTemplate:FindFirstChild("MeshPartMesh")
	local beamModel = vfxTemplate:FindFirstChild("beamslash")

	local function setupTargetedModel(model)
		if not model then return end
		model.Parent = vfxFolder
		Debris:AddItem(model, 4 / speed)

		local startPart = model:FindFirstChild("Start")
		local endPart = model:FindFirstChild("End")

		if startPart then
			startPart.Transparency = 1
			startPart.Anchored = false 
			startPart.CanCollide = false
			startPart.Massless = true
			startPart.CFrame = HRP.CFrame

			local wStart = Instance.new("WeldConstraint")
			wStart.Part0 = HRP
			wStart.Part1 = startPart
			wStart.Parent = startPart
		end

		if endPart then
			endPart.Transparency = 1
			endPart.Anchored = false
			endPart.CanCollide = false
			endPart.Massless = true
			endPart.CFrame = targetHRP.CFrame

			local wEnd = Instance.new("WeldConstraint")
			wEnd.Part0 = targetHRP
			wEnd.Part1 = endPart
			wEnd.Parent = endPart
		end
	end

	setupTargetedModel(meshModel)
	setupTargetedModel(beamModel)

	vfxTemplate:Destroy()

	local function cleanupVFX()
		if popAtt then popAtt:Destroy() end
		if pierceAtt then pierceAtt:Destroy() end
		if impactAtt then impactAtt:Destroy() end
		if slashAtt then slashAtt:Destroy() end
		if meshModel then meshModel:Destroy() end
		if beamModel then beamModel:Destroy() end
	end

	local attackFinished = false
	local function finishAttack()
		if attackFinished then return end
		attackFinished = true

		cleanupVFX()

		if handleR and handleR:FindFirstChild("Trail") then
			handleR.Trail.Enabled = false
		end

		local attackingFlag = characterModel:FindFirstChild("Attacking")
		if not HRP or not HRP.Parent then
			if attackingFlag then
				attackingFlag.Value = false
			end
			return
		end

		emitTeleportEffect(HRP.CFrame)
		task.wait(returnDelay)

		if not HRP or not HRP.Parent then
			if attackingFlag then
				attackingFlag.Value = false
			end
			return
		end

		characterModel:PivotTo(originalPivot)
		emitTeleportEffect(HRP.CFrame)
		if attackingFlag then
			attackingFlag.Value = false
		end
	end

	local connection = characterModel.Destroying:Once(function()
		attackFinished = true
		cleanupVFX()
	end)

	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -(Range - 2))
	TweenService:Create(HRP, TweenInfo.new(0.15 / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()

	if popAtt then VFX_Helper.EmitAllParticles(popAtt) end
	if pierceAtt then VFX_Helper.EmitAllParticles(pierceAtt) end
	if meshModel then VFX_Helper.EmitAllParticles(meshModel) end
	if beamModel then VFX_Helper.OnAllBeams(beamModel) end 

	task.wait(0.09 / speed)
	if not HRP or not HRP.Parent or not targetHRP then
		if attackCommitted then
			finishAttack()
		end
		return
	end

	if impactAtt then VFX_Helper.EmitAllParticles(impactAtt) end
	if slashAtt then VFX_Helper.EmitAllParticles(slashAtt) end

	UnitSoundEffectLib.playSound(characterModel, 'SaberSwing' .. tostring(math.random(1, 2)), false)

	task.wait(0.05 / speed)
	if not HRP or not HRP.Parent then
		if attackCommitted then
			finishAttack()
		end
		return
	end

	if beamModel then VFX_Helper.OffAllBeams(beamModel) end

	task.wait(1 / speed)
	if not HRP or not HRP.Parent then
		if attackCommitted then
			finishAttack()
		end
		return
	end

	finishAttack()
	connection:Disconnect()
end

-- INIT
return module

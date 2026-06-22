local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VFX = ReplicatedStorage:WaitForChild("VFX")

local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)
local VFX_Helper = require(ReplicatedStorage.Modules.VFX_Helper)
local upgradesModule = require(ReplicatedStorage.Upgrades)

local GameSpeed = workspace.Info.GameSpeed
local vfxFolder = workspace:FindFirstChild("VFX") or workspace
local armoredCommandoVFX = VFX:FindFirstChild("Armored Commando")

local module = {}

local function emitParticles(container)
	VFX_Helper.EmitAllParticles(container)
end

local function disableInterference(characterModel, hrp)
	if characterModel:FindFirstChild("Humanoid") then
		characterModel.Humanoid.PlatformStand = true
	end

	if not hrp then
		return
	end

	local bodyGyro = hrp:FindFirstChildOfClass("BodyGyro")
	if bodyGyro then
		bodyGyro.MaxTorque = Vector3.zero
	end

	hrp.Anchored = true
end

local function restoreInterference(characterModel, hrp, originalCFrame)
	if characterModel and characterModel:FindFirstChild("Attacking") then
		characterModel.Attacking.Value = false
	end

	if hrp then
		local towerBase = characterModel and characterModel:FindFirstChild("TowerBasePart")
		if towerBase then
			hrp.CFrame = towerBase.CFrame
		elseif originalCFrame then
			hrp.CFrame = originalCFrame
		end

		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.Anchored = false

		local bodyGyro = hrp:FindFirstChildOfClass("BodyGyro")
		if bodyGyro then
			bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		end
	end

	if characterModel and characterModel:FindFirstChild("Humanoid") then
		characterModel.Humanoid.PlatformStand = false
	end
end

local function getStageEffect(folder, effectName)
	if not folder then
		return nil
	end

	return folder:FindFirstChild(effectName)
end

local function setEffectCFrame(effect, cf)
	if not effect or not cf then
		return effect
	end

	if effect:IsA("Model") then
		effect:PivotTo(cf)
	elseif effect:IsA("BasePart") then
		effect.CFrame = cf
	end

	return effect
end

local function safeLookAt(originPos, targetPos)
	if (originPos - targetPos).Magnitude < 0.1 then
		return CFrame.new(originPos)
	end

	return CFrame.lookAt(originPos, targetPos)
end

local function getActionTrack(characterModel)
	local humanoid = characterModel and characterModel:FindFirstChild("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end

	for _, track in animator:GetPlayingAnimationTracks() do
		local lowerName = string.lower(track.Name)
		if lowerName == "punch" or lowerName == "punches" or lowerName == "combo" or lowerName == "attack2" or lowerName == "attack1" then
			return track
		end
	end

	return nil
end

local function getAnimator(characterModel)
	local humanoid = characterModel and characterModel:FindFirstChild("Humanoid")
	return humanoid and humanoid:FindFirstChildOfClass("Animator")
end

local function findAnimationObject(characterModel, candidateNames)
	local animationsFolder = characterModel and characterModel:FindFirstChild("Animations")
	if not animationsFolder then
		return nil
	end

	for _, candidateName in candidateNames do
		local directMatch = animationsFolder:FindFirstChild(candidateName)
		if directMatch and directMatch:IsA("Animation") then
			return directMatch
		end
	end

	for _, descendant in animationsFolder:GetDescendants() do
		if descendant:IsA("Animation") then
			local lowerName = string.lower(descendant.Name)
			for _, candidateName in candidateNames do
				if lowerName == string.lower(candidateName) then
					return descendant
				end
			end
		end
	end

	return nil
end

local function stopActionTracks(characterModel)
	local animator = getAnimator(characterModel)
	if not animator then
		return
	end

	for _, track in animator:GetPlayingAnimationTracks() do
		local lowerName = string.lower(track.Name)
		if lowerName ~= "idle" then
			track:Stop(0.05)
		end
	end
end

local function playAnimationByCandidates(characterModel, candidateNames, speed, loopedOverride)
	local animator = getAnimator(characterModel)
	local animationObject = findAnimationObject(characterModel, candidateNames)
	if not animator or not animationObject then
		return nil
	end

	local existingTrack = nil
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Name == animationObject.Name then
			existingTrack = track
			break
		end
	end

	local animationTrack = existingTrack or animator:LoadAnimation(animationObject)
	if loopedOverride ~= nil then
		animationTrack.Looped = loopedOverride
	end

	animationTrack:Play()

	local unitAnimSpeed = animationObject:FindFirstChild("UnitAnimSpeed")
	if unitAnimSpeed and typeof(unitAnimSpeed.Value) == "number" then
		animationTrack:AdjustSpeed(unitAnimSpeed.Value * speed)
	else
		animationTrack:AdjustSpeed(speed)
	end

	return animationTrack
end

local function waitForActionTrackToAppear(characterModel, timeoutDuration)
	local timeoutAt = os.clock() + timeoutDuration
	local track = getActionTrack(characterModel)
	while not track and os.clock() < timeoutAt do
		task.wait()
		track = getActionTrack(characterModel)
	end

	return track
end

local function getUpgradeStats(characterModel)
	local config = characterModel and characterModel:FindFirstChild("Config")
	local upgradeValue = config and config:FindFirstChild("Upgrades")
	local unitStats = characterModel and upgradesModule[characterModel.Name]
	if not unitStats or not unitStats.Upgrades or not upgradeValue then
		return nil
	end

	return unitStats.Upgrades[upgradeValue.Value]
end

local function getImpactDelay(characterModel, speed)
	local upgradeStats = getUpgradeStats(characterModel)
	local delays = upgradeStats and upgradeStats.MultiDamageDelays
	local firstDelay = if typeof(delays) == "table" and typeof(delays[1]) == "number" then delays[1] else 1
	return math.max(firstDelay / speed, 0.25 / speed)
end

local function getTrackRemainingTime(track)
	if not track then
		return nil
	end

	local trackLength = track.Length
	if typeof(trackLength) ~= "number" or trackLength <= 0 then
		return nil
	end

	local playbackSpeed = math.max(math.abs(track.Speed), 0.01)
	return math.max((trackLength - track.TimePosition) / playbackSpeed, 0)
end

local function waitForActionTrack(track, fallbackDuration)
	local remainingTime = getTrackRemainingTime(track)
	if not track or not remainingTime then
		task.wait(fallbackDuration)
		return
	end

	local timeoutAt = os.clock() + remainingTime + (0.2 / math.max(GameSpeed.Value, 0.01))
	repeat
		task.wait()
	until not track.IsPlaying or os.clock() >= timeoutAt
end

local function emitNamedParticles(effect, pattern)
	if not effect then
		return
	end

	for _, obj in effect:GetDescendants() do
		if obj:IsA("ParticleEmitter") and obj.Parent and string.find(string.lower(obj.Parent.Name), pattern) then
			emitParticles(obj)
		end
	end
end

local function stopAllParticles(effect)
	if effect and effect.Parent then
		VFX_Helper.OffAllParticles(effect)
	end
end

local function getFlatEnemyPosition(target, yPosition)
	local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return nil
	end

	return Vector3.new(targetRoot.Position.X, yPosition, targetRoot.Position.Z)
end

local function dashTowardTarget(hrp, target, travelTime, stopDistance)
	local startingEnemyPos = getFlatEnemyPosition(target, hrp.Position.Y)
	if not startingEnemyPos then
		return false
	end

	local startingLookDir = safeLookAt(hrp.Position, startingEnemyPos)
	local startingTargetPosition = startingEnemyPos - (startingLookDir.LookVector * stopDistance)
	local totalDistance = (startingTargetPosition - hrp.Position).Magnitude
	if totalDistance <= 0.05 or travelTime <= 0 then
		hrp.CFrame = CFrame.lookAt(startingTargetPosition, startingEnemyPos)
		return true
	end

	local runSpeedStudsPerSecond = totalDistance / travelTime
	local finishAt = os.clock() + travelTime
	local lastStepAt = os.clock()

	while os.clock() < finishAt do
		if not hrp or not hrp.Parent then
			return false
		end

		local currentEnemyPos = getFlatEnemyPosition(target, hrp.Position.Y) or startingEnemyPos
		local lookDir = safeLookAt(hrp.Position, currentEnemyPos)
		local desiredPosition = currentEnemyPos - (lookDir.LookVector * stopDistance)
		local toTarget = desiredPosition - hrp.Position

		if toTarget.Magnitude <= 0.05 then
			hrp.CFrame = CFrame.lookAt(desiredPosition, currentEnemyPos)
			task.wait()
			continue
		end

		local now = os.clock()
		local deltaTime = now - lastStepAt
		lastStepAt = now

		local stepDistance = math.min(toTarget.Magnitude, runSpeedStudsPerSecond * deltaTime)
		local nextPosition = hrp.Position + (toTarget.Unit * stepDistance)
		hrp.CFrame = CFrame.lookAt(nextPosition, currentEnemyPos)

		task.wait()
	end

	local finalEnemyPos = getFlatEnemyPosition(target, hrp.Position.Y) or startingEnemyPos
	local finalLookDir = safeLookAt(hrp.Position, finalEnemyPos)
	local finalTargetPosition = finalEnemyPos - (finalLookDir.LookVector * stopDistance)
	hrp.CFrame = CFrame.lookAt(finalTargetPosition, finalEnemyPos)
	return true
end

local function runBeatdown(HRP, target)
	if not HRP or not HRP.Parent then
		return
	end

	if not target or not target:FindFirstChild("HumanoidRootPart") then
		return
	end

	local characterModel = HRP.Parent
	local attackingValue = characterModel:FindFirstChild("Attacking")
	if attackingValue and attackingValue.Value then
		return
	end
	if attackingValue then
		attackingValue.Value = true
	end

	local towerBase = characterModel:FindFirstChild("TowerBasePart")
	local originalCFrame = towerBase and towerBase.CFrame or HRP.CFrame
	local speed = math.max(GameSpeed.Value, 0.01)
	local beatdownFolder = armoredCommandoVFX and armoredCommandoVFX:FindFirstChild("Second")
	local secondEffect = getStageEffect(beatdownFolder, "Second")
	local mainVFX = nil

	disableInterference(characterModel, HRP)

	if secondEffect then
		mainVFX = secondEffect:Clone()
		mainVFX = setEffectCFrame(mainVFX, HRP.CFrame)
		mainVFX.Parent = characterModel
		Debris:AddItem(mainVFX, 4 / speed)

		local effectPart = if mainVFX:IsA("Model")
			then (mainVFX.PrimaryPart or mainVFX:FindFirstChildWhichIsA("BasePart"))
			else mainVFX
		if effectPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = HRP
			weld.Part1 = effectPart
			weld.Parent = effectPart
		end

		for _, obj in mainVFX:GetDescendants() do
			if obj:IsA("ParticleEmitter") and obj.Parent and string.find(string.lower(obj.Parent.Name), "wind") then
				obj.Enabled = true
				emitParticles(obj)
			end
		end
	end

	task.wait(0.03 / speed)

	if not HRP or not HRP.Parent or not target or not target:FindFirstChild("HumanoidRootPart") then
		stopAllParticles(mainVFX)
		restoreInterference(characterModel, HRP, originalCFrame)
		return
	end

	local stopDistance = 3
	local flatEnemyPos = getFlatEnemyPosition(target, HRP.Position.Y)
	if not flatEnemyPos then
		stopAllParticles(mainVFX)
		restoreInterference(characterModel, HRP, originalCFrame)
		return
	end

	local travelDistance = math.max((HRP.Position - flatEnemyPos).Magnitude - stopDistance, 0)
	local impactDelay = getImpactDelay(characterModel, speed)
	local arrivalLeadTime = 0.1 / speed
	local timeToTravel = math.max(impactDelay - arrivalLeadTime, 0.22 / speed)
	if travelDistance <= 1 then
		timeToTravel = 0.08 / speed
	end

	if not dashTowardTarget(HRP, target, timeToTravel, stopDistance) then
		stopAllParticles(mainVFX)
		restoreInterference(characterModel, HRP, originalCFrame)
		return
	end

	if not HRP or not HRP.Parent then
		stopAllParticles(mainVFX)
		restoreInterference(characterModel, HRP, originalCFrame)
		return
	end

	emitNamedParticles(mainVFX, "impact")
	emitNamedParticles(mainVFX, "starthing")

	task.spawn(function()
		for _ = 1, 3 do
			if not characterModel or not characterModel.Parent then
				return
			end

			UnitSoundEffectLib.playSound(characterModel, "Punch" .. tostring(math.random(1, 3)), false)
			task.wait(0.08 / speed)
		end
	end)

	task.delay(0.2 / speed, function()
		stopAllParticles(mainVFX)
	end)

	local actionTrack = waitForActionTrackToAppear(characterModel, 0.15 / speed)
	waitForActionTrack(actionTrack, 0.6 / speed)

	if not HRP or not HRP.Parent then
		restoreInterference(characterModel, HRP, originalCFrame)
		return
	end

	local baseCFrame = towerBase and towerBase.CFrame or originalCFrame
	HRP.CFrame = baseCFrame

	restoreInterference(characterModel, HRP, originalCFrame)
end

module["Beatdown"] = runBeatdown
module["Death Slam"] = runBeatdown

return module

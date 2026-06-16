local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local animateTowerEvent = events:WaitForChild("AnimateTower")
local GameSpeed = workspace.Info.GameSpeed

local function listAvailableAnimations(animationsFolder)
	local animationNames = {}

	for _, descendant in animationsFolder:GetDescendants() do
		if descendant:IsA("Animation") then
			table.insert(animationNames, descendant.Name)
		end
	end

	table.sort(animationNames)

	return if #animationNames > 0 then table.concat(animationNames, ", ") else "none"
end

local function findAnimationByName(animationsFolder, animName)
	local exactMatch = animationsFolder:FindFirstChild(animName)
	if exactMatch and exactMatch:IsA("Animation") then
		return exactMatch
	end

	local normalizedTarget = string.lower(animName)
	for _, descendant in animationsFolder:GetDescendants() do
		if descendant:IsA("Animation") and string.lower(descendant.Name) == normalizedTarget then
			return descendant
		end
	end

	return nil
end

local function resolveAnimationObject(animationsFolder, animName)
	local animationObject = findAnimationByName(animationsFolder, animName)
	if animationObject then
		return animationObject
	end

	if animName == "Walk" then
		return findAnimationByName(animationsFolder, "Run")
			or findAnimationByName(animationsFolder, "Idle")
	end

	return nil
end


local function setAnimation(object, animName)
	if not animName then
		return nil
	end

	local humanoid = object:WaitForChild("Humanoid", 10)
	local animationsFolder = object:WaitForChild("Animations", 10)

	if not humanoid or not animationsFolder then
		warn(`[Animations] {object.Name} is missing Humanoid or Animations folder.`)
		return nil
	end

	local animationObject = resolveAnimationObject(animationsFolder, animName)
	if not animationObject then
		warn(
			`[Animations] Could not resolve "{animName}" for {object.Name}. Available animations: {listAvailableAnimations(animationsFolder)}`
		)
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Name == animationObject.Name then
			return track
		end
	end

	local ok, animationTrack = pcall(function()
		return animator:LoadAnimation(animationObject)
	end)

	if not ok then
		warn(`[Animations] Failed to load "{animationObject.Name}" for {object.Name}: {animationTrack}`)
		return nil
	end

	return animationTrack
end

local function playAnimation(object, animName, speed, isEnemy)
	local animationTrack = setAnimation(object, animName)

	if animationTrack then
		if isEnemy then
			animationTrack.Looped = true
		end

		animationTrack:Play()
		animationTrack:AdjustSpeed(speed or 1)

		return animationTrack
	else
		return
	end
end

local info = workspace:WaitForChild('Info')

local function bindMobFolder(folder)
	for _, object in folder:GetChildren() do
		task.spawn(playAnimation, object, "Walk", GameSpeed.Value, true)
	end

	folder.ChildAdded:Connect(function(object)
		playAnimation(object, "Walk", GameSpeed.Value, true)
	end)
end

if not info.Versus.Value and not info.Competitive.Value then
	bindMobFolder(workspace:WaitForChild("Mobs"))
else
	bindMobFolder(workspace:WaitForChild("RedMobs"))
	bindMobFolder(workspace:WaitForChild("BlueMobs"))
end

workspace.Towers.ChildAdded:Connect(function(object)
	playAnimation(object, "Idle")
end)		

animateTowerEvent.OnClientEvent:Connect(function(tower, animName, target)
	local animtrack = playAnimation(tower, animName, GameSpeed.Value)
	if animtrack then
		if tower.Animations:FindFirstChild(animName):FindFirstChild("UnitAnimSpeed") then
			animtrack:AdjustSpeed(tower.Animations[animName].UnitAnimSpeed.Value*GameSpeed.Value)
		end
	end

end)

game.ReplicatedStorage.Events.StopAnimation.OnClientEvent:Connect(function(enemy, duration)
	for i, v in enemy.Humanoid:GetPlayingAnimationTracks() do
		v:AdjustSpeed(0)
	end
	task.wait(duration)
	for i, v in enemy.Humanoid:GetPlayingAnimationTracks() do
		v:AdjustSpeed(1)
	end
end)

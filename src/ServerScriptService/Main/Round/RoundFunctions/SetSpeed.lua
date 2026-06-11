local Info = workspace.Info
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Round = script.Parent.Parent
local Basic_mob_spawn_delay = 1
local Min_mob_spawn_delay = 0.1
local HigherSpeedGamePassId = 1823132888
local FreeSpeedLimit = 2
local AvailableSpeeds = {1, 2, 3, 5}

local speedMultiplier = 1

local module = {}

local function getCurrentSpeedMultiplier()
	local currentGameSpeed = workspace.Info.GameSpeed.Value
	if currentGameSpeed > 0 then
		return currentGameSpeed
	end

	return speedMultiplier
end

local function markHigherSpeedOwned(player)
	local ownGamePasses = player:FindFirstChild("OwnGamePasses")
	if not ownGamePasses then
		return
	end

	for _, passName in ipairs({"3x Speed", "5x Speed"}) do
		local passValue = ownGamePasses:FindFirstChild(passName)
		if passValue then
			passValue.Value = true
		end
	end
end

local function hasHigherSpeedAccess(player)
	local ownGamePasses = player:FindFirstChild("OwnGamePasses")
	if ownGamePasses then
		for _, passName in ipairs({"3x Speed", "5x Speed"}) do
			local passValue = ownGamePasses:FindFirstChild(passName)
			if passValue and passValue.Value then
				return true
			end
		end
	end

	local success, ownsPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, HigherSpeedGamePassId)
	end)

	if success and ownsPass then
		markHigherSpeedOwned(player)
		return true
	end

	if not success then
		warn("Failed to check higher speed gamepass:", ownsPass)
	end

	return false
end

local function promptHigherSpeedPurchase(player)
	pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, HigherSpeedGamePassId)
	end)
end

local function getRequestedSpeed(speed)
	if typeof(speed) == "number" and table.find(AvailableSpeeds, speed) then
		return speed
	end

	return nil
end

local function getNextSpeedMultiplier(currentSpeedMultiplier)
	local currentIndex = table.find(AvailableSpeeds, currentSpeedMultiplier)

	if not currentIndex then
		return AvailableSpeeds[1]
	end

	local nextIndex = currentIndex + 1

	if nextIndex > #AvailableSpeeds then
		nextIndex = 1
	end

	return AvailableSpeeds[nextIndex]
end

local function applySpeed(player, newSpeedMultiplier)
	speedMultiplier = newSpeedMultiplier

	ReplicatedStorage.Events.ChangeSpeed:FireAllClients(`{speedMultiplier}x`, player)

	Round:SetAttribute('MobSpawnDelay', math.max(Min_mob_spawn_delay, Basic_mob_spawn_delay / speedMultiplier))

	workspace.Info.GameSpeed.Value = speedMultiplier

	if player:FindFirstChild('Speed') then
		player.Speed.Value = speedMultiplier
	end

	for _, v in workspace.Mobs:GetChildren() do
		local humanoid = v:FindFirstChild("Humanoid")
		local originalSpeed = v:FindFirstChild("OriginalSpeed")

		if humanoid and originalSpeed then
			humanoid.WalkSpeed = originalSpeed.Value * speedMultiplier
		end
	end

	for _, v in workspace.Spawnables:GetChildren() do
		local humanoid = v:FindFirstChild("Humanoid") :: Humanoid

		if humanoid then
			local originalSpeed = v:FindFirstChild("OriginalSpeed")
			if not originalSpeed then
				originalSpeed = Instance.new('NumberValue', v)
				originalSpeed.Name = 'OriginalSpeed'
				originalSpeed.Value = humanoid.WalkSpeed
			end

			if originalSpeed then
				humanoid.WalkSpeed = originalSpeed.Value * speedMultiplier
			end
		end
	end
end

ReplicatedStorage.Functions.SpeedRemote.OnServerInvoke = function(player,speed)
	if not Info.GameRunning.Value then return false, "Wait until the match has started!" end
	if Info.Versus.Value then return false, "Changing this setting is disabled in Versus" end

	if workspace.Info.OwnerId.Value ~= 0 and player.UserId ~= workspace.Info.OwnerId.Value then
		return false, `only host can change speed`
	end

	if workspace.Info.SpeedCD.Value then
		return false, "Please Wait Before Changing Speed!"
	end

	local hasAccess = hasHigherSpeedAccess(player)
	local nextSpeedMultiplier = getRequestedSpeed(speed) or getNextSpeedMultiplier(getCurrentSpeedMultiplier())
	if nextSpeedMultiplier > FreeSpeedLimit and not hasAccess then
		applySpeed(player, 1)
		promptHigherSpeedPurchase(player)
		return false, "3x and 5x speed require the speed gamepass."
	end

	workspace.Info.SpeedCD.Value = true
	task.spawn(function()
		task.wait(3.2)
		workspace.Info.SpeedCD.Value = false
	end)

	applySpeed(player, nextSpeedMultiplier)

	return true
end

return module

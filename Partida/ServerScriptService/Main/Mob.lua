local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local towerModule = require(script.Parent.Tower)
local QuestHandler = require(game.ReplicatedStorage.Configs.QuestConfig)
local XPHandler = require(ReplicatedStorage:WaitForChild('EpisodeConfig').XPHandler)
local ClanQuestProgressScheduler = require(ServerScriptService.ClanService.ClanQuestsLib.ClanQuestProgressScheduler)
local GameBalance = require(ReplicatedStorage.Modules.GameBalance)
local info = workspace.Info

local mob = {}

local CHECK_INTERVAL = 0.08
local ORIGINAL_TRANSPARENCY_ATTRIBUTE = "OriginalMobTransparency"
local ORIGINAL_ENABLED_ATTRIBUTE = "OriginalMobEnabled"

local function ensureMobCollisionGroup()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Mob")
	end)

	pcall(function()
		PhysicsService:CollisionGroupSetCollidable("Mob", "Mob", false)
	end)
end

ensureMobCollisionGroup()

local function getGameSpeed()
	local gameSpeed = info:FindFirstChild("GameSpeed")
	if gameSpeed and gameSpeed.Value > 0 then
		return gameSpeed.Value
	end

	return 1
end

local function getSlowFactor(model)
	if model:GetAttribute("Slowness") then
		return model:GetAttribute("SlownessFactor") or 0.8
	end

	return 1
end

local function getScaledMobSpeed(model)
	local originalSpeed = model:FindFirstChild("OriginalSpeed")
	if not originalSpeed then
		return nil
	end

	return originalSpeed.Value * getGameSpeed() * getSlowFactor(model)
end

local function getModelRootPart(model)
	if not model or not model.Parent then
		return nil
	end

	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function getSpawnCFrameFromMap(map, team)
	if not info.Versus.Value then
		if map:FindFirstChild("Start") then
			return map.Start.CFrame * CFrame.new(Vector3.new(0, 3, 0))
		end

		local pathStart = map:FindFirstChild("Start" .. tostring(workspace.Info.PathNumber.Value))
		if pathStart then
			return pathStart.CFrame
		end
	elseif team then
		local teamStart = map:FindFirstChild(team .. "Start")
		if teamStart then
			return teamStart.CFrame
		end
	end

	return nil
end

local function setMobHidden(model, hidden)
	model:SetAttribute("MobHidden", hidden)

	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			if obj:GetAttribute(ORIGINAL_TRANSPARENCY_ATTRIBUTE) == nil then
				obj:SetAttribute(ORIGINAL_TRANSPARENCY_ATTRIBUTE, obj.Transparency)
			end
			obj.Transparency = if hidden then 1 else obj:GetAttribute(ORIGINAL_TRANSPARENCY_ATTRIBUTE)
		elseif obj:IsA("Decal") then
			if obj:GetAttribute(ORIGINAL_TRANSPARENCY_ATTRIBUTE) == nil then
				obj:SetAttribute(ORIGINAL_TRANSPARENCY_ATTRIBUTE, obj.Transparency)
			end
			obj.Transparency = if hidden then 1 else obj:GetAttribute(ORIGINAL_TRANSPARENCY_ATTRIBUTE)
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("BillboardGui") then
			if obj:GetAttribute(ORIGINAL_ENABLED_ATTRIBUTE) == nil then
				obj:SetAttribute(ORIGINAL_ENABLED_ATTRIBUTE, obj.Enabled)
			end
			obj.Enabled = if hidden then false else obj:GetAttribute(ORIGINAL_ENABLED_ATTRIBUTE)
		end
	end
end

local function stopMobMovement(model, reveal)
	if not model or not model.Parent then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = getModelRootPart(model)

	if reveal then
		setMobHidden(model, false)
	end

	if humanoid then
		humanoid.WalkSpeed = 0
	end

	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end

function incrementpercentage(n, t, p) 
	local r = n 
	for _ = 1, t do 
		r+=(r*p) 
	end 
	return r 
end

function mob.Move(newMob, map, team)
	local humanoid = newMob:WaitForChild("Humanoid")
	local root = newMob:WaitForChild("HumanoidRootPart")
	local waypoints

	if not info.Versus.Value then
		waypoints = map:FindFirstChild("Waypoints")
	else
		waypoints = map[team .. 'Waypoints']
	end

	if not waypoints then
		waypoints = map:FindFirstChild("Waypoints"..tostring(game.Workspace.Info.PathNumber.Value))
	end

	for waypoint=newMob.MovingTo.Value, #waypoints:GetChildren() do
		if not newMob:FindFirstChild("MovingTo") then
			return
		end

		if info.GameOver.Value then
			stopMobMovement(newMob, true)
			return
		end

		newMob.MovingTo.Value = waypoint
		local target = waypoints[waypoint].Position

		local scaledSpeed = getScaledMobSpeed(newMob)
		if scaledSpeed then
			humanoid.WalkSpeed = scaledSpeed
		end
		setMobHidden(newMob, false)
		humanoid:MoveTo(target)

		while newMob.Parent and root.Parent and humanoid.Health > 0 and (root.Position - target).Magnitude > 2.5 do
			if info.GameOver.Value then
				stopMobMovement(newMob, true)
				return
			end

			local currentScaledSpeed = getScaledMobSpeed(newMob)
			if currentScaledSpeed and humanoid.WalkSpeed ~= currentScaledSpeed then
				humanoid.WalkSpeed = currentScaledSpeed
			end
			humanoid:MoveTo(target)

			task.wait(CHECK_INTERVAL)
		end
	end

	if info.GameOver.Value then
		stopMobMovement(newMob, true)
		return
	end

	setMobHidden(newMob, false)

	if newMob.Parent then
		newMob:Destroy()
	end

	if not info.Versus.Value then
		map.Base.Humanoid:TakeDamage(math.min(humanoid.Health, map.Base.Humanoid.Health))
	else
		map[team .. 'Base'].Humanoid:TakeDamage(math.min(humanoid.Health, map[team .. 'Base'].Humanoid.Health))
	end
end

function mob.StopAll(revealHidden)
	for _, folderName in ipairs({"Mobs", "RedMobs", "BlueMobs"}) do
		local folder = workspace:FindFirstChild(folderName)
		if not folder then
			continue
		end

		for _, mobModel in ipairs(folder:GetChildren()) do
			stopMobMovement(mobModel, revealHidden)
		end
	end
end

local function cloneScript(mobType, parent)
	if not mobType then return end

	if script:FindFirstChild(mobType) then
		local scriptToCopy = script[mobType]:Clone()
		scriptToCopy.Parent = parent
		scriptToCopy.Enabled = true
	end
end

function mob.Spawn(name, quantity, map, old, health, money, speed, isBoss, unitStats, isbossrush, team)
	local mobExists = ReplicatedStorage.Enemies:FindFirstChild(name)
	local lastMob = old

	if mobExists then
		for i=1, quantity do
			local currentFront = lastMob
			if not getModelRootPart(currentFront) then
				currentFront = nil
			end
			local mvt = 1

			if currentFront and currentFront:FindFirstChild("MovingTo") then
				mvt = currentFront.MovingTo.Value
			end

			local newMob = mobExists:Clone()
			newMob:SetAttribute("MobHidden", false)

			if not newMob:FindFirstChild('Type') then
				local val = Instance.new('StringValue', newMob)
				val.Name = 'Type'
				val.Value = 'Ground'
			end

			if team then
				newMob:SetAttribute('Team', team)
			end

			local mobType = newMob:GetAttribute("Type")
			task.spawn(cloneScript, mobType, newMob)

			newMob.Humanoid.MaxHealth = GameBalance.ApplyEnemyHealth(health or newMob.Humanoid.MaxHealth, isBoss or isbossrush)
			newMob.Humanoid.Health = newMob.Humanoid.MaxHealth
			local baseSpeed = speed or (unitStats and unitStats.speed) or newMob.Humanoid.WalkSpeed
			if workspace.Info.TestingMode.Value then
				baseSpeed = 1
			end
			newMob.Humanoid.WalkSpeed = baseSpeed * getGameSpeed()

			local previousRoot = getModelRootPart(old)
			local spawnCFrame = previousRoot and previousRoot.CFrame or getSpawnCFrameFromMap(map, team)
			if spawnCFrame then
				newMob:PivotTo(spawnCFrame)
			end

			if team then
				newMob.Parent = workspace[team .. 'Mobs']
			else
				newMob.Parent = workspace.Mobs
			end

			newMob.HumanoidRootPart:SetNetworkOwner(nil)

			if not newMob:FindFirstChild("MovingTo") then
				local movingTo = Instance.new("IntValue")
				movingTo.Name = "MovingTo"
				movingTo.Value = mvt
				movingTo.Parent = newMob
			end

			local PathNumber = Instance.new("IntValue")
			PathNumber.Name = "PathNumber"
			PathNumber.Value = info.PathNumber.Value
			PathNumber.Parent = newMob

			local OriginalSpeed = Instance.new("NumberValue")
			OriginalSpeed.Name = "OriginalSpeed"
			OriginalSpeed.Value = baseSpeed
			OriginalSpeed.Parent = newMob

			if isBoss or isbossrush then
				local isBossBool = Instance.new("BoolValue")
				isBossBool.Name = "IsBoss"
				isBossBool.Value = true
				isBossBool.Parent = newMob
			end

			for _, object in newMob:GetDescendants() do
				if object:IsA("BasePart") then
					PhysicsService:SetPartCollisionGroup(object, "Mob")
				end
			end

			if not mobExists:GetAttribute("OriginalHealth") then 
				mobExists:SetAttribute("OriginalHealth", mobExists.Humanoid.MaxHealth) 
			end

			local OriginalHealth = mobExists:GetAttribute("OriginalHealth") 
			local HealthMultiplier = script.Parent:GetAttribute("EnemyHealthMultiplier")
			local info = workspace.Info

			newMob.Humanoid.Died:Connect(function()
				if typeof(money) == "number" then
					local moneyReward = GameBalance.ApplyEnemyKillMoney(money)
					for _, player in game.Players:GetPlayers() do
						local bypass = not info.Versus.Value

						if bypass or (player.Team and player.Team.Name == team) then
							player.Money.Value += moneyReward

							task.spawn(function()
								QuestHandler.UpdateProgressAll(player, "KillEnemies", 1)
								ClanQuestProgressScheduler.addToQueue(player, "Kills", 1)

								if isBoss or isbossrush then
									ClanQuestProgressScheduler.addToQueue(player, "Kills:Bosses", 1)
								end
							end)

							if isBoss then
								if not info.Infinity.Value and not info.Raid.Value and not isbossrush then
									QuestHandler.UpdateProgressAll(player, "KillStoryBosses", 1)
								end
							end
						end
					end
				end
				task.wait(0.2)
				if newMob.Parent then
					newMob:Destroy()
				end
			end)

			task.spawn(function()
				local function SelfDeleteOnEmptyBody()
					local countPart = 0
					for _, object in newMob:GetChildren() do
						if object:IsA("BasePart") then
							countPart += 1
						end
					end
					if countPart == 0 and newMob:FindFirstChild("Humanoid") and newMob.Humanoid.Health > 0 then
						newMob:Destroy()
					end
				end

				newMob.ChildRemoved:Connect(function()
					SelfDeleteOnEmptyBody()
				end)
			end)

			task.spawn(mob.Move, newMob, map, team)

			lastMob = newMob
		end

		return lastMob
	else
		warn("Requested mob does not exist:", name)
	end
end

return mob

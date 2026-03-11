local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["332nd Trooper Attack"] = function(HRP, target)
	local Folder = VFX.Epic["nd 332 Trooper"]
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(0.84/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local lookAtPos = enemypos + Vector3.new(0, -1, 0)

	local Ball = Folder:WaitForChild("Part"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.Pos.Position 
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)

	UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster1')

	task.wait(0.01/speed)
	if not HRP or not HRP.Parent then return end
	TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = lookAtPos}):Play()
	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end
	local explosion = Folder:WaitForChild("Explosionnnnns"):Clone()
	explosion.Position = enemypos
	explosion.Parent = vfxFolder
	Debris:AddItem(explosion,2)
	VFX_Helper.EmitAllParticles(explosion)
	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(Ball)
	Ball.Transparency = 1
	task.wait(1.2/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local tweenService = game:GetService("TweenService")
local LightningSparks = require(rs.VFXModules.LightningBolt.LightningSparks)
local LightningModule = require(rs.VFXModules.LightningModule)

local GameSpeed = workspace.Info.GameSpeed

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


module["Saber Slash"] = function(HRP, target)
	local Folder = VFX["3rd Sister"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local saber = Folder["Saber Slash"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed

	tween(saber, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)

	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing')

	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end




end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)


local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Commando Attack"] = function(HRP, target)
	local Folder = VFX.Epic.Commando
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.98/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector

	local connection = nil

	for i = 1, 12 do
		if not HRP or not HRP.Parent then return end

		local startPos = HRP.Parent["Right Arm"].Gunn.Pos.Position
		local scatterOffset = Vector3.new(math.random(-3, 3), math.random(-1, 1), math.random(-3, 3))
		local endPos = startPos + (direction * Range) + scatterOffset

		local Ball = Folder:WaitForChild("Part"):Clone()
		Ball.CFrame = HRP.Parent["Right Arm"].Gunn.Pos.CFrame
		Ball.Position = startPos
		Ball.Parent = vfxFolder
		Ball.Transparency = 0
		Debris:AddItem(Ball, 2 / speed)

		UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster2')

		connection = HRP.Parent.Destroying:Once(function()
			Ball:Destroy()
		end)

		--VFX_Helper.EmitAllParticles(HRP.Parent["Right Arm"].Gunn.Pos)

		task.delay(0.02 / speed, function()
			if Ball and Ball.Parent then
				local tween = TS:Create(Ball, TweenInfo.new(0.1 / speed, Enum.EasingStyle.Linear), {Position = endPos})
				tween:Play()
				tween.Completed:Connect(function()
					if Ball and Ball.Parent then
						Ball.Transparency = 1
						local Endlemit = Folder:WaitForChild("EndlEmit"):Clone()
						Endlemit.Position = endPos
						Endlemit.Parent = vfxFolder
						Debris:AddItem(Endlemit, 2 / speed)
						VFX_Helper.EmitAllParticles(Endlemit)
						--VFX_Helper.OffAllParticles(Ball)

					end
				end)
			end
		end)
	end

	task.wait(1.5 / speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)


local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local StoryModeStats = require(rs.StoryModeStats)

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0
	return weld
end

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 10

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end


module["Force Choke"] = function(HRP, target)
	warn("Force Choke")
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX["Eighth Brother"].First
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(1.1/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		for _, folder in folders do
			for i, mob in rs.Enemies[folder]:GetChildren() do
				if mob.Name == MobName then
					Mob = mob:Clone()
				end
			end
		end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end

	local forceChoke = anikinFolder["Force Choke"]:Clone()
	warn(anikinFolder["Force Choke"].Parent)
	forceChoke.Parent = workspace.VFX

	connect(forceChoke, Mob.HumanoidRootPart, CFrame.new(0,-1,0))
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end

	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = false
		end
	end

	Debris:AddItem(forceChoke, 2)

	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local repStorage = game:GetService('ReplicatedStorage')
local tweenService = game:GetService('TweenService')
local Debris = game:GetService("Debris")

local vfxFolder = repStorage.VFX
local supperCommandoVfx = vfxFolder["SuperCommando"]

local module = {}

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or particle.Rate

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0 or CFrame.new(0,0,0)
	weld.Parent = p0	

	return weld
end

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length), details):Play()
end

module["Turbo Laser"] = function(HRP, target)
	task.wait(.25)

	local folder = vfxFolder["Elite Commando"]
	local vfx = folder["Turbo Laser"]:Clone()

	if not HRP or not HRP.Parent then
		return
	end 

	HRP.Parent.Attacking.Value = true

	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z) 
	local dir = (HRP.Position-enemyPos).Unit

	enemyPos = enemyPos - (dir * 1.7)

	local travelSpeed = 50
	local timeToTravel = getMag(HRP.Position, enemyPos) / travelSpeed

	vfx.CFrame = HRP.CFrame
	vfx.Parent = workspace.VFX
	local weld = connect(vfx, HRP)

	local endPoint = vfx.EndPoint

	for _, instance in vfx:GetDescendants() do
		if instance:IsA("Beam") then
			instance.Enabled = true
		elseif instance:IsA("ParticleEmitter") then
			instance.Enabled = true
		end
	end

	UnitSoundEffectLib.playSound(HRP.Parent, "Blaster1")

	task.delay(.5, function()
		tween(vfx.EndPoint, timeToTravel, {WorldPosition = enemyPos})
	end)

	task.wait(timeToTravel + 2)

	if HRP and HRP.Parent then
		HRP.Parent.Attacking.Value = false
	end

	for _, instance in vfx:GetDescendants() do
		if instance:IsA("Beam") then
			instance.Enabled = false
		elseif instance:IsA("ParticleEmitter") then
			instance.Enabled = false
		end
	end

	if weld then
		weld:Destroy()
	end

	if vfx then
		vfx:Destroy()
	end
end

return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["C-3PO Farm Reward"] = function(HRP, target)
	local Folder = VFX.LEGA["C-3PO Farm"]
	local speed = GameSpeed.Value


	--VFX_Helper.SoundPlay(HRP,Folder.First)

	task.wait(0.7/speed)
	if not HRP or not HRP.Parent then return end

	local Emit = Folder:WaitForChild("GoldEmit"):Clone()
	Emit.Position = HRP.Position
	Emit.Parent = vfxFolder
	Debris:AddItem(Emit,3/speed)
	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(Emit)


end

return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Burst Fire"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Greedy.First
	local BallTemplate = Folder:WaitForChild("Ball")
	local vfxFolder = workspace:WaitForChild("VFX")

	VFX_Helper.SoundPlay(HRP, Folder.First)

	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	local points = {HRP.Parent.LPoint, HRP.Parent.RPoint}

	for i = 1, 4 do
		if not HRP or not HRP.Parent then return end

		local currentPoint = points[(i % 2) + 1]
		local Ball = BallTemplate:Clone()
		Ball.CFrame = currentPoint.CFrame
		Ball.Position = currentPoint.Position
		Ball.Parent = vfxFolder

		Debris:AddItem(Ball, 1 / speed)
		TS:Create(Ball, TweenInfo.new(0.13 / speed, Enum.EasingStyle.Linear), {
			Position = targetPosition
		}):Play()

		task.wait(0.5 / speed)
	end

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end



return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)


local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local tweenService = game:GetService("TweenService")

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


module["Heavy Machine Gun"] = function(HRP, target)
	local Folder = VFX.Heavy.First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	task.wait(0.3 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	--VFX_Helper.SoundPlay(HRP, Folder.Sound)
	local GunShoot = Folder["Heavy Machine gun"]:Clone()


	GunShoot.CFrame = HRP.CFrame
	GunShoot.Parent = HRP.Parent
	local Attatchments = GunShoot.Attachment
	local tableEmit = {}

	local speed = 5
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed

	tween(GunShoot, timeToTravel, {Position = enemyPos})

	UnitSoundEffectLib.playSound(HRP.Parent, 'LaserGun4')
	task.delay(timeToTravel, function()
		GunShoot:Destroy()
	end)

	for i,v in Attatchments:GetChildren() do
		table.insert(tableEmit, v)
	end

	warn(tableEmit, "Particles for gun")

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.2 / speed, function()
			v.Enabled = false
		end)
	end
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Scout Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Scout.First
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	UnitSoundEffectLib.playSound(HRP.Parent, 'LaserGun1')

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.Point.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.Point.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end



return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)


local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = game.Workspace.Info.GameSpeed
module["Jedai Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Jedai.First
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.1/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local starsemit = Folder:WaitForChild("Ground"):Clone()
	starsemit.Position = HRP.Position + Vector3.new(0,1.55,0)
	starsemit.Parent = HRP.Parent
	VFX_Helper.EmitAllParticles(starsemit)
	Debris:AddItem(starsemit,2/speed)
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	TS:Create(HRP, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + enemyCFrame.LookVector * -2.5}):Play()
	task.wait(0.1/speed)
	local Hit = Folder:WaitForChild("Emit"):Clone()
	Hit.Position = enemypos 
	Hit.Parent = vfxFolder
	Debris:AddItem(Hit,1/speed)
	task.spawn(function()
		task.wait(0.1/speed)
		VFX_Helper.EmitAllParticles(Hit)

	end)
	if not HRP or not HRP.Parent then return end

	task.wait(0.54/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end

return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Officer Attack"] = function(HRP, target)
	local Folder = VFX.Officer.First
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(0.3/speed)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Left Arm"].Handle.Positions.CFrame
	Ball.Position = HRP.Parent["Left Arm"].Handle.Positions.Position 
	Ball.Parent = vfxFolder
	UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster3')
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.15/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	VFX_Helper.EmitAllParticles(HRP.Parent["Left Arm"].Handle.Winnd)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	VFX_Helper.OffAllParticles(Ball)
	Ball.Transparency = 1
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local repStorage = game:GetService('ReplicatedStorage')
local tweenService = game:GetService('TweenService')
local Debris = game:GetService("Debris")

local vfxFolder = repStorage.VFX
local supperCommandoVfx = vfxFolder["SuperCommando"]

local module = {}

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or particle.Rate

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

module["Pistol and Rocket"] = function(HRP, target)
	local rocketExplosion = supperCommandoVfx["Rocket Explosion"]:Clone()

	UnitSoundEffectLib.playSound(HRP.Parent, 'Rockets1')


	task.delay(1.3, function()
		rocketExplosion.CFrame = HRP.CFrame * CFrame.new(0,0,-2)
		rocketExplosion.Parent = workspace.VFX
		UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

		for _, particle in rocketExplosion:GetDescendants() do
			if not particle:IsA("ParticleEmitter") then continue end
			emitParticles(particle)
		end

		Debris:AddItem(rocketExplosion, 2)
	end)
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = game.Workspace.Info.GameSpeed
local StoryModeStats = require(rs.StoryModeStats)
function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0
	return weld
end

local function emit(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 10

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end



local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")

module["Fury"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dart Wader Maskless"].First
	local characterModel = HRP.Parent
	local Range = characterModel.Config:WaitForChild("Range").Value
	local enemyPos = target:GetPivot().Position

	local originalCFrame = characterModel:GetPivot()
	UnitSoundEffectLib.playSound(HRP.Parent, 'Flamethrower')
	task.wait(1 / speed)  -- adjusted timing here
	if not HRP or not HRP.Parent then return end

	characterModel.Attacking.Value = true

	local SaberDash = Folder["Fury"]:Clone()

	for _, part in pairs(SaberDash:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
		end
	end

	SaberDash.Parent = workspace.VFX
	SaberDash.CFrame = HRP.CFrame
	Debris:AddItem(SaberDash, 1.5 / speed)

	local distance = (HRP.Position - enemyPos).Magnitude
	local timeToTravel = math.max(0.5, distance / speed)

	TS:Create(SaberDash, TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear), {Position = enemyPos}):Play()

	for _, v in pairs(SaberDash:GetChildren()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = true
		elseif v:IsA("Attachment") then
			for _, child in pairs(v:GetChildren()) do
				if child:IsA("ParticleEmitter") or child:IsA("Beam") then
					child.Enabled = true
				end
			end
		end
	end

	task.delay(0.5 / speed, function()
		for _, v in pairs(SaberDash:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = false
			end
		end
	end)

	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15 / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()

	task.wait(1 / speed)
	if not HRP or not HRP.Parent then return end

	characterModel:PivotTo(originalCFrame)
	characterModel.Attacking.Value = false
end





module["Force Slam"] = function(HRP: BasePart, target: Model)
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX["Dart Wader Maskless"].Second
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(1.1/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps

		Mob = target

		--for _, folder in folders do
		--	for i, mob in rs.Enemies[folder]:GetChildren() do
		--		if mob.Name == MobName then
		--			Mob = mob:Clone()
		--		end
		--	end
		--end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	--Debris:AddItem(Mob,2/speed)
	--local connection = HRP.Parent.Destroying:Once(function()
	--	Mob:Destroy()
	--end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end

	local forceChoke = anikinFolder["force slam"]:Clone()
	forceChoke.Parent = workspace.VFX

	connect(forceChoke, Mob.HumanoidRootPart, CFrame.new(0,-1,0))

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end

	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = false
		end
	end

	Debris:AddItem(forceChoke, 2)

	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	--local returnTween = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	--	CFrame = CFrame.new(enemypos, enemypos + Mob.HumanoidRootPart.CFrame.LookVector)
	--})
	--returnTween:Play()

	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end

	task.delay(1/speed, function()
		if Mob and Mob:FindFirstChild("HumanoidRootPart") then
			Mob.HumanoidRootPart.Anchored = false
		end
	end)

	HRP.Parent.Attacking.Value = false
	--connection:Disconnect()

end



module["AOE Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dart Wader Maskless"].Third
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end


	task.wait(0.7/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')

	local Emit = Folder:WaitForChild("aoe"):Clone()
	Emit.Position = HRP.Position
	Emit.Parent = vfxFolder
	Debris:AddItem(Emit,7/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Emit:Destroy()
	end)
	TS:Create(HRP,TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear),{CFrame = HRP.CFrame * CFrame.new(0, 4, 0)}):Play()
	--HRP.Anchored = true
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end


	if not HRP or not HRP.Parent then return end

	VFX_Helper.OnAllParticles(Emit)

	local points = {}
	local center = HRP.Position

	for i = 1, 18 do
		local angle = math.rad((360 / 18) * i)
		local radius = 15
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local y = math.random(-3, 7)
		table.insert(points, center + Vector3.new(x, y, z))
	end

	for i = 1, #points do
		if not HRP or not HRP.Parent then return end
		HRP.CFrame = CFrame.new(points[i])
		task.wait((1.75 / #points) / speed)
	end


	VFX_Helper.OffAllParticles(Emit)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end


	--HRP.Anchored = false

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local VFX = rs.VFX
local GameSpeed = workspace.Info.GameSpeed
local RunService = game:GetService("RunService")
local TS = game:GetService("TweenService")
local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


module["Beatdown"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Armored Commando"].Second
	local characterModel = HRP.Parent
	local Range = characterModel.Config:WaitForChild("Range").Value
	local enemyPos = target:GetPivot().Position

	local originalCFrame = characterModel:GetPivot()

	task.wait(0.78 / speed)
	if not HRP or not HRP.Parent then return end

	characterModel.Attacking.Value = true


	local SaberDash = Folder["run and punch"]:Clone()
	SaberDash.Parent = workspace.VFX
	SaberDash.CFrame = HRP.CFrame

	local distance = (HRP.Position - enemyPos).Magnitude
	local timeToTravel = distance / speed

	TS:Create(SaberDash, TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear), {Position = enemyPos}):Play()

	task.delay(timeToTravel, function()
		if SaberDash and SaberDash.Parent then
			SaberDash:Destroy()
		end
	end)

	for _, v in pairs(SaberDash:GetChildren()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = true
		elseif v:IsA("Attachment") then
			for _, child in pairs(v:GetChildren()) do
				if child:IsA("ParticleEmitter") or child:IsA("Beam") then
					child.Enabled = true
				end
			end
		end
	end


	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()

	local cancel = false
	task.spawn(function()
		while task.wait(0.2) do
			if cancel then break end
			UnitSoundEffectLib.playSound(HRP.Parent, "Punch" .. tostring(math.random(1,3)))
		end
	end)

	task.wait(1 / speed)
	cancel = true
	if not HRP or not HRP.Parent then return end
	characterModel:PivotTo(originalCFrame)

	characterModel.Attacking.Value = false
end



module["Death Slam"] = function(HRP, target)
	local Model = HRP.Parent
	local speed = GameSpeed.Value
	local Folder = VFX["Armored Commando"].First
	local Range = Model.Config:WaitForChild("Range").Value
	local enemyHRP = target:FindFirstChild("HumanoidRootPart")
	if not enemyHRP then return end

	local originalCFrame = Model:FindFirstChild("TowerPart") and Model.TowerPart.CFrame or Model:GetPivot()
	local enemyPos = enemyHRP.Position

	task.wait(0.2 / speed)
	if not HRP or not HRP.Parent then return end
	Model.Attacking.Value = true

	local JumpVFX = Folder["death slam"]
	for _, attachment in JumpVFX:GetChildren() do
		if attachment:IsA("Attachment") then
			for _, emitter in attachment:GetChildren() do
				if emitter:IsA("ParticleEmitter") then
					emitter:Emit(emitter.Rate > 0 and emitter.Rate or 30)
				end
			end
		end
	end

	local jumpHeight = 25
	local jumpTime = 0.35 / speed
	local slamTime = 0.2 / speed

	UnitSoundEffectLib.playSound(HRP.Parent, "Blaster" .. tostring(math.random(1,3)))
	local jumpTween = TS:Create(Model.PrimaryPart, TweenInfo.new(jumpTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = HRP.CFrame * CFrame.new(0, jumpHeight, 0)
	})
	jumpTween:Play()
	jumpTween.Completed:Wait()

	local slamCFrame = CFrame.new(enemyPos + Vector3.new(0, 4, 0)) -- Slam just above enemy
	local slamTween = TS:Create(Model.PrimaryPart, TweenInfo.new(slamTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = slamCFrame
	})
	slamTween:Play()
	slamTween.Completed:Wait()


	task.wait(0.15 / speed)


	local returnTween = TS:Create(Model.PrimaryPart, TweenInfo.new(0.3 / speed, Enum.EasingStyle.Linear), {
		CFrame = originalCFrame
	})
	returnTween:Play()
	returnTween.Completed:Wait()

	Model.Attacking.Value = false
end



return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Money Reward"] = function(HRP, target)
	local Folder = VFX["B2 Farm"].First
	local speed = GameSpeed.Value

	if not HRP or not HRP.Parent then return end

	VFX_Helper.SoundPlay(HRP,Folder.First)

	local Emit = Folder:WaitForChild("Part"):Clone()
	Emit.Position = HRP.Position + Vector3.new(0,-1,0)
	Emit.Parent = vfxFolder
	Debris:AddItem(Emit,2)
	task.wait(0.1/speed)
	VFX_Helper.EmitAllParticles(Emit)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	local emitUp = Folder:WaitForChild("GoldEmit"):Clone()
	emitUp.Position = HRP.Position
	emitUp.Parent = vfxFolder
	Debris:AddItem(emitUp,3/speed)
	VFX_Helper.EmitAllParticles(emitUp)

end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Crossblast"] = function(HRP, target)
	local speed = GameSpeed.Value
	local x = 0.3
	local Folder = VFX["Chompy"].First
	local BallTemplate = Folder:WaitForChild("Ball")
	local vfxFolder = workspace:WaitForChild("VFX")

	task.wait(1 / speed)
	VFX_Helper.SoundPlay(HRP, Folder.First)

	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	for i = 1, 3 do
		if not HRP or not HRP.Parent then return end

		local Ball = BallTemplate:Clone()
		Ball.CFrame = HRP.Parent.Point.CFrame
		Ball.Position = HRP.Parent.Point.Position
		Ball.Parent = vfxFolder

		Debris:AddItem(Ball, 1 / speed)
		TS:Create(Ball, TweenInfo.new(0.13 / speed, Enum.EasingStyle.Linear), {
			Position = targetPosition
		}):Play()

		UnitSoundEffectLib.playSound(HRP.Parent, 'BlasterBurst1')

		task.wait(x / speed)
	end

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Air Shot"] = function(HRP)
	local speed = GameSpeed.Value
	local Folder = VFX.Scout.First
	local GunPoint = HRP.Parent["Right Arm"].Gun.Point

	task.wait(1 / speed)

	VFX_Helper.SoundPlay(HRP, Folder.First)


	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = GunPoint.CFrame
	Ball.Position = GunPoint.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball, 1 / speed)

	local targetPosition = HRP.Position + Vector3.new(0, 10, 0)

	UnitSoundEffectLib.playSound(HRP.Parent, 'LaserGun' .. tostring(math.random(1,4)))

	TS:Create(Ball, TweenInfo.new(0.13 / speed, Enum.EasingStyle.Linear), {
		Position = targetPosition
	}):Play()

	task.wait(0.1)

	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RunService = game:GetService("RunService")
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

module["Dakar Guard Attack"] = function(HRP, target)
	local Folder = VFX["Dakar Guard"].first
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].sword.CFrame 
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].sword
	weld.Part1 = trail
	weld.Parent = trail
	local Start = HRP.CFrame
	local End = CFrame.new(enemypos + Vector3.new(0, 0, 0)) 
	local Offset = (End.Position - HRP.Position).unit * -2 
	End = CFrame.new(enemypos + Offset) 

	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0, 4, 0))
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0, 3, 0))

	local startRotation = HRP.CFrame - HRP.Position
	local startCFrame = HRP.CFrame
	UnitSoundEffectLib.playSound(HRP.Parent, 'Flamethrower')
	task.spawn(function()
		task.wait(0.5/speed)
		local Emit = Folder:WaitForChild("Pos"):Clone()
		Emit.Position = enemypos + Vector3.new(0,1,0)
		Emit.CFrame = HRP.CFrame 
		Emit.Parent = vfxFolder
		Debris:AddItem(Emit, 2/speed)
		VFX_Helper.EmitAllParticles(Emit)
	end)
	task.spawn(function()
		task.wait(0.1/speed)
		local startemit = Folder:WaitForChild("StartEmit"):Clone()
		startemit.CFrame = startCFrame + Vector3.new(0, -1, 0)
		startemit.Parent = vfxFolder
		Debris:AddItem(startemit, 2/speed)
		VFX_Helper.EmitAllParticles(startemit)

		local teleposrtter = Folder:WaitForChild("teleport"):Clone()
		teleposrtter.CFrame = startCFrame + Vector3.new(0, -0.5, 0)
		teleposrtter.Parent = vfxFolder    
		Debris:AddItem(teleposrtter, 1/speed)
		VFX_Helper.EmitAllParticles(teleposrtter)
	end)


	for i = 1, 100, 4.3 do
		local t = i / 100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.fromMatrix(NewPos, startRotation.XVector, startRotation.YVector, startRotation.ZVector)

		task.wait(0.005/speed)
	end

	task.wait(0.88/speed)
	local teleposr = Folder:WaitForChild("teleport"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr, 1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end

module["Whirlwind Slash"] = function(HRP, target)
	local Folder = VFX["Dakar Guard"].Second
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local AOEEmit = Folder:WaitForChild("AOE_emit"):Clone()
	AOEEmit.CFrame = HRP.CFrame
	AOEEmit.Parent = HRP
	Debris:AddItem(AOEEmit,2.5/speed)
	VFX_Helper.EmitAllParticles(AOEEmit)

	HRP.Parent.Attacking.Value = false
end




return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Rifle Blast"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dark Trooper"].First
	task.wait(1/speed)

	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	print(Range, "new range")
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local function createBall(fromPoint)
		local Ball = Folder:WaitForChild("Ball"):Clone()
		Ball.CFrame = fromPoint.CFrame
		Ball.Position = fromPoint.Position
		Ball.Parent = vfxFolder
		Debris:AddItem(Ball, 1/speed)

		TS:Create(Ball, TweenInfo.new(0.13/speed, Enum.EasingStyle.Linear), {Position = targetPosition}):Play()

		task.delay(0.13/speed, function()
			if HRP and HRP.Parent then
				Ball.Transparency = 1
			end
		end)
	end

	local parentModel = HRP.Parent
	if parentModel then
		local rightPoint = parentModel:FindFirstChild("RightHand") and parentModel.RightHand:FindFirstChild("Point")
		local leftPoint = parentModel:FindFirstChild("LeftHand") and parentModel.LeftHand:FindFirstChild("Point")

		if rightPoint and leftPoint then
			UnitSoundEffectLib.playSound(HRP.Parent, 'LaserGun' .. tostring(math.random(1,4)))
			createBall(rightPoint)
			createBall(leftPoint)
		end
	end

	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false

end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Rifle Blast"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Death Trooper"].First
	task.wait(1/speed)

	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	print(Range, "new range")
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.Point.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.Point.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	UnitSoundEffectLib.playSound(HRP.Parent, 'BlasterBurst1')
	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Eileen Secra Attack"] = function(HRP, target)
	local Folder = VFX["Eileen Secra"].First
	local speed = GameSpeed.Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0, math.rad(90), 0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail, 2/speed)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail

	task.wait(0.5/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local emitHRP = Folder:WaitForChild("EffectHRP"):Clone()
	emitHRP.CFrame = HRP.CFrame
	emitHRP.Parent = HRP.Parent
	Debris:AddItem(emitHRP, 3/speed)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = emitHRP
	weld.Parent = emitHRP
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local steps = 12  
	local duration = 0.4 / steps 
	local amplitude = 3.5 
	VFX_Helper.OnAllParticles(trail.Effect)
	local finalPosition = HRP.CFrame * CFrame.new(0, 0, -Range)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing2')

	for i = 1, steps do
		local progress = i / steps 
		local smoothProgress = math.sin(progress * math.pi * 0.4)  
		local dynamicAmplitude = amplitude * (1 - progress) 
		local offset = math.sin(progress * math.pi * 4) * dynamicAmplitude  
		local intermediatePosition = startCFrame:Lerp(finalPosition, smoothProgress)  
		intermediatePosition = intermediatePosition * CFrame.new(offset, 0, 0)  

		TS:Create(HRP, TweenInfo.new(duration/speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = intermediatePosition}):Play()
		task.wait(duration/speed)
	end


	VFX_Helper.OffAllParticles(emitHRP)
	VFX_Helper.OffAllParticles(trail.Effect)

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame

	HRP.Parent.Attacking.Value = false
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Heavy Trooper Attack"] = function(HRP, target)
	local Folder = VFX["Heavy Trooper"].First
	local speed = GameSpeed.Value

	--VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, -0.4, -Range)).Position

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Regular.Ball.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Regular.Ball.Position 
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	task.wait(0.02/speed)
	local emitgun = HRP.Parent["Right Arm"].Regular.Ball
	VFX_Helper.EmitAllParticles(emitgun)
	UnitSoundEffectLib.playSound(HRP.Parent, 'EliteBlaster1')

	TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(Ball)
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local specialVfx = require(game.ReplicatedStorage.Modules.VFX.SpecialVFX)
local towerInfo = require(game.ReplicatedStorage.Modules.Helpers.TowerInfo)


local GameSpeed = workspace.Info.GameSpeed
module["Ice Stomp"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Hoth Trooper"].First
	task.wait(0.4/speed)
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local range = towerInfo.GetRange(HRP.Parent)
	local distance = math.floor((range / 10) * 7) 

	UnitSoundEffectLib.playSound(HRP.Parent, 'IceAttack')
	specialVfx.IceStomp(HRP.Parent, HRPCF * CFrame.new(0, -1.2, -1), distance, Vector3.new(1, 1, 1), 0.5, 2.5, 0.025)


	task.wait(0.1/speed)
	HRP.Parent.Attacking.Value = false

	if not HRP or not HRP.Parent then return end

end



return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local tweenService = game:GetService("TweenService")
local LightningSparks = require(rs.VFXModules.LightningBolt.LightningSparks)
local LightningModule = require(rs.VFXModules.LightningModule)

local GameSpeed = workspace.Info.GameSpeed

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


module["Saber Slash"] = function(HRP, target)
	local Folder = VFX["Jedai Jay"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local saber = Folder["Saber Slash"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed

	tween(saber, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end




end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = game.Workspace.Info.GameSpeed
local RocksModule = require(rs.Modules.RocksModule)

module["Ki Mundi Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.LEGA["Ki Mundi"].First
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	local handleR = HRP.Parent["Right Arm"].Handle.Trail
	handleR.Enabled = true

	task.wait(0.75/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local Emit = Folder:WaitForChild("Slashes"):Clone()
	Emit.CFrame = HRP.CFrame
	Emit.Parent = HRP
	Debris:AddItem(Emit,4/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = Emit
	weld.Parent = Emit

	local connection = HRP.Parent.Destroying:Once(function()
		Emit:Destroy()
	end)

	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -(Range - 2))
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	VFX_Helper.OnAllParticles(trail)
	task.wait(0.09/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(Emit)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(trail)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	local teleposr = Folder:WaitForChild("teleport"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr, 1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposttt = Folder:WaitForChild("teleport"):Clone()
	teleposttt.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposttt.Parent = vfxFolder	
	Debris:AddItem(teleposttt, 1/speed)
	VFX_Helper.EmitAllParticles(teleposttt)
	handleR.Enabled = false
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)

local GameSpeed = workspace.Info.GameSpeed

module["Lyminora Attack"] = function(HRP, target)
	local Folder = VFX.Lyminora.First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	local connection = nil

	for i = 1, 5 do

		if not HRP or not  HRP.Parent then return end
		local randomoffset = Vector3.new(math.random(-3,3),-1,math.random(-3,3))
		local readyrand = enemypos + randomoffset
		local Ball = Folder:WaitForChild("Ball"):Clone()
		Ball.CFrame = HRP.Parent["Right Arm"].Regular.Pos.CFrame
		Ball.Position = HRP.Parent["Right Arm"].Regular.Pos.Position 
		Ball.Parent = vfxFolder
		Debris:AddItem(Ball,2/speed)
		connection = HRP.Parent.Destroying:Once(function()
			Ball:Destroy()
		end)
		TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = readyrand}):Play()
		VFX_Helper.EmitAllParticles(HRP.Parent["Right Arm"].Regular.Winnd)
		task.wait(0.09/speed)
		if not HRP or not HRP.Parent then return end
		local Endlemit = Folder:WaitForChild("EndlEmit"):Clone()
		Endlemit.Position = readyrand
		Endlemit.Parent = vfxFolder
		Debris:AddItem(Endlemit,2/speed)
		VFX_Helper.EmitAllParticles(Endlemit)
		VFX_Helper.OffAllParticles(Ball)
		Ball.Transparency = 1

		UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster' .. tostring(math.random(1,3)))
	end

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local vfxFolder = workspace.VFX
local supperCommandoVfx = game:GetService("ReplicatedStorage").VFX.Purge
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local tweenService = game:GetService("TweenService")

local module = {}

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or particle.Rate

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

module["Electric Blast"] = function(HRP, target)
	local rocketExplosion = supperCommandoVfx.First["electric blast"]:Clone()

	task.delay(0.3, function()
		rocketExplosion.CFrame = HRP.CFrame * CFrame.new(0,0,-2)
		rocketExplosion.Parent = workspace.VFX

		UnitSoundEffectLib.playSound(HRP.Parent, 'Thunder')

		for _, particle in rocketExplosion:GetDescendants() do
			if not particle:IsA("ParticleEmitter") then continue end
			emitParticles(particle)
		end

		Debris:AddItem(rocketExplosion, 2)
	end)
end


module["Electric Judgement"] = function(HRP, target)
	local Folder = VFX.Purge.Second
	local speed = GameSpeed.Value
	local characterModel = HRP.Parent
	local enemyPos = target:GetPivot().Position
	local distance = (HRP.Position - enemyPos).Magnitude
	local timeToTravel = math.clamp(distance / 5, 0.5, 1.5)

	task.wait(0.3 / speed)
	if not HRP or not HRP.Parent then return end

	characterModel.Attacking.Value = true

	local BallTemplate = Folder:FindFirstChild("Ball")
	if not BallTemplate then error("Ball effect missing in VFX.Purge.Second") end

	local Ball = BallTemplate:Clone()
	Ball.CFrame = HRP.CFrame
	Ball.Parent = workspace.VFX

	local attachment1 = Ball.Ball


	for _, v in attachment1:GetChildren() do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end



	TS:Create(Ball, TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear), {Position = enemyPos}):Play()
	UnitSoundEffectLib.playSound(HRP.Parent, 'Thunder')

	Debris:AddItem(Ball, timeToTravel)




	characterModel.Attacking.Value = false
end





return modulelocal ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)

local LightningSparks = require(rs.VFXModules.LightningBolt.LightningSparks)
local LightningModule = require(rs.VFXModules.LightningModule)

local GameSpeed = workspace.Info.GameSpeed

module["Red Guard Attack"] = function(HRP, target)
	local Folder = VFX["Red Guard"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	local lightning = HRP.Parent["Right Arm"].Handle.PosPart	
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(lightning)
	task.wait(0.73/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local StartAttachment = Folder:WaitForChild("start"):Clone()
	StartAttachment.Position = HRP.Parent["Right Arm"].Handle.PosPart.Position
	StartAttachment.Parent = vfxFolder
	Debris:AddItem(StartAttachment,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle.PosPart
	weld.Part1 = StartAttachment
	weld.Parent = StartAttachment
	
	local EndAttachment = Folder:WaitForChild("end"):Clone()
	EndAttachment.Position = enemypos + Vector3.new(0,-1,0)
	EndAttachment.Parent = vfxFolder
	Debris:AddItem(EndAttachment,2/speed)
	local Lightning = LightningModule.new(StartAttachment.Attachment, EndAttachment.Attachment, 9)
	Lightning.MinRadius = 0.5 
	Lightning.MaxRadius = 1 
	Lightning.AnimationSpeed = 5 
	Lightning.FadeLength = 0.5 
	Lightning.PulseLength = 5 
	Lightning.Thickness = 0.5
	Lightning.MinTransparency, Lightning.MaxTransparency = 0.3, 2.5 
	Lightning.ContractFrom = 3
	Lightning.PulseSpeed = math.random(8, 12) 
	Lightning.MinThicknessMultiplier, Lightning.MaxThicknessMultiplier = 0.3, 0.5 
	Lightning.Color = ColorSequence.new(Color3.fromRGB(199, 0, 149), Color3.fromRGB(199, 0, 149)) 

	UnitSoundEffectLib.playSound(HRP.Parent, 'Thunder')

	LightningSparks.new(Lightning)
	local endemit = Folder:WaitForChild("PartDown"):Clone()
	endemit.Position = enemypos + Vector3.new(0,-1,0)
	endemit.Parent = vfxFolder
	Debris:AddItem(endemit,3/speed)
	VFX_Helper.EmitAllParticles(endemit)
	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(lightning)
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)

local LightningSparks = require(rs.VFXModules.LightningBolt.LightningSparks)
local LightningModule = require(rs.VFXModules.LightningModule)

local GameSpeed = workspace.Info.GameSpeed

module["Red Guard Attack"] = function(HRP, target)
	local Folder = VFX["Red Guard"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	local lightning = HRP.Parent["Right Arm"].Handle.PosPart	
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(lightning)
	task.wait(0.73/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local StartAttachment = Folder:WaitForChild("start"):Clone()
	StartAttachment.Position = HRP.Parent["Right Arm"].Handle.PosPart.Position
	StartAttachment.Parent = vfxFolder
	Debris:AddItem(StartAttachment,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle.PosPart
	weld.Part1 = StartAttachment
	weld.Parent = StartAttachment

	local EndAttachment = Folder:WaitForChild("end"):Clone()
	EndAttachment.Position = enemypos + Vector3.new(0,-1,0)
	EndAttachment.Parent = vfxFolder
	Debris:AddItem(EndAttachment,2/speed)
	local Lightning = LightningModule.new(StartAttachment.Attachment, EndAttachment.Attachment, 9)
	Lightning.MinRadius = 0.5 
	Lightning.MaxRadius = 1 
	Lightning.AnimationSpeed = 5 
	Lightning.FadeLength = 0.5 
	Lightning.PulseLength = 5 
	Lightning.Thickness = 0.5
	Lightning.MinTransparency, Lightning.MaxTransparency = 0.3, 2.5 
	Lightning.ContractFrom = 3
	Lightning.PulseSpeed = math.random(8, 12) 
	Lightning.MinThicknessMultiplier, Lightning.MaxThicknessMultiplier = 0.3, 0.5 
	Lightning.Color = ColorSequence.new(Color3.fromRGB(199, 0, 149), Color3.fromRGB(199, 0, 149)) 

	UnitSoundEffectLib.playSound(HRP.Parent, 'Thunder')

	LightningSparks.new(Lightning)
	local endemit = Folder:WaitForChild("PartDown"):Clone()
	endemit.Position = enemypos + Vector3.new(0,-1,0)
	endemit.Parent = vfxFolder
	Debris:AddItem(endemit,3/speed)
	VFX_Helper.EmitAllParticles(endemit)
	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(lightning)
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local tweenService = game:GetService("TweenService")
local LightningSparks = require(rs.VFXModules.LightningBolt.LightningSparks)
local LightningModule = require(rs.VFXModules.LightningModule)

local GameSpeed = workspace.Info.GameSpeed

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


module["Saber Throw"] = function(HRP, target)
	local Folder = VFX["Second Sister"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local saber = Folder["Saber Throw"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed


	HRP.Parent.Attacking.Value = true

	tween(saber, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end

	for i,v in saber:GetChildren() do
		if v:IsA("Attachment") then
			continue
		else
			v.Enabled = true
		end
	end


	HRP.Parent.Attacking.Value = false
end



return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local VFX = rs.VFX
local GameSpeed = workspace.Info.GameSpeed
local RunService = game:GetService("RunService")
local TS = game:GetService("TweenService")
local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


module["Saber Dash"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Seventh Sister"].First
	local characterModel = HRP.Parent
	local Range = characterModel.Config:WaitForChild("Range").Value
	local enemyPos = target:GetPivot().Position

	local originalCFrame = characterModel:GetPivot()

	task.wait(0.78 / speed)
	if not HRP or not HRP.Parent then return end

	characterModel.Attacking.Value = true


	local SaberDash = Folder["Saber Dash"]:Clone()
	SaberDash.Parent = workspace.VFX
	SaberDash.CFrame = HRP.CFrame

	local distance = (HRP.Position - enemyPos).Magnitude
	local timeToTravel = distance / speed

	TS:Create(SaberDash, TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear), {Position = enemyPos}):Play()
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))


	task.delay(timeToTravel, function()
		if SaberDash and SaberDash.Parent then
			SaberDash:Destroy()
		end
	end)

	for _, v in pairs(SaberDash:GetChildren()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = true
		elseif v:IsA("Attachment") then
			for _, child in pairs(v:GetChildren()) do
				if child:IsA("ParticleEmitter") or child:IsA("Beam") then
					child.Enabled = true
				end
			end
		end
	end


	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()

	task.wait(1 / speed)
	if not HRP or not HRP.Parent then return end
	characterModel:PivotTo(originalCFrame)

	characterModel.Attacking.Value = false
end



return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameSpeed = workspace.Info.GameSpeed
local effectsFolder = ReplicatedStorage.VFX
local wreckerVFX = effectsFolder.Wrecker

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0	

	return weld
end

local function tween(obj, length, details)
	TweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local module = {}

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameSpeed = workspace.Info.GameSpeed
local effectsFolder = ReplicatedStorage.VFX
local wreckerVFX = effectsFolder.Wrecker

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0	

	return weld
end

local function tween(obj, length, details)
	TweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local module = {}

module["Run it down"] = function(HRP, target)
	local Folder = wreckerVFX
	local speed = GameSpeed.Value * 16

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	if not HRP or not HRP.Parent then return end

	local mag = getMag(HRP.Position, target:GetPivot().Position)
	tween(HRP, mag/speed, {CFrame = CFrame.new(enemypos)})

	HRP.Parent.Attacking.Value = true

	local vfx = Folder.RunItDown:Clone()
	vfx.Parent = workspace.VFX

	local weld = connect(vfx, HRP, CFrame.new(0,-.5,0))

	for _, particle in vfx:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = true
	end

	local stop = false

	task.spawn(function()
		while not stop do
			UnitSoundEffectLib.playSound(HRP.Parent, 'Punch' .. tostring(math.random(1,3)))
			task.wait(1)
		end
	end)

	task.wait(mag / speed)

	if not HRP or not HRP.Parent then return end

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame

	for _, particle in vfx:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = false
	end

	stop = true
	HRP.Parent.Attacking.Value = false

	for _, track in HRP.Parent.Humanoid.Animator:GetPlayingAnimationTracks() do
		if track.Animation.AnimationId == "128527655134187" or track.Animation.AnimationId == "rbxassetid://128527655134187" then
			track:Stop(.1)
		end
	end

	Debris:AddItem(vfx, 2)
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length), details):Play()
end
local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

module["Saber Slash"] = function(HRP, target)
	local Folder = VFX["Bo Kotan"]
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local saber = Folder["Saber Slash"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	tween(saber, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)


	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end
end

module["Saber Slam"] = function(HRP, target)
	local Folder = VFX["Bo Kotan"]
	local speed = GameSpeed.Value

	if not HRP or not HRP.Parent then return end
	local character = HRP.Parent

	local spawnPoint = character:FindFirstChild("SpawnPoint")
	if not spawnPoint then
		spawnPoint = Instance.new("Part")
		spawnPoint.Name = "SpawnPoint"
		spawnPoint.Size = Vector3.new(0.5, 0.5, 0.5)
		spawnPoint.Anchored = true
		spawnPoint.CanCollide = false
		spawnPoint.Transparency = 1
		spawnPoint.CFrame = HRP.CFrame
		spawnPoint.Parent = character
	end

	local enemyPos = target:GetPivot().Position
	local travelSpeed = 16
	local travelTime = (HRP.Position - enemyPos).Magnitude / travelSpeed

	local saberSmoke = Folder["SaberSlamSmoke"]:Clone()
	saberSmoke.Parent = workspace.Terrain
	saberSmoke.Position = enemyPos
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	local startTime = tick()
	while tick() - startTime < travelTime do
		local alpha = (tick() - startTime) / travelTime
		HRP.CFrame = HRP.CFrame:Lerp(CFrame.new(enemyPos), alpha)
		task.wait()
	end

	HRP.CFrame = CFrame.new(enemyPos)

	VFX_Helper.EmitAllParticles(saberSmoke)

	task.delay(1, function()
		if saberSmoke then
			saberSmoke:Destroy()
		end
	end)

	task.wait(0.2)

	if spawnPoint then
		HRP.CFrame = spawnPoint.CFrame
	end
end


return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Hip Shot"] = function(HRP, target)
	local Folder = VFX["Bob"]["Hip Shot"]
	local speed = GameSpeed.Value

	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent.Point.CFrame
	Ball.Position = HRP.Parent.Point.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end

module["Rocket Shot"] = function(HRP, target)
	local Folder = VFX["Bob"].Rocket
	local speed = GameSpeed.Value

	local Ball = Folder:WaitForChild("Ball"):Clone()
	local start = HRP.Position + Vector3.new(0, 2, 0) 
	local finish = target.HumanoidRootPart.Position + Vector3.new(0, -2, 0)
	local mid = (start + finish) / 2 + Vector3.new(0, 3, 0)

	Ball.Position = HRP.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball, 2/speed)
	VFX_Helper.SoundPlay(HRP, "Sniper" .. tostring(math.random(1,3)))

	TS:Create(Ball, TweenInfo.new(0.25/speed, Enum.EasingStyle.Linear), {Position = start}):Play()
	task.wait(0.25/speed)

	local t = 0
	local duration = 0.5 / speed
	local steps = 30
	for i = 1, steps do
		t = i / steps
		local a = start:Lerp(mid, t)
		local b = mid:Lerp(finish, t)
		local bezier = a:Lerp(b, t)
		Ball.Position = bezier

		if i == steps then
			local vfxPart = Folder.Explosion:Clone()
			vfxPart.Position = finish
			vfxPart.Parent = workspace.Terrain
			VFX_Helper.EmitAllParticles(vfxPart.Explosion)
			VFX_Helper.SoundPlay(vfxPart, "Explosion")
			Debris:AddItem(vfxPart, 2)

		end

		task.wait(duration / steps)
	end


	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end


module["Rocket Barrage"] = function(HRP, target)
	local Folder = VFX["Bob"].Rocket
	local speed = GameSpeed.Value

	local rocketCount = 3
	local delayBetween = 1 / speed 
	local xOffsets = {-1, 0, 1}

	HRP.Parent.Attacking.Value = true

	for i = 1, rocketCount do
		task.spawn(function()
			local xOffset = xOffsets[i]
			local rise = 2 + i

			local Ball = Folder:WaitForChild("Ball"):Clone()
			local start = HRP.Position + Vector3.new(xOffset, rise, 0)
			local finish = target.HumanoidRootPart.Position + Vector3.new(0, -2, 0)
			local mid = (start + finish) / 2 + Vector3.new(0, 3, 0)

			Ball.Position = HRP.Position
			Ball.Parent = vfxFolder
			Debris:AddItem(Ball, 2 / speed)
			VFX_Helper.SoundPlay(HRP, "Sniper" .. tostring(math.random(1,3)))

			TS:Create(Ball, TweenInfo.new(0.25 / speed, Enum.EasingStyle.Linear), {Position = start}):Play()
			task.wait(0.25 / speed)

			local t = 0
			local duration = 0.5 / speed
			local steps = 30
			for j = 1, steps do
				t = j / steps
				local a = start:Lerp(mid, t)
				local b = mid:Lerp(finish, t)
				local bezier = a:Lerp(b, t)
				Ball.Position = bezier
				task.wait(duration / steps)
			end

			local vfxPart = Folder.Explosion:Clone()
			vfxPart.Position = finish
			vfxPart.Parent = workspace.Terrain
			VFX_Helper.EmitAllParticles(vfxPart.Explosion)
			VFX_Helper.SoundPlay(vfxPart, "Explosion")
			Debris:AddItem(vfxPart, 2)

			Ball.Transparency = 1
		end)

		task.wait(delayBetween)
	end


	task.wait(1)
	HRP.Parent.Attacking.Value = false
end




return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Hip Shot"] = function(HRP, target)
	local Folder = VFX["Bob"]["Hip Shot"]
	local speed = GameSpeed.Value

	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent.Point.CFrame
	Ball.Position = HRP.Parent.Point.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end

module["Rocket Shot"] = function(HRP, target)
	local Folder = VFX["Bob"].Rocket
	local speed = GameSpeed.Value

	local Ball = Folder:WaitForChild("Ball"):Clone()
	local start = HRP.Position + Vector3.new(0, 2, 0) 
	local finish = target.HumanoidRootPart.Position + Vector3.new(0, -2, 0)
	local mid = (start + finish) / 2 + Vector3.new(0, 3, 0)

	Ball.Position = HRP.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball, 2/speed)
	VFX_Helper.SoundPlay(HRP, "Sniper" .. tostring(math.random(1,3)))

	TS:Create(Ball, TweenInfo.new(0.25/speed, Enum.EasingStyle.Linear), {Position = start}):Play()
	task.wait(0.25/speed)

	local t = 0
	local duration = 0.5 / speed
	local steps = 30
	for i = 1, steps do
		t = i / steps
		local a = start:Lerp(mid, t)
		local b = mid:Lerp(finish, t)
		local bezier = a:Lerp(b, t)
		Ball.Position = bezier

		if i == steps then
			local vfxPart = Folder.Explosion:Clone()
			vfxPart.Position = finish
			vfxPart.Parent = workspace.Terrain
			VFX_Helper.EmitAllParticles(vfxPart.Explosion)
			VFX_Helper.SoundPlay(vfxPart, "Explosion")
			Debris:AddItem(vfxPart, 2)

		end

		task.wait(duration / steps)
	end


	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end


module["Rocket Barrage"] = function(HRP, target)
	local Folder = VFX["Bob"].Rocket
	local speed = GameSpeed.Value

	local rocketCount = 3
	local delayBetween = 1 / speed 
	local xOffsets = {-1, 0, 1}

	HRP.Parent.Attacking.Value = true

	for i = 1, rocketCount do
		task.spawn(function()
			local xOffset = xOffsets[i]
			local rise = 2 + i

			local Ball = Folder:WaitForChild("Ball"):Clone()
			local start = HRP.Position + Vector3.new(xOffset, rise, 0)
			local finish = target.HumanoidRootPart.Position + Vector3.new(0, -2, 0)
			local mid = (start + finish) / 2 + Vector3.new(0, 3, 0)

			Ball.Position = HRP.Position
			Ball.Parent = vfxFolder
			Debris:AddItem(Ball, 2 / speed)
			VFX_Helper.SoundPlay(HRP, "Sniper" .. tostring(math.random(1,3)))

			TS:Create(Ball, TweenInfo.new(0.25 / speed, Enum.EasingStyle.Linear), {Position = start}):Play()
			task.wait(0.25 / speed)

			local t = 0
			local duration = 0.5 / speed
			local steps = 30
			for j = 1, steps do
				t = j / steps
				local a = start:Lerp(mid, t)
				local b = mid:Lerp(finish, t)
				local bezier = a:Lerp(b, t)
				Ball.Position = bezier
				task.wait(duration / steps)
			end

			local vfxPart = Folder.Explosion:Clone()
			vfxPart.Position = finish
			vfxPart.Parent = workspace.Terrain
			VFX_Helper.EmitAllParticles(vfxPart.Explosion)
			VFX_Helper.SoundPlay(vfxPart, "Explosion")
			Debris:AddItem(vfxPart, 2)

			Ball.Transparency = 1
		end)

		task.wait(delayBetween)
	end


	task.wait(1)
	HRP.Parent.Attacking.Value = false
end




return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameSpeed = workspace.Info.GameSpeed
local effectsFolder = ReplicatedStorage.VFX
local vfx = workspace.VFX
local wreckerVFX = effectsFolder.Wrecker

local VFX_Helper = require(ReplicatedStorage.Modules.VFX_Helper)

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0	

	return weld
end

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local module = {}

module["Double Sabre Throw"] = function(HRP: BasePart, target: Model)
	local Folder = ReplicatedStorage.VFX["Brevious"].First
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value

	task.wait(0.3/speed)

	if not HRP or not HRP.Parent then
		error("No rootpart / parent for unit")
	end

	if not target or not target:FindFirstChild("HumanoidRootPart") then 
		error("No rootpart / parent for target")
	end

	HRP.Parent.Attacking.Value = true

	local blueLightSaber = HRP.Parent.RightArmBlueSaber
	local greenLightSaber = HRP.Parent.LeftArmGreenSaber
	local HRPCF = HRP.CFrame
	local startPosition = blueLightSaber.Position 
	local targetPosition = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)



	for _, part in blueLightSaber:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.Transparency = 1
		end
		if part:IsA("ParticleEmitter") then
			part.Enabled = false
		end
	end

	for _, part in greenLightSaber:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.Transparency = 1
		end
		if part:IsA("ParticleEmitter") then
			part.Enabled = false
		end
	end

	local emit = Folder:WaitForChild("BluePart"):Clone()
	local emit2 = Folder:WaitForChild("GreenPart"):Clone()
	emit.Position = (HRP.CFrame * CFrame.new(0.5,0.8,-.2)).Position
	emit.Parent = vfx
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	Debris:AddItem(emit,3/speed)

	print(Range)

	local tween = TS:Create(emit, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = targetPosition + Vector3.new(0,0,-25)})
	tween:Play()

	print("Playing tween on: " .. emit.Name)

	task.wait(0.3/speed)

	if not HRP or not HRP.Parent then
		error("No rootpart / parent for unit")
	end

	if not target or not target:FindFirstChild("HumanoidRootPart") then 
		error("No rootpart / parent for target")
	end

	emit2.Position = (HRP.CFrame * CFrame.new(-0.5,0.8,-.5)).Position
	emit2.Parent = vfx
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing2')
	Debris:AddItem(emit2, 3/speed)

	TS:Create(emit2, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = targetPosition + Vector3.new(0,0,-25)}):Play()

	local handleTween = TS:Create(emit, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = blueLightSaber.Position})
	handleTween:Play()

	handleTween.Completed:Once(function()
		if emit then
			for _, particle in emit:GetDescendants() do
				if not particle:IsA("ParticleEmitter") then continue end
				particle.Enabled = false
			end

			task.delay(1, function()
				if emit then
					emit:Destroy()
				end
			end)
		end

		for _, part in blueLightSaber:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				part.Transparency = 0
			end
			if part:IsA("ParticleEmitter") then
				part.Enabled = true
			end
		end
	end)

	task.wait(0.3/speed)

	if not HRP or not HRP.Parent then
		error("No rootpart / parent for unit")
	end

	if not target or not target:FindFirstChild("HumanoidRootPart") then 
		error("No rootpart / parent for target")
	end

	local returnTween = TS:Create(emit2, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = greenLightSaber.Position})
	returnTween:Play()

	returnTween.Completed:Once(function()
		if emit2 then
			for _, particle in emit2:GetDescendants() do
				if not particle:IsA("ParticleEmitter") then continue end
				particle.Enabled = false
			end

			task.delay(1, function()
				if emit2 then
					emit2:Destroy()
				end
			end)
		end

		for _, part in greenLightSaber:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				part.Transparency = 0
			end
			if part:IsA("ParticleEmitter") then
				part.Enabled = true
			end
		end
	end)

	HRP.Parent.Attacking.Value = false
end

module["Sabre Spin"] = function(HRP: BasePart, target: Model)
	local Folder = ReplicatedStorage.VFX["Brevious"].Second
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value

	task.wait(0.3/speed)

	if not HRP or not HRP.Parent then 
		warn("No humanoid root part..")
		return 
	end

	HRP.Parent.Attacking.Value = true

	local blueLightSaber = HRP.Parent.RightArmBlueSaber
	local HRPCF = HRP.CFrame
	local startPosition = blueLightSaber.Position 
	local targetPosition = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	for _, part in blueLightSaber:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.Transparency = 1
		end
		if part:IsA("ParticleEmitter") then
			part.Enabled = false
		end
	end

	local emit = Folder:WaitForChild("Sabre Spin"):Clone()

	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	emit.Position = (HRP.CFrame * CFrame.new(0.5,0.8,-.2)).Position
	emit.Parent = vfx
	Debris:AddItem(emit,3/speed)

	local tween = TS:Create(emit, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = targetPosition + Vector3.new(0,0,-25)})
	tween:Play()

	task.wait(0.3/speed)

	if not HRP or not HRP.Parent then 
		return 
	end

	local handleTween = TS:Create(emit, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = blueLightSaber.Position})
	handleTween:Play()

	handleTween.Completed:Once(function()
		if emit then
			for _, particle in emit:GetDescendants() do
				if not particle:IsA("ParticleEmitter") then continue end
				particle.Enabled = false
			end

			task.delay(1, function()
				if emit then
					emit:Destroy()
				end
			end)
		end

		for _, part in blueLightSaber:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				part.Transparency = 0
			end
			if part:IsA("ParticleEmitter") then
				part.Enabled = true
			end
		end
	end)

	HRP.Parent.Attacking.Value = false
end

module["Sabre Barrage"] = function(HRP, target)
	local Folder = ReplicatedStorage.VFX["Brevious"].Third
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value * 16

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	if not HRP or not HRP.Parent then return end

	local mag = getMag(HRP.Position, target:GetPivot().Position)
	tween(HRP, mag/speed, {CFrame = CFrame.new(enemypos)})

	HRP.Parent.Attacking.Value = true

	local breviousFx = Folder["Sabre Barrage"]:Clone()
	breviousFx.Parent = workspace.VFX

	local weld = connect(breviousFx.PrimaryPart, HRP, CFrame.new(0,-.5,0))

	for _, particle in breviousFx:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = true
	end

	task.wait(mag / speed)

	if not HRP or not HRP.Parent then return end

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	for _, particle in breviousFx:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = false
	end

	HRP.Parent.Attacking.Value = false

	for _, track in HRP.Parent.Humanoid.Animator:GetPlayingAnimationTracks() do
		if track.Animation.AnimationId == "86170606432550" or track.Animation.AnimationId == "rbxassetid://86170606432550" then
			track:Stop(.1)
		end
	end

	Debris:AddItem(breviousFx, 2)
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)


local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameSpeed = workspace.Info.GameSpeed
local effectsFolder = ReplicatedStorage.VFX
local vfx = workspace.VFX
local wreckerVFX = effectsFolder.Wrecker

local VFX_Helper = require(ReplicatedStorage.Modules.VFX_Helper)

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0	

	return weld
end

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local module = {}

module["Double Sabre Throw"] = function(HRP: BasePart, target: Model)
	local Folder = ReplicatedStorage.VFX["Brevious"].First
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value

	task.wait(0.3/speed)

	if not HRP or not HRP.Parent then 
		warn("No humanoid root part..")
		return 
	end

	HRP.Parent.Attacking.Value = true

	local blueLightSaber = HRP.Parent.RightArmBlueSaber
	local greenLightSaber = HRP.Parent.LeftArmGreenSaber
	local HRPCF = HRP.CFrame
	local startPosition = blueLightSaber.Position 
	local targetPosition = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	for _, part in blueLightSaber:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.Transparency = 1
		end
		if part:IsA("ParticleEmitter") then
			part.Enabled = false
		end
	end

	for _, part in greenLightSaber:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.Transparency = 1
		end
		if part:IsA("ParticleEmitter") then
			part.Enabled = false
		end
	end

	local emit = Folder:WaitForChild("BluePart"):Clone()
	local emit2 = Folder:WaitForChild("GreenPart"):Clone()
	emit.Position = (HRP.CFrame * CFrame.new(0.5,0.8,-.2)).Position
	emit.Parent = vfx
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	Debris:AddItem(emit,3/speed)

	print(Range)

	local tween = TS:Create(emit, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = targetPosition + Vector3.new(0,0,-25)})
	tween:Play()

	print("Playing tween on: " .. emit.Name)

	task.wait(0.3/speed)

	if not HRP or not HRP.Parent then 
		return 
	end

	emit2.Position = (HRP.CFrame * CFrame.new(-0.5,0.8,-.5)).Position
	emit2.Parent = vfx
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing2')
	Debris:AddItem(emit2, 3/speed)

	TS:Create(emit2, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = targetPosition + Vector3.new(0,0,-25)}):Play()

	local handleTween = TS:Create(emit, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = blueLightSaber.Position})
	handleTween:Play()

	handleTween.Completed:Once(function()
		if emit then
			for _, particle in emit:GetDescendants() do
				if not particle:IsA("ParticleEmitter") then continue end
				particle.Enabled = false
			end

			task.delay(1, function()
				if emit then
					emit:Destroy()
				end
			end)
		end

		for _, part in blueLightSaber:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				part.Transparency = 0
			end
			if part:IsA("ParticleEmitter") then
				part.Enabled = true
			end
		end
	end)

	task.wait(0.3/speed)

	if not HRP or not HRP.Parent then return end

	local returnTween = TS:Create(emit2, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = greenLightSaber.Position})
	returnTween:Play()

	returnTween.Completed:Once(function()
		if emit2 then
			for _, particle in emit2:GetDescendants() do
				if not particle:IsA("ParticleEmitter") then continue end
				particle.Enabled = false
			end

			task.delay(1, function()
				if emit2 then
					emit2:Destroy()
				end
			end)
		end

		for _, part in greenLightSaber:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				part.Transparency = 0
			end
			if part:IsA("ParticleEmitter") then
				part.Enabled = true
			end
		end
	end)

	HRP.Parent.Attacking.Value = false
end

module["Sabre Spin"] = function(HRP: BasePart, target: Model)
	local Folder = ReplicatedStorage.VFX["Brevious"].Second
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value

	task.wait(0.3/speed)

	if not HRP or not HRP.Parent then 
		warn("No humanoid root part..")
		return 
	end

	HRP.Parent.Attacking.Value = true

	local blueLightSaber = HRP.Parent.RightArmBlueSaber
	local HRPCF = HRP.CFrame
	local startPosition = blueLightSaber.Position 
	local targetPosition = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	for _, part in blueLightSaber:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.Transparency = 1
		end
		if part:IsA("ParticleEmitter") then
			part.Enabled = false
		end
	end

	local emit = Folder:WaitForChild("Sabre Spin"):Clone()
	emit.Position = (HRP.CFrame * CFrame.new(0.5,0.8,-.2)).Position
	emit.Parent = vfx
	Debris:AddItem(emit,3/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	local tween = TS:Create(emit, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = targetPosition + Vector3.new(0,0,-25)})
	tween:Play()

	task.wait(0.3/speed)

	if not HRP or not HRP.Parent then 
		return 
	end

	local handleTween = TS:Create(emit, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {Position = blueLightSaber.Position})
	handleTween:Play()

	handleTween.Completed:Once(function()
		if emit then
			for _, particle in emit:GetDescendants() do
				if not particle:IsA("ParticleEmitter") then continue end
				particle.Enabled = false
			end

			task.delay(1, function()
				if emit then
					emit:Destroy()
				end
			end)
		end

		for _, part in blueLightSaber:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				part.Transparency = 0
			end
			if part:IsA("ParticleEmitter") then
				part.Enabled = true
			end
		end
	end)

	HRP.Parent.Attacking.Value = false
end

module["Sabre Barrage"] = function(HRP, target)
	warn("Saber barrage..")

	local Folder = ReplicatedStorage.VFX["Brevious"].Third
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value * 16

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	if not HRP or not HRP.Parent then return end

	local mag = getMag(HRP.Position, target:GetPivot().Position)
	tween(HRP, mag/speed, {CFrame = CFrame.new(enemypos)})

	HRP.Parent.Attacking.Value = true

	local breviousFx = Folder["Sabre Barrage"]:Clone()
	breviousFx.Parent = workspace.VFX

	local weld = connect(breviousFx.PrimaryPart, HRP, CFrame.new(0,-1,0))

	for _, particle in breviousFx:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = true
	end
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	task.wait(mag / speed)

	if not HRP or not HRP.Parent then return end

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame

	for _, particle in breviousFx:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = false
	end

	HRP.Parent.Attacking.Value = false

	for _, track in HRP.Parent.Humanoid.Animator:GetPlayingAnimationTracks() do
		if track.Animation.AnimationId == "106829327004680" or track.Animation.AnimationId == "rbxassetid://106829327004680" then
			track:Stop(.1)
		end
	end

	Debris:AddItem(breviousFx, 4)
end

return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Captain Reks Attack"] = function(HRP, target)
	local Folder = VFX["Captain Reks"].First
	local speed = GameSpeed.Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector

	task.wait(0.45/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].gun.Point.CFrame
	Ball.Position = HRP.Parent["Right Arm"].gun.Point.Position 
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	task.wait(0.01/speed)

	local emitgun = HRP.Parent["Right Arm"].gun.Point
	VFX_Helper.EmitAllParticles(emitgun)
	TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	VFX_Helper.OffAllParticles(Ball)

	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end

	local Secondball = Folder:WaitForChild("Ball"):Clone()
	Secondball.CFrame = HRP.Parent["Left Arm"].gun2.Point2.CFrame
	Secondball.Position = HRP.Parent["Left Arm"].gun2.Point2.Position
	Secondball.Parent = vfxFolder
	Debris:AddItem(Secondball,1/speed)
	task.wait(0.01/speed)

	local SecondEmit = HRP.Parent["Left Arm"].gun2.Point2
	VFX_Helper.EmitAllParticles(SecondEmit)
	TS:Create(Secondball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	Secondball.Transparency = 1
	VFX_Helper.OffAllParticles(Secondball)

	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end

	local Thrball = Folder:WaitForChild("Ball"):Clone()
	Thrball.CFrame = HRP.Parent["Right Arm"].gun.Point.CFrame
	Thrball.Position = HRP.Parent["Right Arm"].gun.Point.Position 
	Thrball.Parent = vfxFolder
	Debris:AddItem(Thrball,1/speed)
	task.wait(0.01/speed)
	VFX_Helper.EmitAllParticles(emitgun)
	TS:Create(Thrball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	Thrball.Transparency = 1
	VFX_Helper.OffAllParticles(Thrball)

	HRP.Parent.Attacking.Value = false
end


module["Hurricane Blaster"] = function(HRP, target)
	local Folder = VFX["Captain Reks"].Second
	local speed = GameSpeed.Value

	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.First)
	task.wait(0.45/speed)
	if not HRP or not HRP.Parent then return end

	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local rightGun = HRP.Parent["Right Arm"].gun.Point
	local leftGun = HRP.Parent["Left Arm"].gun2.Point2

	for i = 1, 50 do
		if not HRP or not HRP.Parent then return end 

		local isRight = (i % 2 == 1) 
		local gunPoint = isRight and rightGun or leftGun

		local Ball = Folder:WaitForChild("Ball"):Clone()
		Ball.CFrame = gunPoint.CFrame 
		Ball.Parent = vfxFolder
		Debris:AddItem(Ball, 1)
		task.wait(0.01/speed)
		VFX_Helper.EmitAllParticles(gunPoint)

		local forwardPosition = Ball.CFrame * CFrame.new(0, 0, -Range)

		TS:Create(Ball, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = forwardPosition}):Play()

		task.wait(0.06/speed)
		if not HRP or not HRP.Parent then return end
		task.spawn(function()
			task.wait(0.05/speed)
			Ball.Transparency = 1
			VFX_Helper.OffAllParticles(Ball)
		end)


		if not HRP or not HRP.Parent then return end
	end

	HRP.Parent.Attacking.Value = false
end

module["Double Squall"] = function(HRP, target)
	local Folder = VFX["Captain Reks"].Thrid
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.45 / speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	task.wait(0.45 / speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.First)

	local rightGunEmit = HRP.Parent["Right Arm"].gun.Point
	local leftGunEmit = HRP.Parent["Left Arm"].gun2.Point2

	local RightBall = Folder:WaitForChild("Ball"):Clone()
	RightBall.CFrame = rightGunEmit.CFrame
	RightBall.Position = rightGunEmit.Position
	RightBall.Parent = vfxFolder
	Debris:AddItem(RightBall, 1 / speed)

	local LeftBall = Folder:WaitForChild("Ball"):Clone()
	LeftBall.CFrame = leftGunEmit.CFrame
	LeftBall.Position = leftGunEmit.Position
	LeftBall.Parent = vfxFolder
	Debris:AddItem(LeftBall, 1 / speed)
	VFX_Helper.EmitAllParticles(HRP.Parent["Right Arm"].gun.Point)
	VFX_Helper.EmitAllParticles(HRP.Parent["Left Arm"].gun2.Point2)
	task.wait(0.01)
	TS:Create(RightBall, TweenInfo.new(0.1 / speed, Enum.EasingStyle.Linear), {Position = enemypos + Vector3.new(0,-1,0)}):Play()
	TS:Create(LeftBall, TweenInfo.new(0.1 / speed, Enum.EasingStyle.Linear), {Position = enemypos + Vector3.new(0,-1,0)}):Play()

	task.wait(0.1 / speed)
	if not HRP or not HRP.Parent then return end
	local explosion = Folder:WaitForChild("Explosion"):Clone()
	explosion.Position = enemypos + Vector3.new(0,-0.7,0)
	explosion.Parent = vfxFolder
	Debris:AddItem(explosion,3)
	VFX_Helper.EmitAllParticles(explosion)
	RightBall.Transparency = 1
	LeftBall.Transparency = 1
	VFX_Helper.OffAllParticles(RightBall)
	VFX_Helper.OffAllParticles(LeftBall)


	HRP.Parent.Attacking.Value = false
end



return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end


module["Rocket Shot"] = function(HRP, target)
	local Folder = VFX["Commander Codi 222th"].First
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(0.7 / speed)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Rockets' .. tostring(math.random(1,2)))

	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	task.wait(0.1 / speed)
	if not HRP or not HRP.Parent then return end

	local heandemit = HRP.Parent["Right Arm"].Gun.emit

	local rocket = Folder:WaitForChild("Rocket"):Clone()
	local startPos = HRP.Parent["Right Arm"].Gun.Pos.Position
	local lookAtPos = enemypos + Vector3.new(0, -1, 0)
	rocket.CFrame = CFrame.lookAt(startPos, lookAtPos)
	rocket.Parent = vfxFolder
	Debris:AddItem(rocket, 2 / speed)
	local connection = HRP.Parent.Destroying:Once(function()
		rocket:Destroy()
	end)
	task.wait(0.01 / speed)
	if not HRP or not HRP.Parent then return end

	TS:Create(rocket, TweenInfo.new(0.2 / speed, Enum.EasingStyle.Linear), {Position = lookAtPos}):Play()
	task.wait(0.04 / speed)
	if not HRP or not HRP.Parent then return end

	--VFX_Helper.OnAllParticles(rocket.FistProjecile)
	VFX_Helper.EmitAllParticles(heandemit)
	task.wait(0.05 / speed)
	if not HRP or not HRP.Parent then return end

	local Endlemit = Folder:WaitForChild("Explosion"):Clone()
	Endlemit.Position = enemypos
	Endlemit.Parent = vfxFolder
	Debris:AddItem(Endlemit, 2 / speed)
	task.wait(0.02 / speed)
	if not HRP or not HRP.Parent then return end

	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	VFX_Helper.EmitAllParticles(Endlemit)
	VFX_Helper.OffAllParticles(rocket)
	rocket.Transparency = 1

	task.wait(1)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Alpha Strike"] = function(HRP, target)
	local Folder = VFX["Commander Codi 222th"].Second
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	HRP.Parent.Attacking.Value = true
	task.wait(0.15/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	if not HRP or not HRP.Parent then return end
	local connection = nil
	for i = 1, 8 do
		if not HRP or not  HRP.Parent then return end
		local randomoffset = Vector3.new(math.random(-5.5,5.5),-1,math.random(-5.5,5.5))
		local readyrand = enemypos + randomoffset
		local Ball = Folder:WaitForChild("Part"):Clone()
		Ball.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
		Ball.Position = HRP.Parent["Right Arm"].Gun.Pos.Position 
		Ball.Parent = vfxFolder
		Debris:AddItem(Ball,2/speed)
		connection = HRP.Parent.Destroying:Once(function()
			Ball:Destroy()
		end)
		UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster' .. tostring(math.random(1,3)))
		task.wait(0.01/speed)
		TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = readyrand}):Play()
		VFX_Helper.EmitAllParticles(HRP.Parent["Right Arm"].Gun.Pos.Winnd)
		task.wait(0.1/speed)
		if not HRP or not HRP.Parent then return end
		local Endlemit = Folder:WaitForChild("Explosion"):Clone()
		Endlemit.Position = readyrand + Vector3.new(0,0.23,0)
		Endlemit.Parent = vfxFolder
		Debris:AddItem(Endlemit,2/speed)
		VFX_Helper.EmitAllParticles(Endlemit)
		VFX_Helper.OffAllParticles(Ball)
		Ball.Transparency = 1
	end

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


module["High Energy Shot"] = function(HRP, target)
	local Folder = VFX["Commander Codi 222th"].Thrid
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.75/speed)
	if not HRP or not HRP.Parent then return end
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	HRP.Parent.Attacking.Value = true

	local zalpNNP = Folder:WaitForChild("Startemit"):Clone()
	zalpNNP.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	zalpNNP.Parent = HRP.Parent
	Debris:AddItem(zalpNNP,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Gun.Pos
	weld.Part1 = zalpNNP
	weld.Parent = zalpNNP
	VFX_Helper.OnAllParticles(zalpNNP)
	VFX_Helper.ScaleParticles(zalpNNP,2)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end


	local lych = Folder:WaitForChild("Lych"):Clone()
	lych.chargegalickgun.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	lych.End.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	lych.Parent = vfxFolder
	Debris:AddItem(lych, 4/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		lych:Destroy()
	end)
	local targetPosition = CFrame.new(enemypos + Vector3.new(0, -1, 0)) 
	TS:Create(lych.End, TweenInfo.new(0.25/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetPosition}):Play()
	VFX_Helper.OffAllParticles(zalpNNP)
	VFX_Helper.OnAllParticles(lych.chargegalickgun)
	UnitSoundEffectLib.playSound(HRP.Parent, 'LaserGun' .. tostring(math.random(1,4)))
	task.wait(0.22/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(lych.End)
	VFX_Helper.ScaleParticles(lych.End,2.2)

	task.wait(0.18/speed)
	if not HRP or not HRP.Parent then return end
	for _, v in (lych:GetChildren()) do
		if v:IsA("Beam") then 
			v.Enabled = true
		end
	end

	task.wait(0.9/speed)
	if not HRP or not HRP.Parent then return end

	for _,v in (lych:GetDescendants()) do	
		if v:IsA("Beam") then
			TS:Create(
				v,
				TweenInfo.new(0.5/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Width0 = 0,Width1 = 0}
			):Play()
		end	
	end
	VFX_Helper.OffAllParticles(lych.End)
	VFX_Helper.OffAllParticles(lych.chargegalickgun)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end




return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length), details):Play()
end
local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

module["Saber Throw"] = function(HRP, target)
	local Folder = VFX.Count.First
	local CountFolder = VFX.Count
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value

	print(Range)

	task.wait(0.78/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local lightsaber = HRP.Parent:WaitForChild("Ground1")
	local HRPCF = HRP.CFrame
	local startPosition = lightsaber.Position 
	local targetPosition = HRPCF * CFrame.new(0, 0, -Range)

	VFX_Helper.Transparency(lightsaber, 1)
	local emit = Folder:WaitForChild("Sabre Throw"):Clone()
	emit.CFrame = HRP.CFrame * CFrame.new(0.5,0.8,-1.4)
	emit.Parent = vfxFolder
	Debris:AddItem(emit,2/speed)
	VFX_Helper.EmitAllParticles(emit)

	local Handle: BasePart = CountFolder.First.Saber:Clone()
	Handle.Anchored = true
	Handle.Parent = vfxFolder

	Debris:AddItem(Handle, 2.5/speed)

	VFX_Helper.OffAllParticles(lightsaber)
	for _, part in lightsaber:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end

	Handle.CFrame = HRPCF * CFrame.Angles(math.rad(90), 0, 0)
	local connection = HRP.Parent.Destroying:Once(function()
		Handle:Destroy()
	end)

	local tween = TS:Create(Handle, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	TS:Create(Handle, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {CFrame = lightsaber.CFrame}):Play()
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end

	for _, part in lightsaber:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end



module["Force Push"] = function(HRP, target)
	local Folder = VFX.Count.Second
	local speed = GameSpeed.Value
	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local ForcePushVFX = Folder.ForcePush:Clone()
	local emitters = {}

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local RightArm = HRP.Parent:FindFirstChild("Right Arm")
	if not RightArm then return end

	ForcePushVFX.CFrame = RightArm.CFrame
	ForcePushVFX.Anchored = true
	ForcePushVFX.Orientation += Vector3.new(0,-90,0)
	ForcePushVFX.Parent = workspace.VFX

	local travelSpeed = 12
	local timeToTravel = getMag(RightArm.Position, enemyPos) / travelSpeed
	tween(ForcePushVFX, timeToTravel, {Position = enemyPos})
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')

	task.delay(timeToTravel, function()
		if ForcePushVFX then
			ForcePushVFX:Destroy()
		end
	end)

	for i, particle in ForcePushVFX.Parent:GetDescendants() do
		if particle:IsA('ParticleEmitter') then
			table.insert(emitters, particle)
		end
	end

	warn(emitters)

	local displayed = false

	for _, emitter in emitters do
		emitter.Enabled = true
		task.delay(1 / speed, function() -- 0.15
			if not displayed then
				warn(emitters)
				displayed = true
			end

			if emitter then
				emitter.Enabled = false
			end
		end)
	end
	HRP.Parent.Attacking.Value = false
end



module["Force Lightning"] = function(HRP, target)
	local Folder = VFX.Count.Third
	local speed = GameSpeed.Value
	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local LightningVFX = Folder.ForceLightning:Clone()
	local emitters = {}

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local RightArm = HRP.Parent:FindFirstChild("Right Arm")
	if not RightArm then return end

	LightningVFX.CFrame = RightArm.CFrame
	LightningVFX.Anchored = true
	LightningVFX.Orientation += Vector3.new(0,-90,0)
	LightningVFX.Parent = workspace.VFX

	local travelSpeed = 12
	local timeToTravel = getMag(RightArm.Position, enemyPos) / travelSpeed
	tween(LightningVFX, timeToTravel, {Position = enemyPos})
	UnitSoundEffectLib.playSound(HRP.Parent, 'Thunder')

	task.delay(timeToTravel, function()
		if LightningVFX then
			LightningVFX:Destroy()
		end
	end)

	for i, particle in LightningVFX.Parent:GetDescendants() do
		if particle:IsA('ParticleEmitter') then
			table.insert(emitters, particle)
		end
	end

	warn(emitters)

	local displayed = false

	for _, emitter in emitters do
		emitter.Enabled = true
		task.delay(1 / speed, function() -- 0.15
			if not displayed then
				warn(emitters)
				displayed = true
			end

			if emitter then
				emitter.Enabled = false
			end
		end)
	end
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

local function emit(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime")
	local emitCount = particle:GetAttribute("EmitCount") or particle.Rate

	if delayTime and delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

module["Assault Rifle"] = function(HRP: BasePart, target: Model)
	local Folder = VFX["Crosshair"].First
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local assaultRifle = Folder["Assult Rifle"]:Clone()
	assaultRifle.CFrame = HRP.CFrame * CFrame.new(0,0,-.5)
	assaultRifle.Parent = vfxFolder

	UnitSoundEffectLib.playSound(HRP.Parent, 'Sniper' .. tostring(math.random(1,3)))

	for _, particle in assaultRifle:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		emit(particle)
	end

	Debris:AddItem(assaultRifle, 2)

	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end

module["Sniper"] = function(HRP: BasePart, target: Model)
	local Folder = VFX["Crosshair"].Second
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local sniper = Folder["Sniper Multiple Hit"]:Clone()
	sniper.CFrame = HRP.CFrame * CFrame.new(0,0,-.5)
	sniper.Parent = vfxFolder
	UnitSoundEffectLib.playSound(HRP.Parent, 'Sniper' .. tostring(math.random(1,3)))

	for _, particle in sniper:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		emit(particle)
	end

	Debris:AddItem(sniper, 2)

	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end

module["Sniper Boom"] = function(HRP: BasePart, target: Model)
	local Folder = VFX["Crosshair"].Third
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local sniper = Folder["Sniper Boom"]:Clone()
	sniper.CFrame = HRP.CFrame * CFrame.new(0,0,-.5)
	sniper.Parent = vfxFolder
	UnitSoundEffectLib.playSound(HRP.Parent, 'Sniper' .. tostring(math.random(1,3)))

	for _, particle in sniper:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		emit(particle)
	end

	Debris:AddItem(sniper, 2)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RunService = game:GetService("RunService")
local GameSpeed = workspace.Info.GameSpeed

module["Dart Mol Attack"] = function(HRP, target)
	local Folder = VFX["Dart Mol"].First
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value

	task.wait(0.78/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local handlePos = HRP.Parent["Right Arm"].FakeHandle
	local HRPCF = HRP.CFrame
	local startPosition = handlePos.Position 
	local targetPosition = HRPCF * CFrame.new(0, 0, -Range)

	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	VFX_Helper.Transparency(handlePos, 1)
	local emit = Folder:WaitForChild("Winnd"):Clone()
	emit.CFrame = HRP.CFrame * CFrame.new(0.5,0.8,-1.4)
	emit.Parent = vfxFolder
	Debris:AddItem(emit,3/speed)
	VFX_Helper.EmitAllParticles(emit)

	local Handle: BasePart = handlePos:Clone()
	Handle.Anchored = true
	Handle.Parent = vfxFolder
	Debris:AddItem(Handle, 2.5/speed)
	VFX_Helper.OffAllParticles(handlePos)
	Handle.HandleM.Trail.Enabled = true
	Handle.HandleM.Trail2.Enabled = true
	for _, part in handlePos:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
	VFX_Helper.OnAllParticles(Handle.HandleM.Part)
	VFX_Helper.OnAllParticles(Handle.HandleM.Part2)
	Handle.CFrame = HRPCF * CFrame.Angles(math.rad(90), 0, 0)
	local connection = HRP.Parent.Destroying:Once(function()
		Handle:Destroy()
	end)
	local fakeHandle = Handle:FindFirstChild("FakeHandleMotor")
	local function rotateChildren()
		for i = 1, 360, 10 do 
			if not HRP or not HRP.Parent then return end
			fakeHandle.Transform = CFrame.Angles(math.rad(i), math.rad(i), math.rad(i))
			task.wait(0.02/speed)
		end
		for i = 1, 360, 10 do 
			if not HRP or not HRP.Parent then return end
			fakeHandle.Transform = CFrame.Angles(math.rad(i), math.rad(i), math.rad(i))
			task.wait(0.02/speed)
		end
	end

	task.spawn(function()
		if not HRP or not HRP.Parent then return end
		rotateChildren()
	end)

	local tween = TS:Create(Handle, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	TS:Create(Handle, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {CFrame = handlePos.CFrame}):Play()
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(Handle.HandleM.Part)
	VFX_Helper.OffAllParticles(Handle.HandleM.Part2)

	Handle.HandleM.Trail.Enabled = false
	Handle.HandleM.Trail2.Enabled = false

	Handle.HandleM.Part.Transparency = 1
	Handle.HandleM.Part2.Transparency = 1

	handlePos.HandleM.Transparency = 0
	for _, part in handlePos:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end


module["Blades of Darkness"] = function(HRP, target)
	local Folder = VFX["Dart Mol"].Second
	local speed = GameSpeed.Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	task.wait(0.5/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local starsemit = Folder:WaitForChild("Startemit"):Clone()
	starsemit.Position = HRP.Position + Vector3.new(0,-1.2,0)
	starsemit.Parent = HRP.Parent
	Debris:AddItem(starsemit,2/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	TS:Create(HRP, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + enemyCFrame.LookVector}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(starsemit)
	local slash = Folder:WaitForChild("Slash"):Clone()
	slash.Position = enemypos 
	slash.Parent = vfxFolder
	Debris:AddItem(slash,4/speed)
	VFX_Helper.OnAllParticles(slash)

	local connection = HRP.Parent.Destroying:Once(function()
		slash:Destroy()
	end)
	if not HRP or not HRP.Parent then return end

	for i = 1, 10 do
		if not HRP or not HRP.Parent then return end
		local randomOffset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
		local randomPos = enemypos + randomOffset
		HRP.CFrame = CFrame.new(randomPos)
		task.wait(1.55 / 10/speed) 
	end
	HRP.CFrame = CFrame.new(enemypos)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(slash)
	task.wait(0.6/speed)
	if not HRP or not HRP.Parent then return end

	local ganblaster = Folder:WaitForChild("Endlemit"):Clone()
	ganblaster.Position = HRP.Position + Vector3.new(0,-0.95,0)
	ganblaster.Parent = vfxFolder
	Debris:AddItem(ganblaster,2/speed)
	VFX_Helper.EmitAllParticles(ganblaster)

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposr = Folder:WaitForChild("Teleportbls"):Clone()
	teleposr.CFrame = HRP.CFrame
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr,1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Ship Crash"] = function(HRP, target)
	local Folder = VFX["Dart Mol"].Thrid
	local speed = GameSpeed.Value

	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	VFX_Helper.SoundPlay(HRP,Folder.Third)
	task.wait(0.4/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local shipStartPos = HRP.Position - HRP.CFrame.LookVector * 20 + Vector3.new(0, 90, 0)
	local shipEndPos = enemypos + Vector3.new(0, -10, 0)
	local shipStartCFrame = CFrame.new(shipStartPos, shipEndPos) 
	local shipEndCFrame = CFrame.new(shipEndPos, shipEndPos + (shipEndPos - shipStartPos).unit * 20) 

	local Ship = Folder:WaitForChild("Look"):Clone()
	Ship.CFrame = shipStartCFrame 
	Ship.Parent = vfxFolder 
	Debris:AddItem(Ship, 2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Ship:Destroy()
	end)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	TS:Create(Ship, TweenInfo.new(1/speed, Enum.EasingStyle.Linear), {CFrame = shipEndCFrame}):Play()
	task.wait(0.85/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	if not HRP or not HRP.Parent then return end

	local explosion = Folder:WaitForChild("Explosion"):Clone()
	explosion.Position = enemypos + Vector3.new(0,0.35,0)
	explosion.Parent = vfxFolder
	Debris:AddItem(explosion,4/speed)	
	VFX_Helper.EmitAllParticles(explosion)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RunService = game:GetService("RunService")
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

module["Whirlwind of Darkness"] = function(HRP, target)
	local Folder = VFX["Dart Raiven"].Firsrt
	local speed = GameSpeed.Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	--VFX_Helper.SoundPlay(HRP,Folder.Second)
	local trailemit = Folder:WaitForChild("Trailemit"):Clone()
	trailemit.CFrame = HRP.CFrame
	trailemit.Parent = HRP
	Debris:AddItem(trailemit,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trailemit
	weld.Parent = trailemit

	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail
	local trail2 = Folder:WaitForChild("Trail2"):Clone()
	trail2.CFrame = HRP.Parent["Left Arm"].Handle2.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail2.Parent = vfxFolder
	Debris:AddItem(trail2,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Handle2
	weld.Part1 = trail2
	weld.Parent = trail2

	task.wait(0.45/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local starsemit = Folder:WaitForChild("Endlemit"):Clone()
	starsemit.Position = HRP.Position + Vector3.new(0,-1.2,0)
	starsemit.Parent = HRP.Parent
	Debris:AddItem(starsemit,2/speed)
	VFX_Helper.OnAllParticles(trailemit)
	task.wait(0.05/speed)
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	TS:Create(HRP, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + enemyCFrame.LookVector}):Play()
	task.wait(0.1/speed)
	VFX_Helper.OffAllParticles(trailemit)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(starsemit)
	local slash = Folder:WaitForChild("ExplosionSlash"):Clone()
	slash.Position = enemypos 
	slash.Parent = vfxFolder
	Debris:AddItem(slash,4/speed)
	VFX_Helper.OnAllParticles(slash)

	local connection = HRP.Parent.Destroying:Once(function()
		slash:Destroy()
	end)
	if not HRP or not HRP.Parent then return end

	for i = 1, 11 do
		if not HRP or not HRP.Parent then return end
		local randomOffset = Vector3.new(math.random(-6, 6), math.random(-1, 1), math.random(-6, 6))
		local randomPos = enemypos + randomOffset
		HRP.CFrame = CFrame.new(randomPos)
		task.wait(1.5 /10/speed) 
	end
	HRP.CFrame = CFrame.new(enemypos + Vector3.new(0,0,-2))
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(slash)
	task.wait(0.6/speed)
	if not HRP or not HRP.Parent then return end
	local ganblaster = Folder:WaitForChild("Teleportbls"):Clone()
	ganblaster.Position = HRP.Position + Vector3.new(0,-1,0)
	ganblaster.Parent = vfxFolder
	Debris:AddItem(ganblaster,2/speed)
	VFX_Helper.EmitAllParticles(ganblaster)


	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposr = Folder:WaitForChild("Teleportbls"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr,1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Double Slash"] = function(HRP, target)
	local Folder = VFX["Dart Raiven"].Second
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	--VFX_Helper.SoundPlay(HRP,Folder.Second)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail
	local trail2 = Folder:WaitForChild("Trail2"):Clone()
	trail2.CFrame = HRP.Parent["Left Arm"].Handle2.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail2.Parent = vfxFolder
	Debris:AddItem(trail2,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Handle2
	weld.Part1 = trail2
	weld.Parent = trail2
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	task.wait(0.8/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local slash = Folder:WaitForChild("Positions"):Clone()
	slash.CFrame = HRP.CFrame 
	slash.Parent = vfxFolder
	Debris:AddItem(slash,3/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		slash:Destroy()
	end)

	task.wait(0.1/speed)
	local decal = Folder:WaitForChild("Dacals"):Clone()
	decal.CFrame = HRP.CFrame 
	decal.Parent = vfxFolder
	Debris:AddItem(decal,3/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		decal:Destroy()
	end)
	if not HRP or not HRP.Parent then return end
	local targetPosition = ( HRP.CFrame * CFrame.new(0, -1, -Range))
	TS:Create(slash, TweenInfo.new(0.2/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(decal)
	task.wait(0.06/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OffAllParticles(slash)
	for _,v in (slash:GetDescendants()) do	
		if v:IsA("Beam") then
			TS:Create(
				v,
				TweenInfo.new(0.65/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Width0 = 0,Width1 = 0}
			):Play()
		end	
	end
	if not HRP or not HRP.Parent then return end
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing2')
	task.wait(1.2/speed)
	if not HRP or not HRP.Parent then return end
	for _,v in (decal:GetDescendants()) do	
		if v:IsA('Decal') then
			TS:Create(
				v,
				TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 1}
			):Play()
		end
	end
	connection:Disconnect()
	HRP.Parent.Attacking.Value = false

end

module["Doom Leap"] = function(HRP, target)
	local Folder = VFX["Dart Raiven"].thrid
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	--VFX_Helper.SoundPlay(HRP,Folder.Second)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail
	local trail2 = Folder:WaitForChild("Trail2"):Clone()
	trail2.CFrame = HRP.Parent["Left Arm"].Handle2.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail2.Parent = vfxFolder
	Debris:AddItem(trail2,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Handle2
	weld.Part1 = trail2
	weld.Parent = trail2
	task.wait(0.45/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	local startemit = Folder:WaitForChild("Endlemit"):Clone()
	startemit.Position = HRP.Position
	startemit.Parent = vfxFolder
	Debris:AddItem(startemit,2/speed)
	VFX_Helper.EmitAllParticles(startemit)

	local End = CFrame.new(enemypos + Vector3.new(0,2,0))
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0) )
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0))

	task.spawn(function()
		task.wait(0.5/speed)

		local Emit = Folder:WaitForChild("main"):Clone()
		Emit.Position = enemypos + Vector3.new(0,-0.5,0)
		Emit.Parent = vfxFolder
		Debris:AddItem(Emit,2/speed)
		VFX_Helper.EmitAllParticles(Emit)

	end)

	for i = 1, 100, 5  do
		local t = i/100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.new(NewPos)
		task.wait(0.014/speed)
	end
	TS:Create(HRP, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(enemypos) }):Play()
	task.wait(1.2/speed)
	local teleposrSE = Folder:WaitForChild("Teleportbls"):Clone()
	teleposrSE.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposrSE.Parent = vfxFolder	
	Debris:AddItem(teleposrSE,1/speed)
	VFX_Helper.EmitAllParticles(teleposrSE)

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposr = Folder:WaitForChild("Teleportbls"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr,1/speed)
	VFX_Helper.EmitAllParticles(teleposr)

	HRP.Parent.Attacking.Value = false

end





return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local tweenService = game:GetService("TweenService")
local StoryModeStats = require(rs.StoryModeStats)


local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0
	return weld
end



module["Rock Throw"] = function(HRP, target)
	warn("Firing")
	local speed = GameSpeed.Value
	local Folder = VFX["Fifth Brother"].First
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)


	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local rocks = {}

	local lookDirection = -HRP.CFrame.LookVector 
	local rightVector = HRP.CFrame.RightVector 

	for i, rockName in ({"Rock1", "Rock2", "Rock3"}) do
		local rock = Folder:WaitForChild(rockName):Clone()

		local offsetX = (i - 2) * 5 
		local spawnPosition = HRP.Position + lookDirection * 7 + rightVector * offsetX + Vector3.new(0, -5, 0)

		rock.CFrame = CFrame.new(spawnPosition)
		rock.Parent = vfxFolder
		table.insert(rocks, rock)
		Debris:AddItem(rock, 2 / speed)

	end

	for i, rock in (rocks) do
		task.spawn(function()
			local randomOffset = Vector3.new(math.random(-5, 5), -4, math.random(-5, 5))
			local readyRand = enemypos + randomOffset
			task.wait((i - 1) * 0.3 / speed) 
			if not HRP or not HRP.Parent then return end
			local connection = HRP.Parent.Destroying:Once(function()
				rock:Destroy()
			end)
			local startGroundEmit = Folder:WaitForChild("Startground"):Clone()
			startGroundEmit.Position = rock.Position + Vector3.new(0, 1.7, 0)
			startGroundEmit.Parent = vfxFolder
			Debris:AddItem(startGroundEmit, 2 / speed)
			VFX_Helper.EmitAllParticles(startGroundEmit)

			local upTime = math.random(10, 15) / 10 / speed

			local liftTween = TS:Create(rock, TweenInfo.new(upTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = rock.Position + Vector3.new(0, 17, 0)})
			local rotateTween = TS:Create(rock, TweenInfo.new(upTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Orientation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360))})

			liftTween:Play()
			rotateTween:Play()

			task.wait(upTime) 
			if not HRP or not HRP.Parent then return end

			local currentOrientation = rock.Orientation
			TS:Create(rock, TweenInfo.new(0.35 / speed, Enum.EasingStyle.Linear), {Orientation = Vector3.new(currentOrientation.X, currentOrientation.Y + 90, currentOrientation.Z)}):Play()

			task.wait(0.2/ speed)
			if not HRP or not HRP.Parent then return end


			TS:Create(rock, TweenInfo.new(0.15 / speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = readyRand}):Play()
			task.wait(0.15 / speed)
			if not HRP or not HRP.Parent then return end

			local ground = Folder:WaitForChild("Ground"):Clone()
			ground.Position = readyRand + Vector3.new(0, 3, 0)
			ground.Parent = vfxFolder
			UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
			Debris:AddItem(ground, 1 / speed)
			VFX_Helper.EmitAllParticles(ground)
			connection:Disconnect()

		end)
	end
	task.wait(1 /speed)
	HRP.Parent.Attacking.Value = false
end

module["Saber Dash"] = function(HRP: BasePart, target: Model)
	warn("Running Saber Dash")
	local speed = GameSpeed.Value
	local Folder = VFX["Fifth Brother"].Second
	local characterModel = HRP.Parent
	local Range = characterModel.Config:WaitForChild("Range").Value
	local enemyPos = target:GetPivot().Position

	local originalCFrame = characterModel:GetPivot()
	task.wait(0.3 / speed)
	if not HRP or not HRP.Parent then return end

	characterModel.Attacking.Value = true


	local SaberDash = Folder["Saber Dash"]:Clone()
	SaberDash.Parent = workspace.VFX
	SaberDash.CFrame = HRP.CFrame

	local distance = (HRP.Position - enemyPos).Magnitude
	local timeToTravel = distance / speed

	TS:Create(SaberDash, TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear), {Position = enemyPos}):Play()
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	task.delay(speed, function()
		if SaberDash and SaberDash.Parent then
			warn("Destroying")
			SaberDash:Destroy()
		end
	end)

	for _, v in pairs(SaberDash:GetChildren()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = true
		elseif v:IsA("Attachment") then
			for _, child in pairs(v:GetChildren()) do
				if child:IsA("ParticleEmitter") or child:IsA("Beam") then
					child.Enabled = true
				end
			end
		end
	end


	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()

	task.wait(1 / speed)
	if not HRP or not HRP.Parent then return end
	characterModel:PivotTo(originalCFrame)


	Debris:AddItem(SaberDash, 1 / speed)


	characterModel.Attacking.Value = false
end


module["Force Slam"] = function(HRP: BasePart, target: Model)
	warn("Running Force Dash")
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX["Fifth Brother"].Third
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(0.3/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		for _, folder in folders do
			for i, mob in rs.Enemies[folder]:GetChildren() do
				if mob.Name == MobName then
					Mob = mob:Clone()
				end
			end
		end
	end
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force')
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end

	local forceChoke = anikinFolder["Force Slam"]:Clone()
	forceChoke.Parent = workspace.VFX

	connect(forceChoke, Mob.HumanoidRootPart, CFrame.new(0,-1,0))

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end

	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = false
		end
	end

	Debris:AddItem(forceChoke, 2)

	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	VFX_Helper.EmitAllParticles(groundemit)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end

return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Hired Killer Attack"] = function(HRP, target)
	local Folder = VFX["Hired Killer"].First
	local speed = GameSpeed.Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.6/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	local Fire = Folder:WaitForChild("Fire"):Clone()
	Fire.CFrame = HRP.Parent["Left Arm"].Pos.CFrame
	Fire.Position = HRP.Parent["Left Arm"].Pos.Position 
	Fire.Parent = HRP
	Debris:AddItem(Fire,4/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Pos
	weld.Part1 = Fire
	weld.Parent = Fire

	VFX_Helper.OnAllParticles(Fire)
	task.wait(1.8/speed)
	VFX_Helper.OffAllParticles(Fire)
	HRP.Parent.Attacking.Value = false
end


module["Storm Barrage"] = function(HRP, target)
	local Folder = VFX["Hired Killer"].Thrid
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.6/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	for i = 1, 11 do
		if not HRP or not  HRP.Parent then return end

		local randomoffset = Vector3.new(math.random(-3.5,3.5),-1,math.random(-3.5,3.5))
		local readyrand = enemypos + randomoffset

		local rocket = Folder:WaitForChild("Rocket"):Clone()
		rocket.CFrame = HRP.Parent["Left Arm"].Pos.CFrame
		rocket.Position = HRP.Parent["Left Arm"].Pos.Position
		rocket.Parent = vfxFolder
		Debris:AddItem(rocket,2/speed)
		task.wait(0.012/speed)
		TS:Create(rocket,TweenInfo.new(0.2/speed,Enum.EasingStyle.Linear),{Position = readyrand}):Play()
		task.wait(0.1/speed)
		local Endlemit = Folder:WaitForChild("Explosion"):Clone()
		Endlemit.Position = readyrand + Vector3.new(0,-0.7,0)
		Endlemit.Parent = vfxFolder
		Debris:AddItem(Endlemit,2/speed)
		task.wait(0.02/speed)
		VFX_Helper.EmitAllParticles(Endlemit)
		VFX_Helper.OffAllParticles(rocket)
		rocket.Transparency = 1
	end

	HRP.Parent.Attacking.Value = false
end


module["Deadshot"] = function(HRP, target)
	local Folder = VFX["Hired Killer"].Second
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(1.15/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Handle.PosHandle.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Handle.PosHandle.Position 
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,2/speed)
	task.wait(0.05/speed)
	TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = enemypos}):Play()
	task.wait(0.1/speed)
	local emit = Folder:WaitForChild("EndlEmit"):Clone()
	emit.Position = enemypos + Vector3.new(0,-1,0)
	emit.Parent = vfxFolder
	Debris:AddItem(emit,3/speed)
	VFX_Helper.EmitAllParticles(emit)
	VFX_Helper.OffAllParticles(Ball)
	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end



return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RocksModule = require(rs.Modules.RocksModule)
local StoryModeStats = require(rs.StoryModeStats)
local GameSpeed = workspace.Info.GameSpeed

module["Kenobi first attack"] = function(HRP, target)
	local Folder = VFX.Kenobi.First
	local speed = GameSpeed.Value

	VFX_Helper.SoundPlay(HRP,Folder.First)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1.1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.3/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Sniper' .. tostring(math.random(1,3)))
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end

	RocksModule.Trail(HRP.CFrame,HRP.CFrame.LookVector,Range,3,Vector3.new(0.5,0.5,0.5),0.02,0.05,0.4,true,6,3)
	local targetPosition = ( HRP.CFrame * CFrame.new(0, 0, -Range))
	TS:Create(HRP, TweenInfo.new(0.4/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	local Start = Folder:WaitForChild("Downslam"):Clone()
	Start.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame + Vector3.new(0,0,-1)
	Start.Parent = HRP.Parent
	Debris:AddItem(Start,3/speed)
	VFX_Helper.EmitAllParticles(Start)

	task.wait(0.8/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end


module["Force Grip"] = function(HRP, target)
	local Folder = VFX.Kenobi.Second
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(1.1/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		for _, folder in folders do
			for i, mob in rs.Enemies[folder]:GetChildren() do
				if mob.Name == MobName then
					Mob = mob:Clone()
				end
			end
		end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end
	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


module["Stone Storm"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Kenobi.Thrid
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	local handle = HRP.Parent["Right Arm"].Handle
	handle.Transparency = 1
	VFX_Helper.OffAllParticles(handle.GlowPart)
	for _, part in handle:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
	task.wait(1.7 / speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local rocks = {}

	local lookDirection = -HRP.CFrame.LookVector 
	local rightVector = HRP.CFrame.RightVector 

	for i, rockName in ({"Rock1", "Rock2", "Rock3"}) do
		local rock = Folder:WaitForChild(rockName):Clone()

		local offsetX = (i - 2) * 5 
		local spawnPosition = HRP.Position + lookDirection * 7 + rightVector * offsetX + Vector3.new(0, -5, 0)

		rock.CFrame = CFrame.new(spawnPosition)
		rock.Parent = vfxFolder
		table.insert(rocks, rock)
		Debris:AddItem(rock, 5 / speed)

	end

	for i, rock in (rocks) do
		task.spawn(function()
			local randomOffset = Vector3.new(math.random(-5, 5), -4, math.random(-5, 5))
			local readyRand = enemypos + randomOffset
			task.wait((i - 1) * 0.3 / speed) 
			if not HRP or not HRP.Parent then return end
			local connection = HRP.Parent.Destroying:Once(function()
				rock:Destroy()
			end)
			local startGroundEmit = Folder:WaitForChild("Startground"):Clone()
			startGroundEmit.Position = rock.Position + Vector3.new(0, 1.7, 0)
			startGroundEmit.Parent = vfxFolder
			Debris:AddItem(startGroundEmit, 2 / speed)
			UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
			VFX_Helper.EmitAllParticles(startGroundEmit)

			local upTime = math.random(10, 15) / 10 / speed

			local liftTween = TS:Create(rock, TweenInfo.new(upTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = rock.Position + Vector3.new(0, 17, 0)})
			local rotateTween = TS:Create(rock, TweenInfo.new(upTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Orientation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360))})

			liftTween:Play()
			rotateTween:Play()

			task.wait(upTime) 
			if not HRP or not HRP.Parent then return end

			local currentOrientation = rock.Orientation
			TS:Create(rock, TweenInfo.new(0.35 / speed, Enum.EasingStyle.Linear), {Orientation = Vector3.new(currentOrientation.X, currentOrientation.Y + 90, currentOrientation.Z)}):Play()

			task.wait(0.2/ speed)
			if not HRP or not HRP.Parent then return end


			TS:Create(rock, TweenInfo.new(0.15 / speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = readyRand}):Play()
			task.wait(0.15 / speed)
			if not HRP or not HRP.Parent then return end

			local ground = Folder:WaitForChild("Ground"):Clone()
			ground.Position = readyRand + Vector3.new(0, 3, 0)
			ground.Parent = vfxFolder
			Debris:AddItem(ground, 3 / speed)
			VFX_Helper.EmitAllParticles(ground)
			connection:Disconnect()

		end)
	end
	task.wait(2.8/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(handle.GlowPart)
	handle.Transparency = 0
	for _, part in handle:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end
	HRP.Parent.Attacking.Value = false

end






return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RunService = game:GetService("RunService")
local GameSpeed = workspace.Info.GameSpeed
local RocksModule = require(rs.Modules.RocksModule)


module["Jedi Fist attack"] = function(HRP, target)
	local Folder = VFX.MIF["Kit Fishto"].First
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	--VFX_Helper.SoundPlay(HRP,Folder.Second)

	local handleR = HRP.Parent["Right Arm"].Handle.Trail
	handleR.Enabled = true

	task.wait(0.6/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local slash = Folder:WaitForChild("Mainpart"):Clone()
	slash.CFrame = HRP.CFrame 
	slash.Parent = vfxFolder
	Debris:AddItem(slash,3/speed)

	local connection = HRP.Parent.Destroying:Once(function()
		slash:Destroy()
	end)

	task.wait(0.01/speed)
	if not HRP or not HRP.Parent then return end

	local targetPosition = ( HRP.CFrame * CFrame.new(0, 0, -Range))
	TS:Create(slash, TweenInfo.new(0.22/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	RocksModule.Trail(HRP.CFrame,HRP.CFrame.LookVector,Range,4.4,Vector3.new(0.3,0.5,0.3),0.02,0.05,0.4,true,6,1.5)

	VFX_Helper.EmitAllParticles(slash.Slash)

	task.wait(0.01/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(slash)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Punch' .. tostring(math.random(1,3)))
	task.wait(0.19/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(slash)
	for _,v in (slash:GetDescendants()) do	
		if v:IsA("Beam") then
			TS:Create(
				v,
				TweenInfo.new(0.4/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Width0 = 0,Width1 = 0}
			):Play()
		end	
	end
	task.wait(1.2/speed)
	if not HRP or not HRP.Parent then return end

	connection:Disconnect()
	HRP.Parent.Attacking.Value = false
	handleR.Enabled = false
end


module["Force Surge"] = function(HRP, target)
	local Folder = VFX.MIF["Kit Fishto"].second
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local handleR = HRP.Parent["Right Arm"].Handle.Trail
	handleR.Enabled = true
	task.wait(0.78/speed)
	if not HRP or not HRP.Parent then return end
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	HRP.Parent.Attacking.Value = true

	local lych = Folder:WaitForChild("lych"):Clone()
	lych.Start.CFrame = HRP.Parent["Left Arm"].pos.CFrame
	lych.End.CFrame = HRP.Parent["Left Arm"].pos.CFrame
	lych.Parent = vfxFolder
	Debris:AddItem(lych, 4/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		lych:Destroy()
	end)
	local targetPosition = ( HRP.CFrame * CFrame.new(0, -1, -Range))
	TS:Create(lych.End, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetPosition}):Play()
	VFX_Helper.OnAllParticles(lych.Start)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(lych.End)

	task.wait(0.9/speed)
	if not HRP or not HRP.Parent then return end
	for _,v in (lych:GetDescendants()) do	
		if v:IsA("Beam") then
			TS:Create(
				v,
				TweenInfo.new(0.5/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Width0 = 0,Width1 = 0}
			):Play()
		end	
	end
	VFX_Helper.OffAllParticles(lych.End)
	VFX_Helper.OffAllParticles(lych.Start)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	handleR.Enabled = false
	connection:Disconnect()

end

module["Blade Rush"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.MIF["Kit Fishto"].Thrid
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	local handleR = HRP.Parent["Right Arm"].Handle.Trail
	handleR.Enabled = true



	task.wait(0.75/speed)
	if not HRP or not HRP.Parent then return end

	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,3/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local Emit = Folder:WaitForChild("Slash"):Clone()
	Emit.Parent = vfxFolder
	Emit:PivotTo(HRP.CFrame)
	Debris:AddItem(Emit, 4/speed)


	local connection = HRP.Parent.Destroying:Once(function()
		Emit:Destroy()
	end)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')

	VFX_Helper.EmitAllParticles(Emit.slas1)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	local targetCFrame = HRP.CFrame * CFrame.new(0, 0,-(Range - 1))
	TS:Create(HRP, TweenInfo.new(0.35/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	VFX_Helper.OnAllParticles(Emit.Slashes)
	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(Emit.Slashes)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing2')
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(Emit.slash2)

	task.wait(0.7/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(trail)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	VFX_Helper.EmitAllParticles(trail)

	handleR.Enabled = false
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = game.Workspace.Info.GameSpeed
local RocksModule = require(rs.Modules.RocksModule)

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end


module["Dual Laceration"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.MIF["Lyk Skaivoker"].First
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	local handleR = HRP.Parent["Right Arm"].Handle.Trail
	handleR.Enabled = true

	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local Emit = Folder:WaitForChild("Slashes"):Clone()
	Emit.CFrame = HRP.CFrame
	Emit.Parent = HRP
	Debris:AddItem(Emit,4/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = Emit
	weld.Parent = Emit

	local connection = HRP.Parent.Destroying:Once(function()
		Emit:Destroy()
	end)

	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	VFX_Helper.OnAllParticles(trail)
	task.wait(0.02/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(Emit.one)
	task.wait(0.07/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(Emit.twoo)

	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(trail)

	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	local teleposr = Folder:WaitForChild("teleport"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr, 1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposttt = Folder:WaitForChild("teleport"):Clone()
	teleposttt.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposttt.Parent = vfxFolder	
	Debris:AddItem(teleposttt, 1/speed)
	VFX_Helper.EmitAllParticles(teleposttt)
	handleR.Enabled = false
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end


module["Echo Strike"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.MIF["Lyk Skaivoker"].Firstgrenn
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	local handleR = HRP.Parent["Right Arm"].Handle.Trail
	handleR.Enabled = true

	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local Emit = Folder:WaitForChild("Slashes"):Clone()
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	Emit.CFrame = HRP.CFrame
	Emit.Parent = HRP
	Debris:AddItem(Emit,4/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = Emit
	weld.Parent = Emit

	local connection = HRP.Parent.Destroying:Once(function()
		Emit:Destroy()
	end)

	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	VFX_Helper.OnAllParticles(trail)
	task.wait(0.02/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(Emit.one)
	task.wait(0.07/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(Emit.twoo)

	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(trail)



	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	local teleposr = Folder:WaitForChild("teleport"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr, 1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposttt = Folder:WaitForChild("teleport"):Clone()
	teleposttt.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposttt.Parent = vfxFolder	
	Debris:AddItem(teleposttt, 1/speed)
	VFX_Helper.EmitAllParticles(teleposttt)
	handleR.Enabled = false
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end


module["Boulder Toss"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.MIF["Lyk Skaivoker"].Second
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local Debris = game:GetService("Debris")
	local TS = game:GetService("TweenService")

	local handleR = HRP.Parent["Right Arm"].Handle.Trail

	task.wait(0.1 / speed)
	if not HRP or not HRP.Parent then return end
	handleR.Enabled = true
	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local originalCFrame = HRP.CFrame
	local backOffset = HRP.CFrame.LookVector * -5
	local backCFrame = originalCFrame + backOffset

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,3/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail

	local startrock = Folder:WaitForChild("startemit"):Clone()
	startrock.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	startrock.Parent = vfxFolder	
	Debris:AddItem(startrock, 1/speed)

	local teleposttt = Folder:WaitForChild("teleport"):Clone()
	teleposttt.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposttt.Parent = vfxFolder	
	Debris:AddItem(teleposttt, 1/speed)
	TS:Create(HRP, TweenInfo.new(0.1 / speed, Enum.EasingStyle.Linear), {CFrame = backCFrame}):Play()
	UnitSoundEffectLib.playSound(HRP.Parent, 'Punch' .. tostring(math.random(1,3)))

	VFX_Helper.EmitAllParticles(teleposttt)
	task.wait(0.11 / speed)
	if not HRP or not HRP.Parent then return end
	local lookVector = originalCFrame.LookVector
	local rockStartPos = originalCFrame.Position - Vector3.new(0, 6, 0)

	local downCFrame = CFrame.new(rockStartPos, rockStartPos - Vector3.new(0, 1, 0))

	local rock = Folder:WaitForChild("Rock"):Clone()
	rock.CFrame = downCFrame
	rock.Parent = HRP
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	Debris:AddItem(rock, 1.9/speed) 


	local connection = HRP.Parent.Destroying:Once(function()
		rock:Destroy()
	end)

	local liftTargetPosition = rockStartPos + Vector3.new(0, 5.8, 0)
	local liftTargetCFrame = CFrame.new(liftTargetPosition, liftTargetPosition + lookVector)

	local liftTween = TS:Create(rock, TweenInfo.new(0.75 / speed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = liftTargetCFrame})
	liftTween:Play()
	VFX_Helper.EmitAllParticles(startrock)

	task.wait(0.75 / speed)
	if not HRP or not HRP.Parent then return end

	local handexplod = Folder:WaitForChild("Explosion 1"):Clone()
	handexplod.CFrame = HRP.CFrame * CFrame.new(0, 0, -1.6)
	handexplod.Parent = HRP
	Debris:AddItem(handexplod, 2 / speed)



	local flyDistance = Range + 500
	local flyTargetPos = liftTargetPosition + lookVector * flyDistance
	local flyTargetCFrame = CFrame.new(flyTargetPos, flyTargetPos + lookVector)

	local flyTween = TS:Create(rock, TweenInfo.new(1.4 / speed, Enum.EasingStyle.Linear), { CFrame = flyTargetCFrame})
	flyTween:Play()
	VFX_Helper.EmitAllParticles(handexplod)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	VFX_Helper.OnAllParticles(rock)
	RocksModule.Trail(HRP.CFrame,HRP.CFrame.LookVector *3 ,flyDistance,5.1,Vector3.new(0.6,0.6,0.6),0.02,0.05,0.4,true,12,3)

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end
	local telepost = Folder:WaitForChild("teleport"):Clone()
	telepost.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	telepost.Parent = vfxFolder	
	Debris:AddItem(telepost, 1/speed)
	VFX_Helper.EmitAllParticles(telepost)

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	handleR.Enabled = false
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Force Boulder"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.MIF["Lyk Skaivoker"].Secondgrenn
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local Debris = game:GetService("Debris")
	local TS = game:GetService("TweenService")

	local handleR = HRP.Parent["Right Arm"].Handle.Trail

	task.wait(0.1 / speed)
	if not HRP or not HRP.Parent then return end
	handleR.Enabled = true
	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local originalCFrame = HRP.CFrame
	local backOffset = HRP.CFrame.LookVector * -5
	local backCFrame = originalCFrame + backOffset

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,3/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail

	local startrock = Folder:WaitForChild("startemit"):Clone()
	startrock.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	startrock.Parent = vfxFolder	
	Debris:AddItem(startrock, 1/speed)

	local teleposttt = Folder:WaitForChild("teleport"):Clone()
	teleposttt.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposttt.Parent = vfxFolder	
	Debris:AddItem(teleposttt, 1/speed)
	TS:Create(HRP, TweenInfo.new(0.1 / speed, Enum.EasingStyle.Linear), {CFrame = backCFrame}):Play()

	VFX_Helper.EmitAllParticles(teleposttt)
	task.wait(0.11 / speed)
	if not HRP or not HRP.Parent then return end
	local lookVector = originalCFrame.LookVector
	local rockStartPos = originalCFrame.Position - Vector3.new(0, 6, 0)

	local downCFrame = CFrame.new(rockStartPos, rockStartPos - Vector3.new(0, 1, 0))

	local rock = Folder:WaitForChild("Rock"):Clone()
	rock.CFrame = downCFrame
	rock.Parent = HRP
	Debris:AddItem(rock, 1.9/speed) 


	local connection = HRP.Parent.Destroying:Once(function()
		UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
		rock:Destroy()
	end)

	local liftTargetPosition = rockStartPos + Vector3.new(0, 5.8, 0)
	local liftTargetCFrame = CFrame.new(liftTargetPosition, liftTargetPosition + lookVector)

	local liftTween = TS:Create(rock, TweenInfo.new(0.75 / speed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = liftTargetCFrame})
	liftTween:Play()
	VFX_Helper.EmitAllParticles(startrock)

	task.wait(0.75 / speed)
	if not HRP or not HRP.Parent then return end

	local handexplod = Folder:WaitForChild("Explosion 1"):Clone()
	handexplod.CFrame = HRP.CFrame * CFrame.new(0, 0, -1.6)
	handexplod.Parent = HRP
	Debris:AddItem(handexplod, 2 / speed)



	local flyDistance = Range + 500
	local flyTargetPos = liftTargetPosition + lookVector * flyDistance
	local flyTargetCFrame = CFrame.new(flyTargetPos, flyTargetPos + lookVector)

	local flyTween = TS:Create(rock, TweenInfo.new(1.4 / speed, Enum.EasingStyle.Linear), { CFrame = flyTargetCFrame})
	flyTween:Play()
	VFX_Helper.EmitAllParticles(handexplod)
	VFX_Helper.OnAllParticles(rock)
	RocksModule.Trail(HRP.CFrame,HRP.CFrame.LookVector *3 ,flyDistance,5.1,Vector3.new(0.6,0.6,0.6),0.02,0.05,0.4,true,12,3)

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end
	local telepost = Folder:WaitForChild("teleport"):Clone()
	telepost.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	telepost.Parent = vfxFolder	
	Debris:AddItem(telepost, 1/speed)
	VFX_Helper.EmitAllParticles(telepost)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	handleR.Enabled = false
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Lightsaber Barrage"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.MIF["Lyk Skaivoker"].thrid
	--VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"].Handle.Trail
	handleR.Enabled = true

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end

	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	--local starsemit = Folder:WaitForChild("teleport"):Clone()
	--starsemit.Position = HRP.Position
	--starsemit.Parent = HRP.Parent
	--VFX_Helper.EmitAllParticles(starsemit)
	--Debris:AddItem(starsemit,2/speed)

	local End = CFrame.new(enemypos + Vector3.new(0,0.25,0))
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,3,0) )
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,3,0))

	VFX_Helper.OnAllParticles(trail)
	for i = 1, 100, 5  do
		local t = i/100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.new(NewPos)
		task.wait(0.014/speed)
	end
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	local slash = Folder:WaitForChild("Slash"):Clone()
	slash.Position = HRP.Position + Vector3.new(0,-1.3,0)
	slash.Parent = HRP
	Debris:AddItem(slash,3/speed)
	VFX_Helper.OnAllParticles(slash)

	task.wait(0.2/speed)	

	local points = {}
	local center = HRP.Position

	for i = 1, 30 do
		local angle = math.rad((360 / 18) * i)
		local radius = 6
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local y = math.random(-0.8, 2)
		table.insert(points, center + Vector3.new(x, y, z))
	end

	for i = 1, #points do
		if not HRP or not HRP.Parent then return end
		HRP.CFrame = CFrame.new(points[i])
		task.wait(1.4 / #points / speed)
	end

	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(slash)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(trail)

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposrrr = Folder:WaitForChild("teleport"):Clone()
	teleposrrr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposrrr.Parent = vfxFolder	
	Debris:AddItem(teleposrrr,1/speed)
	VFX_Helper.EmitAllParticles(teleposrrr)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end
return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RunService = game:GetService("RunService")
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end



module["Sword Throw"] = function(HRP, target)
	local Folder = VFX.MIF["Mace Vindy"].thrid
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(1 / speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local handlePos = HRP.Parent["Right Arm"].Handle
	local handleR = handlePos.Trail
	local handleRR = handlePos.TrailL
	local handleRRR = handlePos.TrailLP
	handleR.Enabled = true
	handleRR.Enabled = true
	handleRRR.Enabled = true

	local handleModel = Instance.new("Model")
	handleModel.Name = "SwordClone"
	handleModel.Parent = vfxFolder

	local Handle = handlePos:Clone()
	Handle.Anchored = true
	Handle.CanCollide = false
	Handle.Parent = handleModel

	for _, obj in handlePos.Parent:GetChildren() do
		if obj:IsA("BasePart") and obj ~= handlePos then
			if obj:FindFirstChildWhichIsA("WeldConstraint") or obj:FindFirstChildWhichIsA("Weld") then
				local partClone = obj:Clone()
				partClone.Anchored = true
				partClone.CanCollide = false
				partClone.Parent = handleModel
			end
		end
	end

	handleModel.PrimaryPart = Handle

	handlePos.Transparency = 1
	for _, part in handlePos:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end

	handleR.Enabled = false
	handleRR.Enabled = false
	handleRRR.Enabled = false

	local startPos = HRP.Position
	local lookCFrame = CFrame.new(startPos, enemypos)
	handleModel:SetPrimaryPartCFrame(lookCFrame * CFrame.Angles(0, math.rad(180), 0))

	Debris:AddItem(handleModel, 1.65 / speed)

	local connection = HRP.Parent.Destroying:Once(function()
		handleModel:Destroy()
	end)

	local distance = (enemypos - startPos).Magnitude
	local flyTime = 0.25 / speed
	local endPos = lookCFrame.Position + lookCFrame.LookVector * distance
	local endCFrame = CFrame.new(endPos, endPos + lookCFrame.LookVector) * CFrame.Angles(math.rad(-20), math.rad(180), 0)

	TS:Create(handleModel.PrimaryPart, TweenInfo.new(flyTime, Enum.EasingStyle.Linear), {
		CFrame = endCFrame + Vector3.new(0, -0.5, 0)
	}):Play()
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	local explosions = Folder:WaitForChild("Explosions"):Clone()
	explosions.Position = enemypos 
	explosions.Parent = HRP
	Debris:AddItem(explosions,3/speed)
	task.wait(0.25 / speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(explosions)
	task.wait(1.1 / speed)
	if not HRP or not HRP.Parent then return end
	TS:Create(handleModel.PrimaryPart, TweenInfo.new(0.3 / speed, Enum.EasingStyle.Linear), {
		CFrame = handlePos.CFrame
	}):Play()
	task.wait(0.3 / speed)

	handlePos.Transparency = 0
	for _, part in handlePos:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end


module["Blade Descent"] = function(HRP, target)
	local Folder = VFX.MIF["Mace Vindy"].First
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	--VFX_Helper.SoundPlay(HRP,Folder.Second)
	local handleR = HRP.Parent["Right Arm"].Handle.Trail
	handleR.Enabled = true

	task.wait(0.45/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local startemit = Folder:WaitForChild("Starteffect"):Clone()
	startemit.CFrame = HRP.CFrame + Vector3.new(0,-0.6,0)
	startemit.Parent = vfxFolder
	Debris:AddItem(startemit,2/speed)


	local End = CFrame.new(enemypos + Vector3.new(0,2,0))
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,3,0) )
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,3,0))

	local slash = Folder:WaitForChild("Slash"):Clone()
	slash.CFrame = HRP.CFrame
	slash.Parent = HRP
	Debris:AddItem(slash,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = slash
	weld.Parent = slash

	local trail = Folder:WaitForChild("taril"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail

	VFX_Helper.EmitAllParticles(startemit)

	for i = 1, 100, 4  do
		local t = i/100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.new(NewPos, NewPos + Start.LookVector)
		task.wait(0.007/speed)
		if not HRP or not HRP.Parent then return end
	end

	VFX_Helper.EmitAllParticles(slash)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))	

	local descentDirection = (End.Position - Start.Position).Unit
	local shiftedPosition = enemypos + descentDirection * 2 + Vector3.new(0, -1, 0)

	local endlemit = Folder:WaitForChild("Slam"):Clone()
	endlemit.Position = shiftedPosition 
	endlemit.Parent = vfxFolder
	Debris:AddItem(endlemit,3/speed)

	TS:Create(HRP, TweenInfo.new(0.07/speed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(enemypos, enemypos + Start.LookVector) }):Play()
	VFX_Helper.EmitAllParticles(endlemit)
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	local teleposrSE = Folder:WaitForChild("teleport"):Clone()
	teleposrSE.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposrSE.Parent = vfxFolder	
	Debris:AddItem(teleposrSE,1/speed)
	VFX_Helper.EmitAllParticles(teleposrSE)

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposr = Folder:WaitForChild("teleport"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr,1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	handleR.Enabled = false
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false

end


module["Stone Uplift"] = function(HRP, target)
	local Folder = VFX.MIF["Mace Vindy"].second
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local handleR = HRP.Parent["Right Arm"].Handle.Trail
	handleR.Enabled = true

	task.wait(0.95 / speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local rock = Folder:WaitForChild("Main"):Clone()
	rock.CFrame = CFrame.new(enemypos + Vector3.new(0, -9, 0)) 
	rock.Parent = vfxFolder
	Debris:AddItem(rock, 3/speed)

	local connection = HRP.Parent.Destroying:Once(function()
		rock:Destroy()
	end)
	local rockemit = Folder:WaitForChild("Ground"):Clone()
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	rockemit.Position = enemypos + Vector3.new(0,-1,0)
	rockemit.Parent = vfxFolder
	Debris:AddItem(rockemit, 5/speed)
	VFX_Helper.EmitAllParticles(rockemit)

	TS:Create(rock, TweenInfo.new(0.15/speed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		CFrame = rock.CFrame + Vector3.new(0, 10, 0)
	}):Play()


	handleR.Enabled = false
	task.wait(1.5/ speed)
	if not HRP or not HRP.Parent then return end


	TS:Create(rock, TweenInfo.new(0.3/speed, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		CFrame = rock.CFrame + Vector3.new(0, -11, 0)
	}):Play()

	local rockemitTwo = Folder:WaitForChild("Groundend"):Clone()
	rockemitTwo.Position = enemypos + Vector3.new(0,-1,0)
	rockemitTwo.Parent = vfxFolder
	Debris:AddItem(rockemitTwo, 2/speed)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(rockemitTwo)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end



return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RocksModule = require(rs.Modules.RocksModule)
local StoryModeStats = require(rs.StoryModeStats)
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0
	return weld
end

local function emit(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 10

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

module["Rebound Bullets"] = function(HRP: BasePart, target: Model)
	warn("Rebound initiated")
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
end

module["Force Slam"] = function(HRP: BasePart, target: Model)
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX.Anakin.Third
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(1.1/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		for _, folder in folders do
			for i, mob in rs.Enemies[folder]:GetChildren() do
				if mob.Name == MobName then
					Mob = mob:Clone()
				end
			end
		end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end

	local forceChoke = anikinFolder["Force Choke"]:Clone()
	forceChoke.Parent = workspace.VFX

	connect(forceChoke, Mob.HumanoidRootPart, CFrame.new(0,-1,0))

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end

	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = false
		end
	end

	Debris:AddItem(forceChoke, 2)

	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Sniper Boom"] = function(HRP: BasePart, target: Model)
	local Folder = VFX["Crosshair"].Third
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	UnitSoundEffectLib.playSound(HRP.Parent, 'Sniper' .. tostring(math.random91,3))

	local sniper = Folder["Sniper Boom"]:Clone()
	sniper.CFrame = HRP.CFrame * CFrame.new(0,0,-.5)
	sniper.Parent = vfxFolder

	for _, particle in sniper:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		emit(particle)
	end

	Debris:AddItem(sniper, 2)

	task.wait(.2 / speed)

	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end

module["Force Reckoning"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Ploo.Folder
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local lig1 = Folder:WaitForChild("Light"):Clone()
	lig1.CFrame = HRP.Parent["Right Arm"].Pos22.CFrame
	lig1.Parent = vfxFolder
	Debris:AddItem(lig1,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Pos22
	weld.Part1 = lig1
	weld.Parent = lig1
	local light = Folder:WaitForChild("Light"):Clone()
	light.CFrame = HRP.Parent["Left Arm"].Pos.CFrame
	light.Parent = vfxFolder
	Debris:AddItem(light,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Pos
	weld.Part1 = light
	weld.Parent = light

	VFX_Helper.OnAllParticles(lig1)
	VFX_Helper.OnAllParticles(light)

	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')

	task.wait(0.6/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRP.CFrame * CFrame.new(0, 0, -Range)).Position

	local starsemit = Folder:WaitForChild("Electrigemit"):Clone()
	starsemit.CFrame = HRP.CFrame 
	starsemit.Parent = HRP.Parent
	VFX_Helper.OnAllParticles(starsemit)
	Debris:AddItem(starsemit,3/speed)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	TS:Create(starsemit,TweenInfo.new(0.25/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	VFX_Helper.OffAllParticles(lig1)
	VFX_Helper.OffAllParticles(light)
	task.wait(0.22/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OffAllParticles(starsemit)


	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length), details):Play()
end
local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

module["Saber Throw"] = function(HRP, target)
	local Folder = VFX["Quinion Vas"].First
	local VasFolder = VFX["Quinion Vas"]
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value

	print(Range)

	task.wait(0.78/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	local lightsaber = HRP.Parent["Right Arm"]:WaitForChild("Ground1")
	local HRPCF = HRP.CFrame
	local startPosition = lightsaber.Position 
	local targetPosition = HRPCF * CFrame.new(0, 0, -Range)

	VFX_Helper.Transparency(lightsaber, 1)

	local Handle: BasePart = VasFolder.First.Saber:Clone()
	Handle.Anchored = true
	Handle.Parent = vfxFolder
	local emit = Folder:WaitForChild("Sabre Throw"):Clone()
	emit.Anchored = false
	local weld = Instance.new("Motor6D", emit)
	weld.Part0 = emit
	weld.Part1 = Handle
	emit.CFrame = Handle.CFrame

	emit.Parent = Handle
	Debris:AddItem(emit,2/speed)
	VFX_Helper.EmitAllParticles(emit)



	Debris:AddItem(Handle, 2/speed)

	VFX_Helper.OffAllParticles(lightsaber)
	for _, part in lightsaber:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end

	Handle.CFrame = HRPCF * CFrame.Angles(math.rad(90), 0, 0)
	local connection = HRP.Parent.Destroying:Once(function()
		Handle:Destroy()
	end)

	local tween = TS:Create(Handle, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	TS:Create(Handle, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {CFrame = lightsaber.CFrame}):Play()
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end

	for _, part in lightsaber:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end



module["Force Push"] = function(HRP, target)
	local Folder = VFX["Quinion Vas"].Second
	local speed = GameSpeed.Value
	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local ForcePushVFX = Folder.ForcePush:Clone()
	local emitters = {}

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local RightArm = HRP.Parent:FindFirstChild("Right Arm")
	if not RightArm then return end

	ForcePushVFX.CFrame = RightArm.CFrame
	ForcePushVFX.Anchored = true
	ForcePushVFX.Orientation += Vector3.new(0,-90,0)
	ForcePushVFX.Parent = workspace.VFX

	local travelSpeed = 12
	local timeToTravel = getMag(RightArm.Position, enemyPos) / travelSpeed
	tween(ForcePushVFX, timeToTravel, {Position = enemyPos})
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')

	task.delay(timeToTravel, function()
		if ForcePushVFX then
			ForcePushVFX:Destroy()
		end
	end)

	for i, particle in ForcePushVFX.Parent:GetDescendants() do
		if particle:IsA('ParticleEmitter') then
			table.insert(emitters, particle)
		end
	end

	warn(emitters)

	local displayed = false

	for _, emitter in emitters do
		emitter.Enabled = true
		task.delay(1 / speed, function() -- 0.15
			if not displayed then
				warn(emitters)
				displayed = true
			end

			if emitter then
				emitter.Enabled = false
			end
		end)
	end
	HRP.Parent.Attacking.Value = false
end

module["Saber Slash"] = function(HRP, target)
	local Folder = VFX["Quinion Vas"].Third
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local saber = Folder["Saber Slash"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	tween(saber, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)


	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end


module["Rocket Shot"] = function(HRP, target)
	local Folder = VFX["Sith Trooper"].First
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(0.7 / speed)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Rockets1')

	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	task.wait(0.1 / speed)
	if not HRP or not HRP.Parent then return end

	local heandemit = HRP.Parent["Right Arm"].Gun.emit

	local rocket = Folder:WaitForChild("Rocket"):Clone()
	local startPos = HRP.Parent["Right Arm"].Gun.Pos.Position
	local lookAtPos = enemypos + Vector3.new(0, -1, 0)
	rocket.CFrame = CFrame.lookAt(startPos, lookAtPos)
	rocket.Parent = vfxFolder
	Debris:AddItem(rocket, 2 / speed)
	local connection = HRP.Parent.Destroying:Once(function()
		rocket:Destroy()
	end)
	task.wait(0.01 / speed)
	if not HRP or not HRP.Parent then return end

	TS:Create(rocket, TweenInfo.new(0.2 / speed, Enum.EasingStyle.Linear), {Position = lookAtPos}):Play()
	task.wait(0.04 / speed)
	if not HRP or not HRP.Parent then return end

	--VFX_Helper.OnAllParticles(rocket.FistProjecile)
	VFX_Helper.EmitAllParticles(heandemit)
	task.wait(0.05 / speed)
	if not HRP or not HRP.Parent then return end

	local Endlemit = Folder:WaitForChild("Explosion"):Clone()
	Endlemit.Position = enemypos
	Endlemit.Parent = vfxFolder
	Debris:AddItem(Endlemit, 2 / speed)
	task.wait(0.02 / speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.EmitAllParticles(Endlemit)
	VFX_Helper.OffAllParticles(rocket)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	rocket.Transparency = 1

	task.wait(1)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Alpha Strike"] = function(HRP, target)
	local Folder = VFX["Sith Trooper"].Second
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	HRP.Parent.Attacking.Value = true
	task.wait(0.15/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	if not HRP or not HRP.Parent then return end
	local connection = nil
	for i = 1, 8 do
		if not HRP or not  HRP.Parent then return end
		local randomoffset = Vector3.new(math.random(-5.5,5.5),-1,math.random(-5.5,5.5))
		local readyrand = enemypos + randomoffset
		local Ball = Folder:WaitForChild("Part"):Clone()
		Ball.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
		Ball.Position = HRP.Parent["Right Arm"].Gun.Pos.Position 
		Ball.Parent = vfxFolder
		Debris:AddItem(Ball,2/speed)
		connection = HRP.Parent.Destroying:Once(function()
			Ball:Destroy()
		end)
		task.wait(0.01/speed)
		TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = readyrand}):Play()
		VFX_Helper.EmitAllParticles(HRP.Parent["Right Arm"].Gun.Pos.Winnd)
		task.wait(0.1/speed)
		if not HRP or not HRP.Parent then return end
		local Endlemit = Folder:WaitForChild("Explosion"):Clone()
		Endlemit.Position = readyrand + Vector3.new(0,0.23,0)
		Endlemit.Parent = vfxFolder
		Debris:AddItem(Endlemit,2/speed)
		VFX_Helper.EmitAllParticles(Endlemit)
		UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster' .. tostring(math.random(1,3)))
		VFX_Helper.OffAllParticles(Ball)
		Ball.Transparency = 1
	end

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


module["High Energy Shot"] = function(HRP, target)
	local Folder = VFX["Sith Trooper"].Thrid
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.75/speed)
	if not HRP or not HRP.Parent then return end
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	HRP.Parent.Attacking.Value = true

	local zalpNNP = Folder:WaitForChild("Startemit"):Clone()
	zalpNNP.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	zalpNNP.Parent = HRP.Parent
	Debris:AddItem(zalpNNP,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Gun.Pos
	weld.Part1 = zalpNNP
	weld.Parent = zalpNNP
	VFX_Helper.OnAllParticles(zalpNNP)
	VFX_Helper.ScaleParticles(zalpNNP,2)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end


	local lych = Folder:WaitForChild("Lych"):Clone()
	lych.chargegalickgun.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	lych.End.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	lych.Parent = vfxFolder
	Debris:AddItem(lych, 4/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		lych:Destroy()
	end)
	local targetPosition = CFrame.new(enemypos + Vector3.new(0, -1, 0)) 
	TS:Create(lych.End, TweenInfo.new(0.25/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetPosition}):Play()
	VFX_Helper.OffAllParticles(zalpNNP)
	VFX_Helper.OnAllParticles(lych.chargegalickgun)
	task.wait(0.22/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(lych.End)
	VFX_Helper.ScaleParticles(lych.End,2.2)
	UnitSoundEffectLib.playSound(HRP.Parent, 'EliteBlaster1')

	task.wait(0.18/speed)
	if not HRP or not HRP.Parent then return end
	for _, v in (lych:GetChildren()) do
		if v:IsA("Beam") then 
			v.Enabled = true
		end
	end

	task.wait(0.9/speed)
	if not HRP or not HRP.Parent then return end

	for _,v in (lych:GetDescendants()) do	
		if v:IsA("Beam") then
			TS:Create(
				v,
				TweenInfo.new(0.5/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Width0 = 0,Width1 = 0}
			):Play()
		end	
	end
	VFX_Helper.OffAllParticles(lych.End)
	VFX_Helper.OffAllParticles(lych.chargegalickgun)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end




return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local RocksModule = require(rs.Modules.RocksModule)


module["Perish"] = function(HRP, target)
	local Folder = VFX["Sixth Brother"].First
	local speed = GameSpeed.Value
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Teleport = Folder:WaitForChild("Startemit"):Clone()
	Teleport.Position = HRP.Parent:WaitForChild("TowerBasePart").Position + Vector3.new(0,-0.5,0)
	Teleport.Parent = HRP.Parent
	Debris:AddItem(Teleport,2/speed)

	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].O.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].O
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.08/speed)
	HRP.Parent.Attacking.Value = true

	if not HRP or not HRP.Parent then return end
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	TS:Create(HRP, TweenInfo.new(0.05/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + enemyCFrame.LookVector * -0.5}):Play()
	VFX_Helper.EmitAllParticles(Teleport)
	task.wait(0.05/speed)
	local Hit = Folder:WaitForChild("Emit"):Clone()
	Hit.Position = enemypos + Vector3.new(0,-1,0)
	Hit.Parent = vfxFolder
	Debris:AddItem(Hit,3/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	task.spawn(function()
		task.wait(0.05/speed)
		VFX_Helper.EmitAllParticles(Hit)
	end)
	if not HRP or not HRP.Parent then return end
	task.wait(0.6/speed)
	TS:Create(Hit.PointLight, TweenInfo.new(0.7/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = 0}):Play()
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end


module["Stone Throw"] = function(HRP, target)
	local Folder = VFX["Sixth Brother"].Second
	local speed = GameSpeed.Value

	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	VFX_Helper.SoundPlay(HRP,Folder.Seconddd)
	task.wait(0.12/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local rockemit = Folder:WaitForChild("Rockemit"):Clone()
	rockemit.CFrame = startCFrame * CFrame.new(0, -0.7, -2)  * CFrame.Angles(math.rad(90),0,0)
	rockemit.Parent = vfxFolder
	Debris:AddItem(rockemit, 2/speed)

	local rock = Folder:WaitForChild("Rock"):Clone()
	rock.CFrame = startCFrame * CFrame.new(0, -5, -2) 
	rock.Parent = vfxFolder
	Debris:AddItem(rock, 1.5/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		rock:Destroy()
	end)
	local rockUpCFrame = rock.CFrame * CFrame.new(0, 10, 0)
	local tweenUp = TS:Create(rock, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = rockUpCFrame})
	VFX_Helper.EmitAllParticles(rockemit)
	tweenUp:Play()
	task.wait(1.2/speed)
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	local tweenToEnemy = TS:Create(rock, TweenInfo.new(0.18/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + Vector3.new(0,-1,0)})
	tweenToEnemy:Play()
	local groundemit =Folder:WaitForChild("GroundVfx"):Clone()
	groundemit.CFrame = enemyCFrame + Vector3.new(0,-1,0)
	groundemit.Parent = vfxFolder
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	Debris:AddItem(groundemit,3/speed)
	task.wait(0.18/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	connection:Disconnect()

end

module["Force Palm"] = function(HRP, target)
	local Folder = VFX["Sixth Brother"].Thrid
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].O.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1.4/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].O
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	local Fire = Folder:WaitForChild("YodaEmit"):Clone()
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	Fire.CFrame = HRP.CFrame
	Fire.Position = HRP.Parent["Left Arm"].Position 
	Fire.Parent = HRP
	Debris:AddItem(Fire,4/speed)
	VFX_Helper.EmitAllParticles(Fire)
	RocksModule.Trail(HRP.CFrame,HRP.CFrame.LookVector,Range - 2.5,3,Vector3.new(0.5,0.5,0.5),0.02,0.05,0.4,true,6,3)
	task.wait(1/speed)
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local RocksModule = require(rs.Modules.RocksModule)

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length), details):Play()
end
local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

module["Saber Throw"] = function(HRP, target)
	local Folder = VFX["Dart Mol"].First
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value

	task.wait(0.78/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local handlePos = HRP.Parent["Right Arm"].Handle
	local HRPCF = HRP.CFrame
	local startPosition = handlePos.Position 
	local targetPosition = HRPCF * CFrame.new(0, 0, -Range)

	VFX_Helper.Transparency(handlePos, 1)
	local emit = Folder:WaitForChild("Winnd"):Clone()
	emit.CFrame = HRP.CFrame * CFrame.new(0.5,0.8,-1.4)
	emit.Parent = vfxFolder
	Debris:AddItem(emit,3/speed)
	VFX_Helper.EmitAllParticles(emit)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	local Handle: BasePart = handlePos:Clone()
	Handle.Anchored = true
	Handle.Parent = vfxFolder
	Debris:AddItem(Handle, 2.5/speed)
	VFX_Helper.OffAllParticles(handlePos)
	Handle.HandleM.Trail.Enabled = true
	Handle.HandleM.Trail2.Enabled = true
	for _, part in handlePos:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
	VFX_Helper.OnAllParticles(Handle.HandleM.Part)
	VFX_Helper.OnAllParticles(Handle.HandleM.Part2)
	Handle.CFrame = HRPCF * CFrame.Angles(math.rad(90), 0, 0)
	local connection = HRP.Parent.Destroying:Once(function()
		Handle:Destroy()
	end)
	local fakeHandle = Handle:FindFirstChild("FakeHandleMotor")
	local function rotateChildren()
		for i = 1, 360, 10 do 
			if not HRP or not HRP.Parent then return end
			fakeHandle.Transform = CFrame.Angles(math.rad(i), math.rad(i), math.rad(i))
			task.wait(0.02/speed)
		end
		for i = 1, 360, 10 do 
			if not HRP or not HRP.Parent then return end
			fakeHandle.Transform = CFrame.Angles(math.rad(i), math.rad(i), math.rad(i))
			task.wait(0.02/speed)
		end
	end

	task.spawn(function()
		if not HRP or not HRP.Parent then return end
		rotateChildren()
	end)

	local tween = TS:Create(Handle, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	TS:Create(Handle, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {CFrame = handlePos.CFrame}):Play()
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(Handle.HandleM.Part)
	VFX_Helper.OffAllParticles(Handle.HandleM.Part2)

	Handle.HandleM.Trail.Enabled = false
	Handle.HandleM.Trail2.Enabled = false

	Handle.HandleM.Part.Transparency = 1
	Handle.HandleM.Part2.Transparency = 1

	handlePos.HandleM.Transparency = 0
	for _, part in handlePos:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end

module["Boulder Toss"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Tenth Brother"].Second
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local Debris = game:GetService("Debris")
	local TS = game:GetService("TweenService")


	task.wait(0.1 / speed)
	if not HRP or not HRP.Parent then return end
	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local originalCFrame = HRP.CFrame
	local backOffset = HRP.CFrame.LookVector * -5
	local backCFrame = originalCFrame + backOffset

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,3/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail

	local startrock = Folder:WaitForChild("startemit"):Clone()
	startrock.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	startrock.Parent = vfxFolder	
	Debris:AddItem(startrock, 1/speed)

	local teleposttt = Folder:WaitForChild("teleport"):Clone()
	teleposttt.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposttt.Parent = vfxFolder	
	Debris:AddItem(teleposttt, 1/speed)
	TS:Create(HRP, TweenInfo.new(0.1 / speed, Enum.EasingStyle.Linear), {CFrame = backCFrame}):Play()

	VFX_Helper.EmitAllParticles(teleposttt)
	task.wait(0.11 / speed)
	if not HRP or not HRP.Parent then return end
	local lookVector = originalCFrame.LookVector
	local rockStartPos = originalCFrame.Position - Vector3.new(0, 6, 0)

	local downCFrame = CFrame.new(rockStartPos, rockStartPos - Vector3.new(0, 1, 0))

	local rock = Folder:WaitForChild("Rock"):Clone()
	rock.CFrame = downCFrame
	rock.Parent = HRP
	Debris:AddItem(rock, 1.9/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	local connection = HRP.Parent.Destroying:Once(function()
		rock:Destroy()
	end)

	local liftTargetPosition = rockStartPos + Vector3.new(0, 5.8, 0)
	local liftTargetCFrame = CFrame.new(liftTargetPosition, liftTargetPosition + lookVector)

	local liftTween = TS:Create(rock, TweenInfo.new(0.75 / speed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = liftTargetCFrame})
	liftTween:Play()
	VFX_Helper.EmitAllParticles(startrock)

	task.wait(0.75 / speed)
	if not HRP or not HRP.Parent then return end

	local handexplod = Folder:WaitForChild("Explosion 1"):Clone()
	handexplod.CFrame = HRP.CFrame * CFrame.new(0, 0, -1.6)
	handexplod.Parent = HRP
	Debris:AddItem(handexplod, 2 / speed)



	local flyDistance = Range + 500
	local flyTargetPos = liftTargetPosition + lookVector * flyDistance
	local flyTargetCFrame = CFrame.new(flyTargetPos, flyTargetPos + lookVector)

	local flyTween = TS:Create(rock, TweenInfo.new(1.4 / speed, Enum.EasingStyle.Linear), { CFrame = flyTargetCFrame})
	flyTween:Play()
	VFX_Helper.EmitAllParticles(handexplod)
	VFX_Helper.OnAllParticles(rock)
	RocksModule.Trail(HRP.CFrame,HRP.CFrame.LookVector *3 ,flyDistance,5.1,Vector3.new(0.6,0.6,0.6),0.02,0.05,0.4,true,12,3)

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end
	local telepost = Folder:WaitForChild("teleport"):Clone()
	telepost.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	telepost.Parent = vfxFolder	
	Debris:AddItem(telepost, 1/speed)
	VFX_Helper.EmitAllParticles(telepost)

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Doom Leap"] = function(HRP, target)
	local Folder = VFX["Tenth Brother"].Third
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	--VFX_Helper.SoundPlay(HRP,Folder.Second)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local startemit = Folder:WaitForChild("Endlemit"):Clone()
	startemit.Position = HRP.Position
	startemit.Parent = vfxFolder
	Debris:AddItem(startemit,2/speed)
	VFX_Helper.EmitAllParticles(startemit)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	local End = CFrame.new(enemypos + Vector3.new(0,2,0))
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0) )
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0))

	task.spawn(function()
		task.wait(0.5/speed)

		local Emit = Folder:WaitForChild("main"):Clone()
		Emit.Position = enemypos + Vector3.new(0,-0.5,0)
		Emit.Parent = vfxFolder
		Debris:AddItem(Emit,2/speed)
		VFX_Helper.EmitAllParticles(Emit)

	end)

	for i = 1, 100, 5  do
		local t = i/100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.new(NewPos)
		task.wait(0.014/speed)
	end
	TS:Create(HRP, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(enemypos) }):Play()
	task.wait(1.2/speed)
	local teleposrSE = Folder:WaitForChild("Teleportbls"):Clone()
	teleposrSE.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposrSE.Parent = vfxFolder	
	Debris:AddItem(teleposrSE,1/speed)
	VFX_Helper.EmitAllParticles(teleposrSE)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposr = Folder:WaitForChild("Teleportbls"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr,1/speed)
	VFX_Helper.EmitAllParticles(teleposr)

	HRP.Parent.Attacking.Value = false

end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local RocksModule = require(rs.Modules.RocksModule)


module["Wisest Jedai first attack"] = function(HRP, target)
	local Folder = VFX.Wisest_Jedi.First
	local speed = GameSpeed.Value
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Teleport = Folder:WaitForChild("Startemit"):Clone()
	Teleport.Position = HRP.Parent:WaitForChild("TowerBasePart").Position + Vector3.new(0,-0.5,0)
	Teleport.Parent = HRP.Parent
	Debris:AddItem(Teleport,2/speed)

	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].O.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].O
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.08/speed)
	HRP.Parent.Attacking.Value = true

	if not HRP or not HRP.Parent then return end
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	TS:Create(HRP, TweenInfo.new(0.05/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + enemyCFrame.LookVector * -0.5}):Play()
	VFX_Helper.EmitAllParticles(Teleport)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	task.wait(0.05/speed)
	local Hit = Folder:WaitForChild("Emit"):Clone()
	Hit.Position = enemypos + Vector3.new(0,-1,0)
	Hit.Parent = vfxFolder
	Debris:AddItem(Hit,3/speed)

	task.spawn(function()
		task.wait(0.05/speed)
		VFX_Helper.EmitAllParticles(Hit)
	end)
	if not HRP or not HRP.Parent then return end
	task.wait(0.6/speed)
	TS:Create(Hit.PointLight, TweenInfo.new(0.7/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = 0}):Play()
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end


module["Stone Throw"] = function(HRP, target)
	local Folder = VFX.Wisest_Jedi.Second
	local speed = GameSpeed.Value

	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	VFX_Helper.SoundPlay(HRP,Folder.Seconddd)
	task.wait(0.12/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local rockemit = Folder:WaitForChild("Rockemit"):Clone()
	rockemit.CFrame = startCFrame * CFrame.new(0, -0.7, -2)  * CFrame.Angles(math.rad(90),0,0)
	rockemit.Parent = vfxFolder
	Debris:AddItem(rockemit, 2/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	local rock = Folder:WaitForChild("Rock"):Clone()
	rock.CFrame = startCFrame * CFrame.new(0, -5, -2) 
	rock.Parent = vfxFolder
	Debris:AddItem(rock, 1.5/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		rock:Destroy()
	end)
	local rockUpCFrame = rock.CFrame * CFrame.new(0, 10, 0)
	local tweenUp = TS:Create(rock, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = rockUpCFrame})
	VFX_Helper.EmitAllParticles(rockemit)
	tweenUp:Play()
	task.wait(1.2/speed)
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	local tweenToEnemy = TS:Create(rock, TweenInfo.new(0.18/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + Vector3.new(0,-1,0)})
	tweenToEnemy:Play()
	local groundemit =Folder:WaitForChild("GroundVfx"):Clone()
	groundemit.CFrame = enemyCFrame + Vector3.new(0,-1,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	task.wait(0.18/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	connection:Disconnect()

end

module["Force Palm"] = function(HRP, target)
	local Folder = VFX.Wisest_Jedi.Thrid
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].O.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1.4/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].O
	weld.Part1 = trail
	weld.Parent = trail
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	local Fire = Folder:WaitForChild("YodaEmit"):Clone()
	Fire.CFrame = HRP.CFrame
	Fire.Position = HRP.Parent["Left Arm"].Position 
	Fire.Parent = HRP
	Debris:AddItem(Fire,4/speed)
	VFX_Helper.EmitAllParticles(Fire)
	RocksModule.Trail(HRP.CFrame,HRP.CFrame.LookVector,Range - 2.5,3,Vector3.new(0.5,0.5,0.5),0.02,0.05,0.4,true,6,3)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	task.wait(1/speed)
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["104th Trooper Attack"] = function(HRP, target)
	local Folder = VFX.RAR["Trooper 104th"]
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.9/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	--VFX_Helper.SoundPlay(HRP,Folder.Sound)


	local fire = Folder:WaitForChild("Fire"):Clone()
	fire.CFrame = HRP.Parent["Right Arm"].Handle.Pos.CFrame
	fire.Parent = HRP
	UnitSoundEffectLib.playSound(HRP.Parent, 'Flamethrower')

	Debris:AddItem(fire,2.5/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle.Pos
	weld.Part1 = fire
	weld.Parent = fire
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OnAllParticles(fire)
	task.wait(1.4/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OffAllParticles(fire)
	task.wait(1.5/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = false
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or particle.Rate

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

local function canAttack(HRP, target)
	if not target or not target:FindFirstChild("HumanoidRootPart") then
		warn("no target")
		return false
	end

	return true
end

module["Dual Wield Pistols"] = function(HRP, target)
	task.wait(.25)
	if not canAttack(HRP, target) then
		return
	end

	local folder = VFX["CT"]

	HRP.Parent.Attacking.Value = true

	local vfxPart = folder["2 Pistol Shot"]:Clone()
	local vfxCFrame = (HRP.CFrame * CFrame.new(0,0,-1)) * CFrame.Angles(0,math.rad(-90),0)

	vfxPart.CFrame = vfxCFrame
	vfxPart.Parent = workspace.VFX

	UnitSoundEffectLib.playSound(HRP.Parent, "LaserGun2")

	for i,v in vfxPart:GetDescendants() do
		if not v:IsA("ParticleEmitter") then continue end
		emitParticles(v)
	end

	Debris:AddItem(vfxPart, 2)

	task.wait(.25)

	if HRP and HRP.Parent then
		HRP.Parent.Attacking.Value = false
	end
end


return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Air Shot"] = function(HRP)
	local speed = GameSpeed.Value
	local Folder = VFX.Scout.First
	local GunPoint = HRP.Parent["Right Arm"].Gun.Point

	task.wait(1 / speed)

	VFX_Helper.SoundPlay(HRP, Folder.First)


	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = GunPoint.CFrame
	Ball.Position = GunPoint.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball, 1 / speed)

	local targetPosition = HRP.Position + Vector3.new(0, 10, 0)

	TS:Create(Ball, TweenInfo.new(0.13 / speed, Enum.EasingStyle.Linear), {
		Position = targetPosition
	}):Play()

	task.wait(0.1)

	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Cinate Attack"] = function(HRP, target)
	local Folder = VFX.RAR["Cinate Guard"]
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.82/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	--VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	local Ball = Folder:WaitForChild("Patronys"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.pos.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.pos.Position 
	Ball.Parent = HRP
	Debris:AddItem(Ball,1/speed)
	task.wait(0.01/speed)

	local emitgun = HRP.Parent["Right Arm"].Gun.pos
	VFX_Helper.EmitAllParticles(emitgun)
	TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	UnitSoundEffectLib.playSound(HRP.Parent, "Blaster" .. tostring(math.random(1,3)))
	task.wait(0.085/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	task.wait(0.01/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(Ball)

	local lastboom = Folder:WaitForChild("bomchik"):Clone()
	lastboom.Position = Ball.Position
	lastboom.Parent = vfxFolder
	Debris:AddItem(lastboom,2/speed)
	VFX_Helper.EmitAllParticles(lastboom)


	HRP.Parent.Attacking.Value = false
end


return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Duoble Attack"] = function(HRP, target)
	local Folder = VFX.RAR["Corruscent Guard"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.9/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	local Secondball = Folder:WaitForChild("Part"):Clone()
	Secondball.CFrame = HRP.Parent["Left Arm"].Gun2.Pos2.CFrame
	Secondball.Position = HRP.Parent["Left Arm"].Gun2.Pos2.Position
	Secondball.Parent = vfxFolder
	Debris:AddItem(Secondball,1/speed)
	task.wait(0.01/speed)

	local SecondEmit = HRP.Parent["Left Arm"].Gun2.Pos2
	VFX_Helper.EmitAllParticles(SecondEmit)
	TS:Create(Secondball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	Secondball.Transparency = 1
	VFX_Helper.OffAllParticles(Secondball)

	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end
	local Ball = Folder:WaitForChild("Part"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.Pos.Position 
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	task.wait(0.01/speed)

	local emitgun = HRP.Parent["Right Arm"].Gun.Pos
	VFX_Helper.EmitAllParticles(emitgun)
	TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	VFX_Helper.OffAllParticles(Ball)

	HRP.Parent.Attacking.Value = false
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local tweenService = game:GetService("TweenService")
function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end


local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end

module["Command Roll"] = function(HRP, target)
	local Folder = VFX["Jungle Trooper"].First
	local speed = GameSpeed.Value
	local enemyPos = Vector3.new(
		target.HumanoidRootPart.Position.X,
		HRP.Position.Y,
		target.HumanoidRootPart.Position.Z
	)

	task.wait(0.77 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local emitters = {}

	local RightArm = HRP.Parent:FindFirstChild('Right Arm')
	if RightArm then
		for i,v in RightArm:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				--print('found a particle!!!')
				table.insert(emitters, v)
			end
		end
	end

	UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster3')

	for _, emitter in emitters do
		emitter.Enabled = true
		task.delay(0.2 / speed, function()
			if emitter then emitter.Enabled = false end
		end)
	end

	HRP.Parent.Attacking.Value = false
end



return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Rifleman Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Rifleman.First
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end

	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.Point.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.Point.Position 
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	Ball.Transparency = 1
end




return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0	

	return weld
end

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or particle.Rate

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

local function canAttack(HRP, target)
	if not HRP or not HRP.Parent then
		warn("no humanoidrootpart for unit")
		return false
	end
	if not target or not target:FindFirstChild("HumanoidRootPart") then
		warn("no target")
		return false
	end

	return true
end

module["Flamethrower"] = function(HRP, target)
	task.wait(.25)

	if not HRP or not target then
		return
	end

	local vfxFolder = VFX["Sand Trooper"]
	local sandTrooperFX = vfxFolder["Flame Thrower"]:Clone()
	sandTrooperFX.CFrame = HRP.CFrame * CFrame.new(-.5, .2, 0)
	sandTrooperFX.Parent = workspace.VFX

	local weld = connect(sandTrooperFX, HRP, CFrame.new(-.5, .2, 0))
	UnitSoundEffectLib.playSound(HRP.Parent, 'Flamethrower')

	for _, particle in sandTrooperFX:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end	

	HRP.Parent.Attacking.Value = true

	task.delay(1.5, function()
		if HRP and HRP.Parent then
			HRP.Parent.Attacking.Value = false
		end

		for _, particle in sandTrooperFX:GetDescendants() do
			if particle:IsA("ParticleEmitter") then
				particle.Enabled = false
			end
		end	

		Debris:AddItem(sandTrooperFX, 1)

		if weld then
			weld:Destroy()
		end
	end)

	task.wait(1.5)

	if HRP.Parent:FindFirstChild("Humanoid") and HRP.Parent.Humanoid:FindFirstChildOfClass("Animator") then
		for _, track in HRP.Parent.Humanoid.Animator:GetPlayingAnimationTracks() do
			if track.Animation.AnimationId == "rbxassetid://72711407720938" then
				track:Stop(.1)
			end
		end
	end
end



return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Scout Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Scout.First
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.Point.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.Point.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end

return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

module["Grenade Attack"] = function(HRP, target)
	local Folder = VFX.RAR["Scout Trooper"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.77/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local granata = HRP.Parent["Right Arm"].Handle

	local grenadeClone = granata:Clone()
	grenadeClone.Parent = HRP	
	grenadeClone.CFrame = granata.CFrame


	local function makeTransparent(part)
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
		for _, child in ipairs(part:GetChildren()) do
			makeTransparent(child)
		end
	end
	makeTransparent(granata)

	local End = CFrame.new(enemypos)
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,2,0))
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,2,0))

	for i = 1, 102, 6  do
		local t = i/100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		grenadeClone.CFrame = CFrame.new(NewPos)
		task.wait(0.01/speed)
	end

	local EXPL = Folder:WaitForChild("Explosion"):Clone()
	EXPL.Position = enemypos
	EXPL.Parent = HRP
	Debris:AddItem(EXPL,2/speed)
	VFX_Helper.EmitAllParticles(EXPL)
	task.wait(0.5)
	if not HRP or not HRP.Parent then return end
	local function restoreTransparency(part)
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
		for _, child in ipairs(part:GetChildren()) do
			restoreTransparency(child)
		end
	end
	restoreTransparency(granata)
	task.wait(0.2)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or particle.Rate

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

local function canAttack(HRP, target)
	if not HRP or not HRP.Parent then
		warn("no humanoidrootpart for unit")
		return false
	end
	if not target or not target:FindFirstChild("HumanoidRootPart") then
		warn("no target")
		return false
	end

	return true
end

module["Semi Auto Fire"] = function(HRP, target)
	task.wait(.25)
	if not canAttack(HRP, target) then
		return
	end

	local folder = VFX["Senate Guard"]

	HRP.Parent.Attacking.Value = true

	for i = 1, 3 do
		if not canAttack(HRP, target) then
			break
		end

		local vfxPart = folder["3 Big Laser"]:Clone()
		local vfxCFrame = (HRP.CFrame) * CFrame.Angles(0,math.rad(-90),0)

		vfxPart.CFrame = vfxCFrame
		vfxPart.Parent = workspace.VFX

		for i,v in vfxPart:GetDescendants() do
			if not v:IsA("ParticleEmitter") then continue end
			emitParticles(v)
		end

		Debris:AddItem(vfxPart, 2)
		UnitSoundEffectLib.playSound(HRP.Parent, 'LaserGun1')

		task.wait(.25)
	end

	if HRP and HRP.Parent then
		HRP.Parent.Attacking.Value = false
	end
end


return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Soldier Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Soldier.First
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.Point.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.Point.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.03/speed)
	if not HRP or not HRP.Parent then return end

	task.spawn(function()
		task.wait(0.1/speed)
		Ball.Transparency = 1
	end)
	local Ball2 = Folder:WaitForChild("Ball"):Clone()
	Ball2.CFrame = HRP.Parent["Right Arm"].Gun.Point.CFrame
	Ball2.Position = HRP.Parent["Right Arm"].Gun.Point.Position
	Ball2.Parent = vfxFolder
	Debris:AddItem(Ball2,1/speed)
	TS:Create(Ball2,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.03/speed)
	if not HRP or not HRP.Parent then return end

	task.spawn(function()
		task.wait(0.1/speed)
		Ball2.Transparency = 1
	end)
	local Ball3 = Folder:WaitForChild("Ball"):Clone()
	Ball3.CFrame = HRP.Parent["Right Arm"].Gun.Point.CFrame
	Ball3.Position = HRP.Parent["Right Arm"].Gun.Point.Position
	Ball3.Parent = vfxFolder
	Debris:AddItem(Ball3,1/speed)
	TS:Create(Ball3,TweenInfo.new(0.14/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.04/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false

	task.spawn(function()
		task.wait(0.1/speed)
		Ball3.Transparency = 1
	end)
end




return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Scout Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Scout.First
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	print(Range, "new range")
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.Trail.Color = ColorSequence.new(Color3.fromRGB(255,0,0))
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.Point.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.Point.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end

return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Scout Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Scout.First
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.Trail.Color = ColorSequence.new(Color3.fromRGB(255,0,0))
	Ball.CFrame = HRP.Parent["Right Arm"].Point.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Point.Position
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local repStorage = game:GetService('ReplicatedStorage')
local tweenService = game:GetService('TweenService')
local Debris = game:GetService("Debris")

local vfxFolder = repStorage.VFX
local templeGuardVfx = vfxFolder["Temple Guard"]

local module = {}

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 10

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

function module.Shunt(HRP, target)
	local shunt = templeGuardVfx.Shunt:Clone()
	shunt.CFrame = HRP.CFrame * CFrame.new(0,0,-2)
	shunt.Parent = workspace.VFX

	task.delay(.5, function() -- random number to time with animation
		for _, particle in shunt:GetDescendants() do
			if not particle:IsA("ParticleEmitter") then continue end
			emitParticles(particle)
			UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
		end

		Debris:AddItem(shunt, 2)
	end)
end

return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed


module["Dart Wader attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dart Wader"].First
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Ground1.CFrame 
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1.3/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Ground1
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.8/speed)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	local slash = Folder:WaitForChild("Position"):Clone()
	slash.CFrame = HRP.CFrame 
	slash.Parent = vfxFolder
	Debris:AddItem(slash,3/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		slash:Destroy()
	end)
	local decal = Folder:WaitForChild("Scar"):Clone()
	decal.CFrame = HRP.CFrame * CFrame.new(0.25,-1,-11)
	decal.Parent = vfxFolder
	Debris:AddItem(decal,3/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		decal:Destroy()
	end)

	local targetPosition = ( HRP.CFrame * CFrame.new(0, 0, -Range))
	TS:Create(slash, TweenInfo.new(0.3/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	VFX_Helper.EmitAllParticles(decal)
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OffAllParticles(slash)
	for _,v in (slash:GetDescendants()) do	
		if v:IsA("Beam") then
			TS:Create(
				v,
				TweenInfo.new(0.5/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Width0 = 0,Width1 = 0}
			):Play()
		end	
	end
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	task.wait(0.5/speed)
	if not HRP or not HRP.Parent then return end
	for _,v in (decal:GetDescendants()) do	
		if v:IsA('Decal') then
			TS:Create(
				v,
				TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 1}
			):Play()
		end
	end
	connection:Disconnect()

end


module["Anekan Skaivoker"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dart Wader"].First_Blue
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Ground1.CFrame 
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1.3/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Ground1
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.8/speed)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	local slash = Folder:WaitForChild("Position"):Clone()
	slash.CFrame = HRP.CFrame 
	slash.Parent = vfxFolder
	Debris:AddItem(slash,3/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		slash:Destroy()
	end)
	local decal = Folder:WaitForChild("Scar"):Clone()
	decal.CFrame = HRP.CFrame * CFrame.new(0.25,-1,-11)
	decal.Parent = vfxFolder
	Debris:AddItem(decal,3/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		decal:Destroy()
	end)

	local targetPosition = ( HRP.CFrame * CFrame.new(0, 0, -Range))
	TS:Create(slash, TweenInfo.new(0.3/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	VFX_Helper.EmitAllParticles(decal)
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OffAllParticles(slash)
	for _,v in (slash:GetDescendants()) do	
		if v:IsA("Beam") then
			TS:Create(
				v,
				TweenInfo.new(0.5/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Width0 = 0,Width1 = 0}
			):Play()
		end	
	end
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	task.wait(0.5/speed)
	if not HRP or not HRP.Parent then return end
	for _,v in (decal:GetDescendants()) do	
		if v:IsA('Decal') then
			TS:Create(
				v,
				TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 1}
			):Play()
		end
	end
	connection:Disconnect()

end

module["Stone Rain attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dart Wader"].Second
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	-- Створюємо слід
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Ground1.CFrame
	trail.Parent = vfxFolder
	Debris:AddItem(trail, 2/speed)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Ground1
	weld.Part1 = trail
	weld.Parent = trail

	task.wait(0.63/speed)
	if not HRP or not HRP.Parent then return end

	local rocks = {}
	local connection = nil
	for i = 1, 20 do
		local rock = Folder:WaitForChild("Stone"):Clone()
		Debris:AddItem(rock,2/speed)
		connection = HRP.Parent.Destroying:Once(function()
			rock:Destroy()
		end)
		local randomX = math.random(-Range/1.5, Range/1.5)
		local randomZ = math.random(-Range/1.5, Range/1.5)

		local spawnPosition = HRP.Position + Vector3.new(randomX, -5, randomZ)
		rock.CFrame = CFrame.new(spawnPosition)
		rock.Parent = vfxFolder

		local upTime =  math.random(13,14)/10/speed
		local downTime = 0.2/speed

		TS:Create(rock, TweenInfo.new(upTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = rock.Position + Vector3.new(0, math.random(12,17), 0)}):Play()
		TS:Create(rock, TweenInfo.new(upTime,Enum.EasingStyle.Linear),{Orientation = Vector3.new(math.random(0,360),math.random(0,360),math.random(0,360))}):Play()

		task.spawn(function()
			task.wait(upTime/speed)
			TS:Create(rock, TweenInfo.new(downTime,Enum.EasingStyle.Linear),{Orientation = Vector3.new(math.random(0,360),math.random(0,360),math.random(0,360))}):Play()
			local finalPos = Vector3.new(rock.Position.X,HRP.Position.Y - 2,rock.Position.Z)
			TS:Create(rock, TweenInfo.new(downTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = finalPos}):Play()

			task.wait(downTime/speed)

			local groundemit = Folder:WaitForChild("GroundVfx"):Clone()
			groundemit.Position = finalPos + Vector3.new(0, .9, 0)
			groundemit.Parent = vfxFolder
			Debris:AddItem(groundemit, 3/speed) 
			VFX_Helper.EmitAllParticles(groundemit)

		end)


	end

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


module["Stone Rain"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dart Wader"].Second_Blue
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	-- Створюємо слід
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Ground1.CFrame
	trail.Parent = vfxFolder
	Debris:AddItem(trail, 2/speed)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Ground1
	weld.Part1 = trail
	weld.Parent = trail

	task.wait(0.63/speed)
	if not HRP or not HRP.Parent then return end

	local rocks = {}
	local connection = nil
	for i = 1, 20 do
		local rock = Folder:WaitForChild("Stone"):Clone()
		Debris:AddItem(rock,2/speed)
		connection = HRP.Parent.Destroying:Once(function()
			rock:Destroy()
		end)
		local randomX = math.random(-Range/1.5, Range/1.5)
		local randomZ = math.random(-Range/1.5, Range/1.5)

		local spawnPosition = HRP.Position + Vector3.new(randomX, -5, randomZ)
		rock.CFrame = CFrame.new(spawnPosition)
		rock.Parent = vfxFolder

		local upTime =  math.random(13,14)/10/speed
		local downTime = 0.2/speed

		TS:Create(rock, TweenInfo.new(upTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = rock.Position + Vector3.new(0, math.random(12,17), 0)}):Play()
		TS:Create(rock, TweenInfo.new(upTime,Enum.EasingStyle.Linear),{Orientation = Vector3.new(math.random(0,360),math.random(0,360),math.random(0,360))}):Play()

		task.spawn(function()
			task.wait(upTime/speed)
			TS:Create(rock, TweenInfo.new(downTime,Enum.EasingStyle.Linear),{Orientation = Vector3.new(math.random(0,360),math.random(0,360),math.random(0,360))}):Play()
			local finalPos = Vector3.new(rock.Position.X,HRP.Position.Y - 2,rock.Position.Z)
			TS:Create(rock, TweenInfo.new(downTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = finalPos}):Play()

			task.wait(downTime/speed)

			local groundemit = Folder:WaitForChild("GroundVfx"):Clone()
			groundemit.Position = finalPos + Vector3.new(0, .9, 0)
			groundemit.Parent = vfxFolder
			Debris:AddItem(groundemit, 3/speed) 
			VFX_Helper.EmitAllParticles(groundemit)

		end)


	end

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


module["Death Star"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dart Wader"].Thrid
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	if not target:FindFirstChild('HumanoidRootPart') then return end

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	VFX_Helper.SoundPlay(HRP,Folder.Third)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Ground1.CFrame
	trail.Parent = vfxFolder
	Debris:AddItem(trail, 2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Ground1
	weld.Part1 = trail
	weld.Parent = trail

	local starStartPos = HRP.Position - HRP.CFrame.LookVector * 150 + Vector3.new(0, 45, 0)
	local star = Folder:WaitForChild("Star"):Clone()
	star.CFrame = CFrame.new(starStartPos) 
	star.Parent = vfxFolder 
	Debris:AddItem(star, 5.5/speed)

	local connection = HRP.Parent.Destroying:Once(function()
		star:Destroy()
	end)
	local starEndPos = HRP.Position - HRP.CFrame.LookVector * 8 + Vector3.new(0, 15, 0)
	local starEndCFrame = CFrame.lookAt(starEndPos, enemypos)
	TS:Create(star, TweenInfo.new(1/speed, Enum.EasingStyle.Exponential), {CFrame = starEndCFrame}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	task.wait(.2/speed)
	if not HRP or not HRP.Parent then return end
	enemypos = VFX_Helper.getEnemyPos(target,enemypos)
	local lych = Folder:WaitForChild("lych"):Clone()
	lych.UP.CFrame = star.CFrame 
	lych.Dwn.CFrame = star.CFrame 
	lych.Parent = vfxFolder
	Debris:AddItem(lych, 5/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		lych:Destroy()
	end)
	local targetPosition = CFrame.new(enemypos + Vector3.new(0, -1, 0)) 
	TS:Create(lych.Dwn, TweenInfo.new(0.25/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetPosition}):Play()
	task.wait(0.22/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OnAllParticles(lych.Dwn)
	task.wait(0.18/speed)
	if not HRP or not HRP.Parent then return end

	for _, v in (lych:GetChildren()) do
		if v:IsA("Beam") then 
			v.Enabled = true
		end
	end

	task.wait(2/speed)
	if not HRP or not HRP.Parent then return end

	for _,v in (lych:GetDescendants()) do	
		if v:IsA("Beam") then
			TS:Create(
				v,
				TweenInfo.new(0.5/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Width0 = 0,Width1 = 0}
			):Play()
		end	
	end
	VFX_Helper.OffAllParticles(lych.Dwn)
	task.wait(.5/speed)
	if not HRP or not HRP.Parent then return end

	local midRotatedCFrame = star.CFrame * CFrame.new(1, 6, 0) * CFrame.Angles(math.rad(68), 0, 0)
	TS:Create(star, TweenInfo.new(.8/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = midRotatedCFrame}):Play()
	task.wait(.8/speed)
	if not HRP or not HRP.Parent then return end


	local flyAwayCFrame = midRotatedCFrame * CFrame.new(0, 0, -160)
	TS:Create(star, TweenInfo.new(.6/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = flyAwayCFrame}):Play()
	task.wait(.6/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end






return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RocksModule = require(rs.Modules.RocksModule)
local StoryModeStats = require(rs.StoryModeStats)
local GameSpeed = workspace.Info.GameSpeed

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0
	return weld
end

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 10

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

module["Force Choke"] = function(HRP, target)
	--warn("Firing VFX")
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX.Anakin.Third
	local speed = GameSpeed.Value

	local MobName = target.Name
	if not target:FindFirstChild('HumanoidRootPart') then return end

	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	--warn(target:GetChildren())
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	task.wait(0.4/speed)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	--print(target:GetChildren(), target, targetCF)
	if target then targetCF = target:WaitForChild("HumanoidRootPart").CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		for _, folder in folders do
			for i, mob in rs.Enemies[folder]:GetChildren() do
				if mob.Name == MobName then
					Mob = mob:Clone()
				end
			end
		end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end

	local forceChoke = anikinFolder["Force Choke"]:Clone()
	forceChoke.Parent = workspace.VFX

	connect(forceChoke, Mob.HumanoidRootPart, CFrame.new(0,-1,0))

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end

	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = false
		end
	end

	Debris:AddItem(forceChoke, 2)

	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Force Throw"] = function(HRP, target)
	local folder = VFX.Anakin
	local throwFx = folder.Second["Force Throw"]:Clone()
	if not target:FindFirstChild('HumanoidRootPart') then return end
	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local speed = workspace.Info.GameSpeed.Value
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')

	if not HRP or not target or not target:FindFirstChild("HumanoidRootPart") then return end

	local Mob = target:Clone()

	if not Mob then return end

	throwFx.CFrame = HRP.CFrame
	throwFx.Parent = workspace.VFX	

	for _, particle in throwFx:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			emitParticles(particle)
		end
	end

	Debris:AddItem(throwFx, 1/speed)

	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,1/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)

	HRP.Parent.Attacking.Value = true

	local pushDirection = (targetCF.Position-HRP.CFrame.Position).Unit

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Parent = Mob.HumanoidRootPart
	bodyVelocity.Velocity = pushDirection * 40
	bodyVelocity.MaxForce = Vector3.new(1,0,1) * 1000000

	warn('parented to the targets root part')

	Debris:AddItem(bodyVelocity, .2)

	task.wait(.5)

	if HRP and HRP.Parent then
		HRP.Parent.Attacking.Value = false
	end

end

module["Dual Wield"] = function(HRP, target)
	task.wait(.5)

	if not HRP or not HRP.Parent or not target or not target:FindFirstChild("HumanoidRootPart") then
		--warn("rejecting dual wield")
		return
	end

	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	local folder = VFX.Anakin.First
	local slash = folder.Slash:Clone()

	slash.CFrame = HRP.CFrame
	slash.Parent = workspace.VFX

	for _, particle in slash:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		emitParticles(particle)
	end

	Debris:AddItem(slash, 2)
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RocksModule = require(rs.Modules.RocksModule)
local StoryModeStats = require(rs.StoryModeStats)
local GameSpeed = workspace.Info.GameSpeed

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0
	return weld
end

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 10

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

module["Force Choke"] = function(HRP, target)
	warn("Force Choke")
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX.Anakin.Third
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(1.1/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		for _, folder in folders do
			for i, mob in rs.Enemies[folder]:GetChildren() do
				if mob.Name == MobName then
					Mob = mob:Clone()
				end
			end
		end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end

	local forceChoke = anikinFolder["Force Choke"]:Clone()
	forceChoke.Parent = workspace.VFX

	connect(forceChoke, Mob.HumanoidRootPart, CFrame.new(0,-1,0))

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end

	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	if not HRP or not HRP.Parent then return end

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = false
		end
	end

	Debris:AddItem(forceChoke, 2)

	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Force Throw"] = function(HRP, target)
	local folder = VFX.Anakin
	local throwFx = folder.Second["Force Throw"]:Clone()

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local speed = workspace.Info.GameSpeed.Value

	if not HRP or not target or not target:FindFirstChild("HumanoidRootPart") then return end

	local Mob = target:Clone()

	if not Mob then return end

	throwFx.CFrame = HRP.CFrame
	throwFx.Parent = workspace.VFX	
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	for _, particle in throwFx:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			emitParticles(particle)
		end
	end

	Debris:AddItem(throwFx, 1/speed)

	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,1/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)

	HRP.Parent.Attacking.Value = true

	local pushDirection = (targetCF.Position-HRP.CFrame.Position).Unit
	
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Parent = Mob.HumanoidRootPart
	bodyVelocity.Velocity = pushDirection * 40
	bodyVelocity.MaxForce = Vector3.new(1,0,1) * 1000000
	
	warn('parented to the targets root part')
	
	Debris:AddItem(bodyVelocity, .2)

	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	task.wait(.5)

	if HRP and HRP.Parent then
		HRP.Parent.Attacking.Value = false
	end

end

module["Dual Wield"] = function(HRP, target)
	task.wait(.5)
	
	if not HRP or not HRP.Parent or not target or not target:FindFirstChild("HumanoidRootPart") then
		--warn("rejecting dual wield")
		return
	end
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	local folder = VFX.Anakin.First
	local slash = folder.Slash:Clone()

	slash.CFrame = HRP.CFrame
	slash.Parent = workspace.VFX

	for _, particle in slash:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		emitParticles(particle)
	end

	Debris:AddItem(slash, 2)
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RocksModule = require(rs.Modules.RocksModule)
local StoryModeStats = require(rs.StoryModeStats)
local GameSpeed = workspace.Info.GameSpeed

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0
	return weld
end

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 10

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

module["Force Choke"] = function(HRP, target)
	warn("Force Choke")
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX.Anakin.Third
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(1.1/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		for _, folder in folders do
			for i, mob in rs.Enemies[folder]:GetChildren() do
				if mob.Name == MobName then
					Mob = mob:Clone()
				end
			end
		end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end

	local forceChoke = anikinFolder["Force Choke"]:Clone()
	forceChoke.Parent = workspace.VFX

	connect(forceChoke, Mob.HumanoidRootPart, CFrame.new(0,-1,0))

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end

	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	if not HRP or not HRP.Parent then return end

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = false
		end
	end

	Debris:AddItem(forceChoke, 2)

	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Force Throw"] = function(HRP, target)
	local folder = VFX.Anakin
	local throwFx = folder.Second["Force Throw"]:Clone()

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local speed = workspace.Info.GameSpeed.Value

	if not HRP or not target or not target:FindFirstChild("HumanoidRootPart") then return end

	local Mob = target:Clone()

	if not Mob then return end

	throwFx.CFrame = HRP.CFrame
	throwFx.Parent = workspace.VFX	
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	for _, particle in throwFx:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			emitParticles(particle)
		end
	end

	Debris:AddItem(throwFx, 1/speed)

	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,1/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)

	HRP.Parent.Attacking.Value = true

	local pushDirection = (targetCF.Position-HRP.CFrame.Position).Unit

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Parent = Mob.HumanoidRootPart
	bodyVelocity.Velocity = pushDirection * 40
	bodyVelocity.MaxForce = Vector3.new(1,0,1) * 1000000

	warn('parented to the targets root part')

	Debris:AddItem(bodyVelocity, .2)

	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	task.wait(.5)

	if HRP and HRP.Parent then
		HRP.Parent.Attacking.Value = false
	end

end

module["Dual Wield"] = function(HRP, target)
	task.wait(.5)

	if not HRP or not HRP.Parent or not target or not target:FindFirstChild("HumanoidRootPart") then
		--warn("rejecting dual wield")
		return
	end
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	local folder = VFX.Anakin.First
	local slash = folder.Slash:Clone()

	slash.CFrame = HRP.CFrame
	slash.Parent = workspace.VFX

	for _, particle in slash:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		emitParticles(particle)
	end

	Debris:AddItem(slash, 2)
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = game.Workspace.Info.GameSpeed
function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end


module["Circle of Light"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Asaka Tano"].Thrid
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"].HandleR.Trail
	local handleL = HRP.Parent["Left Arm"].HandleL.Trail
	handleL.Enabled = true
	handleR.Enabled = true
	task.wait(0.7/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local Emit = Folder:WaitForChild("AOE_emit"):Clone()
	Emit.Position = HRP.Position
	Emit.Parent = vfxFolder
	Debris:AddItem(Emit,7/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Emit:Destroy()
	end)
	TS:Create(HRP,TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear),{CFrame = HRP.CFrame * CFrame.new(0, 4, 0)}):Play()
	--HRP.Anchored = true
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Slices1')

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,2)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	VFX_Helper.OnAllParticles(trail)
	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OnAllParticles(Emit)

	local points = {}
	local center = HRP.Position

	for i = 1, 18 do
		local angle = math.rad((360 / 18) * i)
		local radius = 15
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local y = math.random(-3, 7)
		table.insert(points, center + Vector3.new(x, y, z))
	end

	for i = 1, #points do
		if not HRP or not HRP.Parent then return end
		HRP.CFrame = CFrame.new(points[i])
		task.wait((1.75 / #points) / speed)
	end


	VFX_Helper.OffAllParticles(Emit)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OffAllParticles(trail)

	--HRP.Anchored = false

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	handleL.Enabled = false
	handleR.Enabled = false
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end

module["Cross Slash"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Asaka Tano"].First
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"]:WaitForChild('HandleR'):WaitForChild('Trail')
	local handleL = HRP.Parent["Left Arm"]:WaitForChild('HandleL'):WaitForChild('Trail')
	handleL.Enabled = true
	handleR.Enabled = true

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	UnitSoundEffectLib.playSound(HRP.Parent, 'Slices1')
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(tonumber(1,2)))
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1.2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(trail)
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local starsemit = Folder:WaitForChild("Burst"):Clone()
	starsemit.Position = HRP.Position
	starsemit.Parent = HRP.Parent
	VFX_Helper.EmitAllParticles(starsemit)

	Debris:AddItem(starsemit,2/speed)
	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	task.wait(0.08/speed)
	if not HRP or not HRP.Parent then return end

	local Hit = Folder:WaitForChild("Slash"):Clone()
	Hit.CFrame = HRP.CFrame 
	Hit.Parent = HRP
	Debris:AddItem(Hit,2/speed)
	VFX_Helper.EmitAllParticles(Hit)
	VFX_Helper.EmitAllParticles(Hit.Slash)
	TS:Create(Hit, TweenInfo.new(0.05/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	VFX_Helper.OffAllParticles(trail)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end

module["First Slash"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Asaka Tano"].FirstGrenn
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"].HandleR.Trail
	local handleL = HRP.Parent["Left Arm"].HandleL.Trail
	handleL.Enabled = true
	handleR.Enabled = true

	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(tonumber(1,2)))

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1.2/speed)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(trail)
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local starsemit = Folder:WaitForChild("Burst"):Clone()
	starsemit.Position = HRP.Position
	starsemit.Parent = HRP.Parent
	VFX_Helper.EmitAllParticles(starsemit)

	Debris:AddItem(starsemit,2/speed)
	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	task.wait(0.08/speed)
	if not HRP or not HRP.Parent then return end

	local Hit = Folder:WaitForChild("Slash"):Clone()
	Hit.CFrame = HRP.CFrame 
	Hit.Parent = HRP
	Debris:AddItem(Hit,2/speed)
	VFX_Helper.EmitAllParticles(Hit)
	VFX_Helper.EmitAllParticles(Hit.Slash)
	TS:Create(Hit, TweenInfo.new(0.05/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	VFX_Helper.OffAllParticles(trail)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end

module["Vortex Strike"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Asaka Tano"].Second
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"].HandleR.Trail
	local handleL = HRP.Parent["Left Arm"].HandleL.Trail
	handleL.Enabled = true
	handleR.Enabled = true

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Slices1')
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(tonumber(1,2)))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(trail)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local starsemit = Folder:WaitForChild("Burst"):Clone()
	starsemit.Position = HRP.Position
	starsemit.Parent = HRP.Parent
	VFX_Helper.EmitAllParticles(starsemit)

	Debris:AddItem(starsemit,2/speed)
	local End = CFrame.new(enemypos + Vector3.new(0,0.3,0))
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0) )
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0))


	for i = 1, 100, 5  do
		local t = i/100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.new(NewPos)
		task.wait(0.014/speed)
	end

	local slash = Folder:WaitForChild("Slash"):Clone()
	slash.Position = HRP.Position
	slash.Parent = HRP
	Debris:AddItem(slash,3/speed)
	VFX_Helper.OnAllParticles(slash)
	VFX_Helper.OffAllParticles(trail)
	task.wait(0.2/speed)	
	task.spawn(function()
		local points = {}
		local center = HRP.Position

		for i = 1, 18 do
			local angle = math.rad((360 / 18) * i)
			local radius = 4
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			local y = math.random(-0.5, 2)
			table.insert(points, center + Vector3.new(x, y, z))
		end

		for i = 1, #points do
			if not HRP or not HRP.Parent then return end
			HRP.CFrame = CFrame.new(points[i])
			task.wait(0.75 / #points / speed)
		end
	end)

	task.wait(0.8/speed)	

	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(slash)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposrrr = Folder:WaitForChild("teleport"):Clone()
	teleposrrr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposrrr.Parent = vfxFolder	
	Debris:AddItem(teleposrrr,1/speed)
	VFX_Helper.EmitAllParticles(teleposrrr)
	HRP.Parent.Attacking.Value = false
end

module["Saber Flurry"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Asaka Tano"].SecondGreen
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"].HandleR.Trail
	local handleL = HRP.Parent["Left Arm"].HandleL.Trail
	handleL.Enabled = true
	handleR.Enabled = true
	UnitSoundEffectLib.playSound(HRP.Parent, 'Slices1')
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(tonumber(1,2)))

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(trail)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local starsemit = Folder:WaitForChild("Burst"):Clone()
	starsemit.Position = HRP.Position
	starsemit.Parent = HRP.Parent
	VFX_Helper.EmitAllParticles(starsemit)

	Debris:AddItem(starsemit,2/speed)
	local End = CFrame.new(enemypos + Vector3.new(0,0.3,0))
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0) )
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0))


	for i = 1, 100, 5  do
		local t = i/100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.new(NewPos)
		task.wait(0.014/speed)
	end

	local slash = Folder:WaitForChild("Slash"):Clone()
	slash.Position = HRP.Position
	slash.Parent = HRP
	Debris:AddItem(slash,3/speed)
	VFX_Helper.OnAllParticles(slash)
	VFX_Helper.OffAllParticles(trail)
	task.wait(0.2/speed)	
	task.spawn(function()
		local points = {}
		local center = HRP.Position

		for i = 1, 18 do
			local angle = math.rad((360 / 18) * i)
			local radius = 4
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			local y = math.random(-0.5, 2)
			table.insert(points, center + Vector3.new(x, y, z))
		end

		for i = 1, #points do
			if not HRP or not HRP.Parent then return end
			HRP.CFrame = CFrame.new(points[i])
			task.wait(0.75 / #points / speed)
		end
	end)

	task.wait(0.8/speed)	

	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(slash)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposrrr = Folder:WaitForChild("teleport"):Clone()
	teleposrrr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposrrr.Parent = vfxFolder	
	Debris:AddItem(teleposrrr,1/speed)
	VFX_Helper.EmitAllParticles(teleposrrr)
	HRP.Parent.Attacking.Value = false
end
return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end


module["Easter Shot"] = function(HRP, target)
	local Folder = VFX.MIF["Bounty Bunny"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	task.wait(0.92 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP, Folder.Sound)

	local Ball1 = Folder:WaitForChild("eggs1"):Clone()
	local randomoffset1 = Vector3.new(math.random(-2, 2), -1, math.random(-2, 2))
	local readyrand1 = enemypos + randomoffset1
	Ball1.CFrame = HRP.Parent["Left Arm"].Gun.Pos.CFrame
	Ball1.Position = HRP.Parent["Left Arm"].Gun.Pos.Position
	Ball1.Parent = vfxFolder
	Debris:AddItem(Ball1, 2 / speed)
	task.wait(0.001 / speed)

	local targetCFrame1 = CFrame.new(readyrand1)
	TS:Create(Ball1, TweenInfo.new(0.1 / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame1}):Play()
	task.wait(0.085 / speed)

	if not HRP or not HRP.Parent then return end
	local Endlemit1 = Folder:WaitForChild("Explosion_blue1"):Clone()
	Endlemit1.Position = readyrand1 + Vector3.new(0, 0.23, 0)
	Endlemit1.Parent = vfxFolder
	Debris:AddItem(Endlemit1, 2 / speed)
	VFX_Helper.EmitAllParticles(Endlemit1)
	UnitSoundEffectLib.playSound(HRP.Parent, 'EliteBlaster1')
	Ball1.eggs.Transparency = 1

	task.wait(0.1 / speed)
	if not HRP or not HRP.Parent then return end

	local Ball2 = Folder:WaitForChild("eggs2"):Clone()
	local randomoffset2 = Vector3.new(math.random(-4, 4), -1, math.random(-4, 4))
	local readyrand2 = enemypos + randomoffset2
	Ball2.CFrame = HRP.Parent["Left Arm"].Gun.Pos.CFrame
	Ball2.Position = HRP.Parent["Left Arm"].Gun.Pos.Position
	Ball2.Parent = vfxFolder
	Debris:AddItem(Ball2, 2 / speed)
	task.wait(0.001 / speed)

	local targetCFrame2 = CFrame.new(readyrand2)
	TS:Create(Ball2, TweenInfo.new(0.1 / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame2}):Play()
	task.wait(0.085 / speed)

	if not HRP or not HRP.Parent then return end
	local Endlemit2 = Folder:WaitForChild("Explosion_yellou2"):Clone()
	Endlemit2.Position = readyrand2 + Vector3.new(0, 0.23, 0)
	Endlemit2.Parent = vfxFolder
	Debris:AddItem(Endlemit2, 2 / speed)
	VFX_Helper.EmitAllParticles(Endlemit2)
	Ball2.Cylinder.Transparency = 1

	task.wait(0.1 / speed)
	if not HRP or not HRP.Parent then return end

	local Ball3 = Folder:WaitForChild("eggs3"):Clone()
	local randomoffset3 = Vector3.new(math.random(-3, 3), -1, math.random(-3, 3))
	local readyrand3 = enemypos + randomoffset3
	Ball3.CFrame = HRP.Parent["Left Arm"].Gun.Pos.CFrame
	Ball3.Position = HRP.Parent["Left Arm"].Gun.Pos.Position
	Ball3.Parent = vfxFolder
	Debris:AddItem(Ball3, 2 / speed)
	task.wait(0.001 / speed)

	local targetCFrame3 = CFrame.new(readyrand3)
	TS:Create(Ball3, TweenInfo.new(0.1 / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame3}):Play()
	task.wait(0.085 / speed)

	if not HRP or not HRP.Parent then return end
	local Endlemit3 = Folder:WaitForChild("Explosion_bereza"):Clone()
	Endlemit3.Position = readyrand3 + Vector3.new(0, 0.23, 0)
	Endlemit3.Parent = vfxFolder
	Debris:AddItem(Endlemit3, 2 / speed)
	VFX_Helper.EmitAllParticles(Endlemit3)
	Ball3.Cylinder.Transparency = 1

	task.wait(1 / speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end

module["Bunny Boom"] = function(HRP, target)
	local Folder = VFX.MIF["Bounty Bunny"].second
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.35 / speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local kosharPos = HRP.Parent["Right Arm"].koshar


	local handleModel = Instance.new("Model")
	handleModel.Name = "SwordClone"
	handleModel.Parent = vfxFolder
	Debris:AddItem(handleModel,0.88 / speed)
	local kosharCopy = kosharPos:Clone()
	kosharCopy.Anchored = true
	kosharCopy.CanCollide = false
	kosharCopy.Parent = handleModel
	UnitSoundEffectLib.playSound(HRP.Parent, 'Rockets' .. tostring(math.random(1,2)))

	for _, obj in kosharPos.Parent:GetChildren() do
		if obj:IsA("BasePart") and obj ~= kosharPos then
			if obj:FindFirstChildWhichIsA("WeldConstraint") or obj:FindFirstChildWhichIsA("Weld") then
				local partClone = obj:Clone()
				partClone.Anchored = true
				partClone.CanCollide = false
				partClone.Parent = handleModel
			end
		end
	end

	handleModel.PrimaryPart = kosharCopy

	kosharPos.Transparency = 1
	for _, part in kosharPos:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
	local startPos = HRP.Position
	local lookCFrame = CFrame.new(startPos, enemypos)
	handleModel:SetPrimaryPartCFrame(lookCFrame)



	local connection = HRP.Parent.Destroying:Once(function()
		handleModel:Destroy()
	end)

	local distance = (enemypos - startPos).Magnitude
	local endPos = lookCFrame.Position + lookCFrame.LookVector * distance
	local endCFrame = CFrame.new(endPos, endPos + lookCFrame.LookVector) * CFrame.Angles(0,0, 0)

	local End = CFrame.new(endCFrame.Position + Vector3.new(0, -0.5, 0))
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,4,0) )
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,4,0))
	VFX_Helper.SoundPlay(HRP, Folder.Sound)

	for i = 1, 100, 4 do
		local t = i / 100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)

		if not HRP or not HRP.Parent or not handleModel or not handleModel.PrimaryPart then

			return
		end

		handleModel:SetPrimaryPartCFrame(CFrame.new(NewPos))
		task.wait(0.01 / speed)
	end


	local explosions = Folder:WaitForChild("expolosions"):Clone()
	explosions.PrimaryPart = explosions:WaitForChild("mid")
	explosions:SetPrimaryPartCFrame(CFrame.new(enemypos + Vector3.new(0,-0.4,0) ))
	explosions.Parent = HRP
	Debris:AddItem(explosions, 3/speed)
	VFX_Helper.EmitAllParticles(explosions)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	task.wait(1.5 / speed)
	if not HRP or not HRP.Parent then return end
	kosharPos.Transparency = 0
	for _, part in kosharPos:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end

module["Easter Boom"] = function(HRP, target)
	local Folder = VFX.MIF["Bounty Bunny"].thrid
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local EGGS = HRP.Parent["Torso"]:WaitForChild("egss")
	local RightArm = HRP.Parent:WaitForChild("Right Arm")

	EGGS.Transparency = 1

	local eggClone = EGGS:Clone()
	eggClone.Anchored = false
	eggClone.CanCollide = false
	eggClone.Transparency = 0
	eggClone.Parent = vfxFolder

	eggClone.Size = eggClone.Size + Vector3.new(0.223, 0.321, 0.224)
	local connection = HRP.Parent.Destroying:Once(function()
		eggClone:Destroy()
	end)


	local attach = Instance.new("Motor6D")
	attach.Part0 = RightArm
	attach.Part1 = eggClone
	attach.C0 = CFrame.new(0, -0.5, 0) 
	attach.Parent = RightArm

	task.wait(0.7 / speed)

	attach:Destroy()
	eggClone.Anchored = true

	local startPos = RightArm.Position
	local lookCFrame = CFrame.new(startPos, enemypos)
	local distance = (enemypos - startPos).Magnitude
	local endPos = lookCFrame.Position + lookCFrame.LookVector * distance
	local endCFrame = CFrame.new(endPos, endPos + lookCFrame.LookVector)
	local End = CFrame.new(endCFrame.Position + Vector3.new(0, -0.5, 0))
	local Start = CFrame.new(startPos)
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,4,0))
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,4,0))
	VFX_Helper.SoundPlay(HRP, Folder.Sound)

	for i = 1, 100, 4 do
		local t = i / 100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		eggClone.CFrame = CFrame.new(NewPos)
		task.wait(0.01 / speed)
		if not HRP or not HRP.Parent then return end
	end

	local explosions = Folder:WaitForChild("Explosion"):Clone()
	explosions.Position = enemypos 
	explosions.Parent = HRP
	Debris:AddItem(explosions, 3 / speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	VFX_Helper.EmitAllParticles(explosions)

	eggClone:Destroy()

	task.wait(1.2 / speed)
	if not HRP or not HRP.Parent then return end
	EGGS.Transparency = 0

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local tweenService = game:GetService("TweenService")
function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end


local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end

module["Pistol and rocket"] = function(HRP, target)
	local Folder = VFX.Django.First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	task.wait(0.3 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	--VFX_Helper.SoundPlay(HRP, Folder.Sound)
	local GunShoot = Folder["Gun Shoot"]:Clone()
	GunShoot.CFrame = HRP.CFrame
	GunShoot.Parent = HRP.Parent
	local Attatchments = GunShoot.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed

	tween(GunShoot, timeToTravel, {Position = enemyPos})
	UnitSoundEffectLib.playSound(HRP.Parent, 'EliteBlaster1')
	task.delay(timeToTravel, function()
		GunShoot:Destroy()
	end)

	for i,v in Attatchments:GetChildren() do
		table.insert(tableEmit, v)
	end

	warn(tableEmit, "Particles for gun")

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.4 / speed, function()
			v.Enabled = false
		end)
	end
	HRP.Parent.Attacking.Value = false
end

module["Rockets"] = function(HRP, target)
	local Folder = VFX.Django.Second
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.3 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	--VFX_Helper.SoundPlay(HRP, Folder.Sound)
	local MRE = Folder["Multiple Rocket Explosion"]:Clone()
	MRE.CFrame = HRP.CFrame
	MRE.Parent = workspace.VFX
	local Attatchments = {}
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'Rockets' .. tostring(math.random(1,2)))

	for i, v in MRE:GetChildren() do
		table.insert(Attatchments, v)
	end




	tween(MRE, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
		MRE:Destroy()
	end)

	for i, value in Attatchments do
		for _, v in value:GetChildren() do
			table.insert(tableEmit, v)
		end 
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end
	HRP.Parent.Attacking.Value = false
end

module["Flamethrower"] = function(HRP, target)
	local Folder = VFX.Django.Third
	local speed = GameSpeed.Value
	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local flameVFX = Folder.Flamethrower:Clone()
	local emitters = {}

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local RightArm = HRP.Parent:FindFirstChild("Right Arm")
	UnitSoundEffectLib.playSound(HRP.Parent, 'Flamethrower')
	if not RightArm then return end

	flameVFX.CFrame = RightArm.CFrame
	flameVFX.Anchored = true
	flameVFX.Orientation += Vector3.new(0,-90,0)
	flameVFX.Parent = workspace.VFX

	local travelSpeed = 12
	local timeToTravel = getMag(RightArm.Position, enemyPos) / travelSpeed
	tween(flameVFX, timeToTravel, {Position = enemyPos})

	task.delay(timeToTravel, function()
		if flameVFX then
			flameVFX:Destroy()
		end
	end)

	for i, particle in flameVFX.Parent:GetDescendants() do
		if particle:IsA('ParticleEmitter') then
			table.insert(emitters, particle)
		end
	end

	warn(emitters)

	local displayed = false

	for _, emitter in emitters do
		emitter.Enabled = true
		task.delay(1 / speed, function() -- 0.15
			if not displayed then
				warn(emitters)
				displayed = true
			end

			if emitter then
				emitter.Enabled = false
			end
		end)
	end
	HRP.Parent.Attacking.Value = false
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local tweenService = game:GetService("TweenService")
local LightningSparks = require(rs.VFXModules.LightningBolt.LightningSparks)
local LightningModule = require(rs.VFXModules.LightningModule)

local GameSpeed = workspace.Info.GameSpeed

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


module["Saber Throw"] = function(HRP, target)
	local Folder = VFX["Grand Inquisitor"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local saber = Folder["Saber Throw"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'Rockets' .. tostring(math.random(1,2)))

	HRP.Parent.Attacking.Value = true

	tween(saber, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)


	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end

	for i,v in saber:GetChildren() do
		if v:IsA("Attachment") then
			continue
		else
			v.Enabled = true
		end
	end


	HRP.Parent.Attacking.Value = false
end


module["Force Lightning"] = function(HRP, target)
	local Folder = VFX["Grand Inquisitor"].Second
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local saber = Folder["Force Lightning"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'Thunder1')

	HRP.Parent.Attacking.Value = true

	tween(saber, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)


	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end

	for i,v in saber:GetChildren() do
		if v:IsA("Attachment") then
			continue
		else
			v.Enabled = true
		end
	end


	HRP.Parent.Attacking.Value = false
end


module["Jedai Explosion"] = function(HRP, target)
	local Folder = VFX["Grand Inquisitor"].Third
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.05/speed)
	local saber = Folder["AOE Attack"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 3.5
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')

	HRP.Parent.Attacking.Value = true

	tween(saber, timeToTravel, {Position = enemyPos})
	task.wait(0.1/speed)
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)


	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end
	task.wait(0.05/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	for i,v in saber:GetChildren() do
		if v:IsA("Attachment") then
			continue
		else
			v.Enabled = true
		end
	end

	HRP.Parent.Attacking.Value = false
end







return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Burst Shot"] = function(HRP, target)
	local speed = GameSpeed.Value
	local x = 0.3
	local Folder = VFX["Hans"].First
	local BallTemplate = Folder:WaitForChild("Ball")
	local vfxFolder = workspace:WaitForChild("VFX")

	task.wait(1 / speed)
	VFX_Helper.SoundPlay(HRP, Folder.First)

	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	for i = 1, 4 do
		if not HRP or not HRP.Parent then return end

		local Ball = BallTemplate:Clone()
		Ball.CFrame = HRP.Parent.Point.CFrame
		Ball.Position = HRP.Parent.Point.Position
		Ball.Parent = vfxFolder

		Debris:AddItem(Ball, 1 / speed)
		TS:Create(Ball, TweenInfo.new(0.13 / speed, Enum.EasingStyle.Linear), {
			Position = targetPosition
		}):Play()

		UnitSoundEffectLib.playSound(HRP.Parent, 'BlasterBurst1')

		task.wait(x / speed)
	end

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end


return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local tweenService = game:GetService("TweenService")
function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end
local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end

module["Pistol"] = function(HRP, target)

	local Folder = VFX.Hunter.First
	local speed = GameSpeed.Value

	task.wait(0.3 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local character = HRP.Parent
	local rightArm = character:FindFirstChild("Right Arm")
	if not rightArm then return end


	local Pistol = Folder.Pistol:Clone()
	Pistol.Anchored = false
	Pistol.CFrame = rightArm.CFrame * CFrame.new(0, -0.5, -0.6) * CFrame.Angles(0, math.rad(-90), 0)
	Pistol.Parent = character
	UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster' .. tostring(math.random(1,3)))

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rightArm
	weld.Part1 = Pistol
	weld.Parent = Pistol


	local Attachments = Pistol:FindFirstChild("Attachment")
	if not Attachments then return end

	for _, emitter in Attachments:GetChildren() do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = true
		end
	end


	task.delay(0.4 / speed, function()
		for _, emitter in Attachments:GetChildren() do
			if emitter:IsA("ParticleEmitter") then
				emitter.Enabled = false
			end
		end
		Pistol:Destroy()
	end)

	HRP.Parent.Attacking.Value = false
end




module["Electro Grenades"] = function(HRP, target)
	local Folder = VFX.Hunter.Second
	local speed = GameSpeed.Value
	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local flameVFX = Folder["Electro Grenades"]:Clone()
	local emitters = {}

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local RightArm = HRP.Parent:FindFirstChild("Right Arm")
	if not RightArm then return end

	flameVFX.CFrame = RightArm.CFrame
	flameVFX.Anchored = true
	flameVFX.Orientation += Vector3.new(0,-90,0)
	flameVFX.Parent = workspace.VFX

	local travelSpeed = 12
	local timeToTravel = getMag(RightArm.Position, enemyPos) / travelSpeed
	UnitSoundEffectLib.playSound(HRP.Parent, 'Flamethrower')

	tween(flameVFX, timeToTravel, {Position = enemyPos})

	task.delay(timeToTravel, function()
		if flameVFX then
			flameVFX:Destroy()
		end
	end)

	for i, particle in flameVFX.Parent:GetDescendants() do
		if particle:IsA('ParticleEmitter') then
			table.insert(emitters, particle)
		end
	end

	warn(emitters)

	local displayed = false

	for _, emitter in emitters do
		emitter.Enabled = true
		task.delay(1 / speed, function() -- 0.15
			if not displayed then
				warn(emitters)
				displayed = true
			end

			if emitter then
				emitter.Enabled = false
			end
			UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
		end)
	end
	HRP.Parent.Attacking.Value = false
end

module["Vibro Knife Throw"] = function(HRP, target)
	local Folder = VFX.Hunter.Third
	local speed = GameSpeed.Value
	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local RightArm = HRP.Parent:FindFirstChild("Right Arm")
	if not RightArm then return end

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local numberOfKnives = 3
	local spacing = 0.25
	local travelSpeed = 12

	for i = 1, numberOfKnives do
		UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
		local knifeVFX = Folder["Vibro Knife Throw"]:Clone()
		knifeVFX.CFrame = RightArm.CFrame * CFrame.new((i - 2) * spacing, 0, 0)
		knifeVFX.Anchored = true
		knifeVFX.Orientation += Vector3.new(0, -90, 0)
		knifeVFX.Parent = workspace.VFX

		local timeToTravel = getMag(RightArm.Position, enemyPos) / travelSpeed
		tween(knifeVFX, timeToTravel, {Position = enemyPos})

		task.delay(timeToTravel, function()
			if knifeVFX then
				knifeVFX:Destroy()
			end
		end)

		local emitters = {}
		for _, descendant in knifeVFX:GetDescendants() do
			if descendant:IsA('ParticleEmitter') then
				table.insert(emitters, descendant)
			end
		end

		for _, emitter in emitters do
			emitter.Enabled = true
			task.delay(0.4 / speed, function()
				if emitter then
					emitter.Enabled = false
				end
			end)
		end
	end
	HRP.Parent.Attacking.Value = false
end

return module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RocksModule = require(rs.Modules.RocksModule)
local StoryModeStats = require(rs.StoryModeStats)
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0
	return weld
end

local function emit(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 10

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end

module["Charge Down"] = function(HRP, target)
	local Folder = VFX["Ninth Sister"].First
	local speed = GameSpeed.Value * 16

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	if not HRP or not HRP.Parent then return end

	local mag = getMag(HRP.Position, target:GetPivot().Position)
	tween(HRP, mag/speed, {CFrame = CFrame.new(enemypos)})

	HRP.Parent.Attacking.Value = true

	local vfx = Folder["Charge Down"]:Clone()
	vfx.Parent = workspace.VFX

	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	UnitSoundEffectLib.playSound(HRP.Parent, 'Punch' .. tostring(math.random(1,3)))

	local weld = connect(vfx, HRP, CFrame.new(0,-.5,0))

	for _, particle in vfx:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = true
	end

	task.wait(mag / speed) -- Fully wait for the tween

	if not HRP or not HRP.Parent then return end

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame


	for _, particle in vfx:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = false
	end

	HRP.Parent.Attacking.Value = false

	for _, track in HRP.Parent.Humanoid.Animator:GetPlayingAnimationTracks() do
		if track.Animation.AnimationId == "128527655134187" or track.Animation.AnimationId == "rbxassetid://128527655134187" or track.Animation.AnimationId == "132379076203645"  or track.Animation.AnimationId == "rbxassetid://132379076203645" then
			warn("Stopping track")
			track:Stop(.1)
		end
	end

	Debris:AddItem(vfx, 2)
end

module["Force Choke"] = function(HRP, target)
	warn("Force Choke")
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX["Ninth Sister"].Second
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(0.6/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		for _, folder in folders do
			for i, mob in rs.Enemies[folder]:GetChildren() do
				if mob.Name == MobName then
					Mob = mob:Clone()
				end
			end
		end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end

	local forceChoke = anikinFolder["Force Choke"]:Clone()
	warn(anikinFolder["Force Choke"].Parent)
	forceChoke.Parent = workspace.VFX

	connect(forceChoke, Mob.HumanoidRootPart, CFrame.new(0,-1,0))

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end

	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = false
		end
	end

	Debris:AddItem(forceChoke, 2)

	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end



module["Force Slam"] = function(HRP: BasePart, target: Model)
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX["Ninth Sister"].Third
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(1.1/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		for _, folder in folders do
			for i, mob in rs.Enemies[folder]:GetChildren() do
				if mob.Name == MobName then
					Mob = mob:Clone()
				end
			end
		end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end

	local forceChoke = anikinFolder["Force Slam"]:Clone()
	forceChoke.Parent = workspace.VFX

	connect(forceChoke, Mob.HumanoidRootPart, CFrame.new(0,-1,0))

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end

	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = false
		end
	end

	Debris:AddItem(forceChoke, 2)

	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


return module
local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = game.Workspace.Info.GameSpeed

module["Palpotin light"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Palpotin.Folder
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local lig1 = Folder:WaitForChild("Light"):Clone()
	lig1.CFrame = HRP.Parent["Right Arm"].Pos22.CFrame
	lig1.Parent = vfxFolder
	Debris:AddItem(lig1,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Pos22
	weld.Part1 = lig1
	weld.Parent = lig1
	local light = Folder:WaitForChild("Light"):Clone()
	light.CFrame = HRP.Parent["Left Arm"].Pos.CFrame
	light.Parent = vfxFolder
	Debris:AddItem(light,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Pos
	weld.Part1 = light
	weld.Parent = light

	VFX_Helper.OnAllParticles(lig1)
	VFX_Helper.OnAllParticles(light)

	task.wait(0.6/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRP.CFrame * CFrame.new(0, 0, -Range)).Position

	local starsemit = Folder:WaitForChild("Electrigemit"):Clone()
	starsemit.CFrame = HRP.CFrame 
	starsemit.Parent = HRP.Parent
	VFX_Helper.OnAllParticles(starsemit)
	Debris:AddItem(starsemit,3/speed)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	TS:Create(starsemit,TweenInfo.new(0.25/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	VFX_Helper.OffAllParticles(lig1)
	VFX_Helper.OffAllParticles(light)
	task.wait(0.22/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OffAllParticles(starsemit)


	HRP.Parent.Attacking.Value = false
end

module["Doom Bolt"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Palpotin.Second
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local lig1 = Folder:WaitForChild("Light"):Clone()
	lig1.CFrame = HRP.Parent["Right Arm"].Pos22.CFrame
	lig1.Parent = vfxFolder
	Debris:AddItem(lig1,3/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Pos22
	weld.Part1 = lig1
	weld.Parent = lig1
	local light = Folder:WaitForChild("Light"):Clone()
	light.CFrame = HRP.Parent["Left Arm"].Pos.CFrame
	light.Parent = vfxFolder
	Debris:AddItem(light,3/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Pos
	weld.Part1 = light
	weld.Parent = light


	VFX_Helper.OnAllParticles(lig1)
	VFX_Helper.OnAllParticles(light)
	task.wait(0.5/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local startemit = Folder:WaitForChild("Wind"):Clone()
	startemit.CFrame = HRP.CFrame +Vector3.new(0,-0.88,0)
	startemit.Parent = vfxFolder
	Debris:AddItem(startemit,2/speed)
	VFX_Helper.EmitAllParticles(startemit)

	TS:Create(HRP,TweenInfo.new(1.5/speed, Enum.EasingStyle.Linear),{CFrame = HRP.CFrame * CFrame.new(0, 8, 0)}):Play()
	task.wait(1.3/speed)
	if not HRP or not HRP.Parent then return end

	local boolt = Folder:WaitForChild("PartUp"):Clone()
	boolt.CFrame = HRP.Parent["Right Arm"].Pos22.CFrame
	boolt.Parent = vfxFolder
	Debris:AddItem(boolt,3/speed)

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	local direction = (enemypos - boolt.Position).Unit
	boolt.CFrame = CFrame.lookAt(boolt.Position, boolt.Position + direction)
	VFX_Helper.EmitAllParticles(boolt)
	TS:Create(boolt, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {Position = enemypos + Vector3.new(0, 0, 0)}):Play()
	task.spawn(function()
		task.wait(0.1/speed)
		VFX_Helper.OffAllParticles(lig1)
		VFX_Helper.OffAllParticles(light)
	end)

	local emitlig = Folder:WaitForChild("PartDown"):Clone()
	emitlig.Position = enemypos + Vector3.new(0,-1,0)
	emitlig.Parent = vfxFolder
	Debris:AddItem(emitlig,2/speed)
	task.wait(0.1/speed)
	VFX_Helper.EmitAllParticles(emitlig)
	task.wait(0.7/speed)
	local UPemit = Folder:WaitForChild("teleport"):Clone()
	UPemit.CFrame = HRP.CFrame
	UPemit.Parent = vfxFolder
	Debris:AddItem(UPemit,2/speed)
	VFX_Helper.EmitAllParticles(UPemit)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local endlemit = Folder:WaitForChild("Endlemit"):Clone()
	endlemit.CFrame = HRP.CFrame
	endlemit.Parent = vfxFolder
	Debris:AddItem(endlemit,2/speed)
	task.wait(0.1/speed)
	VFX_Helper.EmitAllParticles(endlemit)

	HRP.Parent.Attacking.Value = false
end

module["Emperor Rage"] = function(HRP, target)
	local Folder = VFX.Palpotin.Thrid
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	VFX_Helper.SoundPlay(HRP,Folder:WaitForChild('Sound'))

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	task.wait(0.2/speed)

	local lighthand = Folder:WaitForChild("lightemit"):Clone()
	lighthand.CFrame = HRP.Parent["Left Arm"].Pos.CFrame
	lighthand.Parent = HRP
	Debris:AddItem(lighthand,3/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Pos
	weld.Part1 = lighthand
	weld.Parent = lighthand
	VFX_Helper.OnAllParticles(lighthand)

	local Handle = HRP.Parent["Right Arm"]:FindFirstChild("Handle")
	Handle.Transparency = 0
	local HandlePart = Handle:FindFirstChild("Part")
	if HandlePart then
		HandlePart.Transparency = 0
		local Trail = HandlePart:FindFirstChild("Trail")
		if Trail then
			Trail.Enabled = true
		end
	end

	if not HRP or not HRP.Parent then return end

	task.wait(0.625/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	task.wait(0.625/speed)
	if not HRP or not HRP.Parent then return end

	local AOEEmit = Folder:WaitForChild("ExplosionSlash"):Clone()
	AOEEmit.Position = enemypos
	AOEEmit.Parent = HRP
	Debris:AddItem(AOEEmit,5/speed)
	local bekemiter = Folder:WaitForChild("teleport"):Clone()
	bekemiter.CFrame = HRP.CFrame
	bekemiter.Parent = vfxFolder
	Debris:AddItem(bekemiter,2/speed)
	VFX_Helper.EmitAllParticles(bekemiter)

	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	TS:Create(HRP, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + enemyCFrame.LookVector}):Play()

	VFX_Helper.OnAllParticles(AOEEmit)

	local connection = HRP.Parent.Destroying:Once(function()
		AOEEmit:Destroy()
	end)

	if not HRP or not HRP.Parent then return end
	for i = 1,25 do
		if not HRP or not HRP.Parent then return end
		local randomOffset = Vector3.new(math.random(-8, 8),math.random(1, 1.2), math.random(-8, 8))
		local randomPos = enemypos + randomOffset
		HRP.CFrame = CFrame.new(randomPos)
		task.wait(1.6 / 10/speed) 
	end
	HRP.CFrame = CFrame.new(enemypos + Vector3.new(0,0,2))
	VFX_Helper.OffAllParticles(AOEEmit)

	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	local Trail = HandlePart:FindFirstChild("Trail")
	if Trail then
		Trail.Enabled = false
	end
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(lighthand)

	Handle.Transparency = 1
	HandlePart.Transparency = 1
	task.wait(0.2/speed)
	local bekemit = Folder:WaitForChild("teleport"):Clone()
	bekemit.CFrame = HRP.CFrame
	bekemit.Parent = vfxFolder
	Debris:AddItem(bekemit,2/speed)
	VFX_Helper.EmitAllParticles(bekemit)

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

return module
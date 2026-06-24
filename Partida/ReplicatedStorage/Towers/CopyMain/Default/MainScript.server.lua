local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')
local ErrorModule = require(ServerStorage.ServerModules.ErrorService)
local Upgrades = require(ReplicatedStorage.Upgrades)

local TowerSpecialisation = require(ServerStorage.ServerModules.TowerSpecialisation)

local TowerFunctions = require(game.ServerScriptService.Main.TowerFunctions)
local upgradesModule = require(game.ReplicatedStorage.Upgrades)
local UnitName = upgradesModule[script.Parent.Name]
local TowerGUI = ReplicatedStorage["TOWER BUFF GUI"]
local TowerInfo = require(game.ReplicatedStorage.Modules.Helpers.TowerInfo)

local function mag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function giveMoneyToOwner(tower)
	local ownerName = tower.Config.Owner.Value
	local player = game.Players:FindFirstChild(ownerName)
	if player then
		local currentTowerUpgrade = tower.Config.Upgrades.Value

		local upgradeStats = UnitName["Upgrades"][script.Parent.Config.Upgrades.Value]
		local moneyToGive
		if currentTowerUpgrade <= #upgradeStats then
			moneyToGive = upgradeStats[currentTowerUpgrade].Money
		else
			moneyToGive = upgradeStats.Money
		end

		if moneyToGive then
			if tower.Config:FindFirstChild("Shiny").Value then moneyToGive *= 1.15 end

			player.Money.Value += moneyToGive 

		end
	end
end

local Duplicates = {}
local EchoCounter = 0
local SupportGuiConnections = setmetatable({}, { __mode = "k" })

local function setupSupportGui(Model: Model, buffText: string, upgradeName: string)
	EchoCounter += 1

	local config = Model:FindFirstChild("Config")
	if not config then return end

	if not config:FindFirstChild("TowerNumber") then
		local towerNum = Instance.new("IntValue")
		towerNum.Name = "TowerNumber"
		towerNum.Value = EchoCounter
		towerNum.Parent = config
	end

	local head = Model:FindFirstChild("Head")
	local num = config:FindFirstChild("Upgrades")
	if not head or not num then return end

	local NewGUI = head:FindFirstChild(TowerGUI.Name)
	if not NewGUI then
		NewGUI = TowerGUI:Clone()
		NewGUI.Parent = head
	end

	local frame = NewGUI:FindFirstChild("Frame")
	if not frame then
		warn(`Support GUI "{TowerGUI.Name}" is missing Frame for {Model.Name}`)
		return
	end

	frame.Buffing.Text = buffText
	frame.Percent.Text = tostring(Upgrades[upgradeName].Upgrades[num.Value].Damage) .. "%"

	if SupportGuiConnections[Model] then
		SupportGuiConnections[Model]:Disconnect()
	end

	SupportGuiConnections[Model] = num.Changed:Connect(function()
		if not NewGUI.Parent then return end

		local currentFrame = NewGUI:FindFirstChild("Frame")
		if not currentFrame then return end

		currentFrame.Percent.Text = tostring(Upgrades[upgradeName].Upgrades[num.Value].Damage) .. "%"
	end)
end

local SupportFunctions = {
	["Echo"] = function(Model : Model, upgradestats)
		setupSupportGui(Model, "Type Buff: DMG", "Echo")
	end,


	["Tech"] = function(Model : Model, upgradestats)
		setupSupportGui(Model, "Type Buff: Cooldown", "Tech")
	end,


	["Mas Med"] = function(Model : Model, upgradestats)
		setupSupportGui(Model, "Type Buff: DMG", "Mas Med")
	end,

	["Captain"] = function(Model : Model, upgradestats)
		setupSupportGui(Model, "Type Buff: DMG", "Captain")
	end,

	["Colonel"] = function(Model : Model, upgradestats)
		setupSupportGui(Model, "Type Buff: Range", "Colonel")
	end,

	["Grand Moth Tarin"] = function(Model : Model, upgradestats)
		setupSupportGui(Model, "Type Buff: DMG", "Grand Moth Tarin")
	end,
}

local functions = {
	['Ground'] = function(upgradeStats)
		if upgradeStats.Damage <= 0 then return end

		if upgradeStats.Money then
			if not script.Parent:FindFirstChild("LastMoneyWave") then
				local waveVal = Instance.new("IntValue")
				waveVal.Name = "LastMoneyWave"
				waveVal.Value = 0
				waveVal.Parent = script.Parent
			end

			local wave = workspace.Info:FindFirstChild("Wave")
			local lastGivenWave = script.Parent:FindFirstChild("LastMoneyWave")
			if wave and lastGivenWave and wave.Value > lastGivenWave.Value then
				lastGivenWave.Value = wave.Value
				giveMoneyToOwner(script.Parent)
			end
		end

		local target = nil
		repeat
			task.wait(0.1)
			target = TowerFunctions.FindTarget(script.Parent)
		until target ~= nil

		if script.Parent.Animations:FindFirstChild(upgradeStats.AnimName) then
			game.ReplicatedStorage.Events.AnimateTower:FireAllClients(script.Parent, upgradeStats.AnimName, target)
		end

		local newTargetPosition = Vector3.new(target.HumanoidRootPart.Position.X, script.Parent.TowerBasePart.Position.Y, target.HumanoidRootPart.Position.Z)
		local targetCFrame = CFrame.lookAt(script.Parent.TowerBasePart.Position, newTargetPosition)
		script.Parent:PivotTo(targetCFrame)

		game.ReplicatedStorage.Events.VFX_Remote:FireAllClients({UnitName.Name, upgradeStats.AttackName}, script.Parent.HumanoidRootPart, target)

		TowerFunctions.DamageFunction(script.Parent, target)

		local attackDuration = 0
		for i, v in upgradeStats.MultiDamageDelays do
			attackDuration += v
		end
		task.wait(TowerInfo.GetCooldown(script.Parent))
	end,

	["Hybrid"] = function(upgradeStats)
		local target = nil
		repeat
			task.wait(0.1)
			target = TowerFunctions.FindTarget(script.Parent)
		until target ~= nil

		if script.Parent.Animations:FindFirstChild(upgradeStats.AnimName) then
			game.ReplicatedStorage.Events.AnimateTower:FireAllClients(script.Parent, upgradeStats.AnimName, target)
		end

		local currentPivot = script.Parent:GetPivot()
		local newTargetPosition = Vector3.new(target.HumanoidRootPart.Position.X, currentPivot.Position.Y, target.HumanoidRootPart.Position.Z) 
		local targetCFrame = CFrame.lookAt(currentPivot.Position, newTargetPosition)
		script.Parent:PivotTo(targetCFrame)

		game.ReplicatedStorage.Events.VFX_Remote:FireAllClients({UnitName.Name,upgradeStats.AttackName},script.Parent.HumanoidRootPart,target)

		TowerFunctions.DamageFunction(script.Parent,target)

		local attackDuration = 0
		if upgradeStats.MultiDamageDelays then
			for i, v in upgradeStats.MultiDamageDelays do
				attackDuration += v
			end
		end

		task.wait(TowerInfo.GetCooldown(script.Parent))
	end,
	['Support'] = function(upgradeStats)
		SupportFunctions[script.Parent.Name](script.Parent, upgradeStats)
		--repeat
		--	task.wait(0.1)
		--	unit = TowerFunctions.FindTarget(script.Parent)
		--until unit ~= nil
		--print(unit)

		if upgradeStats.AnimName then
			game.ReplicatedStorage.Events.AnimateTower:FireAllClients(script.Parent, upgradeStats.AnimName)
		end

		game.ReplicatedStorage.Events.VFX_Remote:FireAllClients({UnitName.Name,upgradeStats.AttackName},script.Parent.HumanoidRootPart)

		--TowerFunctions.DamageFunction(script.Parent,unit)
		local BuffType = upgradeStats.AOEType
		local amount = upgradeStats.Damage
		local range = upgradeStats.Range

		for i,v in workspace.Towers:GetChildren() do
			if v == script.Parent then continue end

			if mag(script.Parent:GetPivot().Position, v:GetPivot().Position) < range then
				TowerSpecialisation.applyBuff(script.Parent, v, BuffType, amount)
			end
		end

		task.wait(TowerInfo.GetCooldown(script.Parent))
	end,

}

while task.wait() do
	--ErrorModule.wrap(main)
	local upgradeStats = UnitName["Upgrades"][script.Parent.Config.Upgrades.Value]
	functions[upgradeStats.Type](upgradeStats)
end

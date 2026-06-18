--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Player & Workspace
local player = Players.LocalPlayer
local info = workspace:WaitForChild("Info")
local wave = info:WaitForChild("Wave")
local towers = workspace:WaitForChild("Towers")

--// UI
local dialogueFrame = script.Parent.Parent:WaitForChild("Dialogue")
local contents = dialogueFrame:WaitForChild("Contents")
local bgText = contents:WaitForChild("Bg_Text")
local optionsFrame = contents:WaitForChild("Options")
local continueButton = optionsFrame:WaitForChild("Continue")

local progressLabel = bgText:FindFirstChild("EventsLabel")

local function createProgressLabel()
	local label = Instance.new("TextLabel")
	label.Name = "EventsLabel"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.fromScale(0.5, 1)
	label.Size = UDim2.fromScale(0.34, 0.18)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.25
	label.Visible = false
	label.ZIndex = 4
	label.Parent = bgText
	return label
end

if not progressLabel then
	progressLabel = createProgressLabel()
end

local function setProgressVisible(isVisible)
	if progressLabel then
		progressLabel.Visible = isVisible
	end
end

local function setProgressText(text)
	if progressLabel then
		progressLabel.Text = text
	end
end

local function resetProgress()
	setProgressText("")
	setProgressVisible(false)
end

local function getTowerConfig(tower)
	if not tower then
		return nil
	end

	local config = tower:FindFirstChild("Config")
	local owner = config and config:FindFirstChild("Owner")
	local upgrades = config and config:FindFirstChild("Upgrades")

	if not config or not owner then
		return nil
	end

	return config, owner, upgrades
end

local function isPlayerTower(tower)
	local _, owner = getTowerConfig(tower)
	return owner and owner.Value == player.Name
end

local function countPlayerTowers()
	local total = 0

	for _, tower in ipairs(towers:GetChildren()) do
		if isPlayerTower(tower) then
			total += 1
		end
	end

	return total
end

local function countPlayerUpgradeLevels()
	local total = 0

	for _, tower in ipairs(towers:GetChildren()) do
		local _, owner, upgrades = getTowerConfig(tower)
		if owner and owner.Value == player.Name and upgrades then
			total += math.max(tonumber(upgrades.Value) or 0, 0)
		end
	end

	return total
end

local function waitForValueAtLeast(valueObject, targetValue)
	if valueObject.Value >= targetValue then
		return
	end

	repeat
		valueObject:GetPropertyChangedSignal("Value"):Wait()
	until valueObject.Value >= targetValue
end

local tutorialEvents = {}

function tutorialEvents.Continue(callback)
	continueButton.Visible = true
	continueButton.Activated:Wait()
	continueButton.Visible = false
	callback()
end

function tutorialEvents.WaveStart(callback)
	waitForValueAtLeast(wave, 1)
	callback()
end

function tutorialEvents.TowersPlaced(callback)
	setProgressVisible(true)

	while true do
		local placedCount = countPlayerTowers()
		setProgressText(string.format("%d/3", math.clamp(placedCount, 0, 3)))

		if placedCount >= 3 then
			break
		end

		task.wait(0.1)
	end

	resetProgress()
	callback()
end

function tutorialEvents.TowerPlaced(callback)
	setProgressVisible(true)

	while true do
		local placedCount = countPlayerTowers()
		setProgressText(string.format("%d/1", math.clamp(placedCount, 0, 1)))

		if placedCount >= 1 then
			break
		end

		task.wait(0.1)
	end

	resetProgress()
	callback()
end

function tutorialEvents.EnoughMoney(callback)
	local upgradesModule = require(ReplicatedStorage:WaitForChild("Upgrades"))
	local playerMoney = player:FindFirstChild("Money")

	if not playerMoney then
		warn("[TutorialEvents.EnoughMoney] Money stat not found.")
		callback()
		return
	end

	while true do
		for _, tower in ipairs(towers:GetChildren()) do
			local config, owner, upgrades = getTowerConfig(tower)
			if config and owner and owner.Value == player.Name and upgrades then
				local towerUpgradeData = upgradesModule[tower.Name]
				local nextUpgrade = towerUpgradeData
					and towerUpgradeData.Upgrades
					and towerUpgradeData.Upgrades[(upgrades.Value or 0) + 1]

				if not nextUpgrade or playerMoney.Value >= (tonumber(nextUpgrade.Price) or math.huge) then
					callback()
					return
				end
			end
		end

		task.wait(0.1)
	end
end

function tutorialEvents.TowerUpgraded(callback)
	setProgressVisible(true)

	while true do
		local upgradedCount = countPlayerUpgradeLevels()
		setProgressText(string.format("%d/1", math.clamp(upgradedCount, 0, 1)))

		if upgradedCount >= 1 then
			break
		end

		task.wait(0.1)
	end

	resetProgress()
	callback()
end

function tutorialEvents.Boss(callback)
	local bossSpawnEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Client"):WaitForChild("BossSpawn")

	if bossSpawnEvent:IsA("RemoteEvent") then
		bossSpawnEvent.OnClientEvent:Wait()
	elseif bossSpawnEvent:IsA("BindableEvent") then
		bossSpawnEvent.Event:Wait()
	end

	callback()
end

function tutorialEvents.Defeated(callback)
	if not info.Victory.Value then
		repeat
			info.Victory:GetPropertyChangedSignal("Value"):Wait()
		until info.Victory.Value == true
	end

	callback()
end

function tutorialEvents.Finished(callback)
	task.wait(6)
	callback()
end

return tutorialEvents

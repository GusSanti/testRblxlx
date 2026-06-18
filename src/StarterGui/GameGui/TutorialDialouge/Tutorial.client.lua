--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Info = workspace:WaitForChild("Info")

--// Dependencies
local tutorialSteps = require(script.TutotrialSteps)
local events = require(script.Events)

--// UI
local player = Players.LocalPlayer
local dialogueFrame = script.Parent:WaitForChild("Dialogue")
local dialogueScale = dialogueFrame:FindFirstChildOfClass("UIScale")
local contents = dialogueFrame:WaitForChild("Contents")
local bgText = contents:WaitForChild("Bg_Text")
local label = bgText:WaitForChild("TextLabel")

local textThread = nil
local gameOverConnection = nil

local lostText = "Oh no! You ended up losing, no worries, you can try again."

local function animateText(text: string)
	local characters = string.split(text or "", "")
	label.Text = ""

	for index = 1, #characters do
		label.Text ..= characters[index]
		task.wait(0.01)
	end
end

local function tween(instance: Instance, tweenInfo: TweenInfo, props: {[string]: any})
	local tweenObject = TweenService:Create(instance, tweenInfo, props)
	tweenObject:Play()
	return tweenObject
end

local function stopTextThread()
	if textThread then
		pcall(task.cancel, textThread)
		textThread = nil
	end
end

local function showStepText(text: string)
	stopTextThread()
	textThread = task.spawn(function()
		animateText(text)
	end)
end

local function shouldSkipTutorial()
	return Info.Raid.Value == true
		or Info.Infinity.Value == true
		or Info.Event.Value == true
		or Info.ChallengeNumber.Value ~= -1
end

local function RunTutorial()
	if shouldSkipTutorial() then
		return
	end

	dialogueFrame.Visible = true

	local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential)
	if dialogueScale then
		tween(dialogueScale, tweenInfo, {Scale = 1})
	end

	local lost = false

	if gameOverConnection then
		gameOverConnection:Disconnect()
	end

	gameOverConnection = Info.GameOver:GetPropertyChangedSignal("Value"):Connect(function()
		if Info.GameOver.Value and not Info.Victory.Value then
			lost = true
			showStepText(lostText)

			task.delay(2, function()
				if dialogueScale then
					tween(dialogueScale, tweenInfo, {Scale = 0})
				end
			end)
		end
	end)

	for stepNum, step in ipairs(tutorialSteps) do
		if Info.Victory.Value or lost then
			break
		end

		if step.callback then
			pcall(step.callback)
		end

		showStepText(step.text)

		local waitFunc = events[step.waitFor]
		if waitFunc then
			waitFunc(function()
				warn("Completed step: " .. stepNum)
			end)
		else
			warn("Missing tutorial event for: " .. tostring(step.waitFor))
		end
	end

	if gameOverConnection then
		gameOverConnection:Disconnect()
		gameOverConnection = nil
	end

	if lost then
		return
	end

	if dialogueScale then
		tween(dialogueScale, tweenInfo, {Scale = 0})
	end
	warn("[TUTORIAL]: Completed :)")
end

if player:GetAttribute("TutorialWin") then
	return
end

repeat
	task.wait(0.1)
until player:FindFirstChild("DataLoaded")

local tutorialModeCompleted = player:FindFirstChild("TutorialModeCompleted")
local tutorialWinValue = player:FindFirstChild("TutorialWin")

if tutorialModeCompleted and tutorialModeCompleted.Value == true and tutorialWinValue and not tutorialWinValue.Value then
	RunTutorial()
end

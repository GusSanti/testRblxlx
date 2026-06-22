-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- CONSTANTS
local SKIP_CENTER_POSITION = UDim2.fromScale(0.5, 0.5)
local SKIP_HIDDEN_POSITION = UDim2.fromScale(0.5, -0.5)

-- VARIABLES
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local SkipUI = playerGui:WaitForChild("NewUI"):WaitForChild("Skip")

local UIHandler = require(ReplicatedStorage.Modules.Client.UIHandler)

-- FUNCTIONS
local function getReplicatedAutoSkipEnabled()
	local settings = player:FindFirstChild("Settings")
	local autoSkip = settings and settings:FindFirstChild("AutoSkip")
	return autoSkip and autoSkip.Value == true or false
end

local function hasAutoSkipEnabled()
	local localEnabled = SkipUI:GetAttribute("AutoSkipLocalEnabled")
	if typeof(localEnabled) == "boolean" then
		return localEnabled == true
	end

	return getReplicatedAutoSkipEnabled()
end

local function syncAutoSkipLocalEnabled()
	local enabled = getReplicatedAutoSkipEnabled()
	if SkipUI:GetAttribute("AutoSkipLocalEnabled") ~= enabled then
		SkipUI:SetAttribute("AutoSkipLocalEnabled", enabled)
	end
end

local function hideWaveSkipUI()
	if SkipUI:GetAttribute("InteractionContext") ~= "WaveSkip" then
		return false
	end

	SkipUI:SetAttribute("InteractionContext", nil)
	SkipUI.Position = SKIP_HIDDEN_POSITION
	SkipUI.Visible = false
	return true
end

local function requestAutoSkipVote()
	task.spawn(function()
		pcall(function()
			ReplicatedStorage.Functions.VoteForSkip:InvokeServer("ClientAutoSkipFallback")
		end)
	end)
end

local function tryHandleWaveSkipAutoVote()
	if not SkipUI.Visible or SkipUI:GetAttribute("InteractionContext") ~= "WaveSkip" then
		return false
	end

	if not hasAutoSkipEnabled() then
		return false
	end

	requestAutoSkipVote()
	hideWaveSkipUI()
	return true
end

-- INIT
repeat task.wait() until player:FindFirstChild("DataLoaded")

syncAutoSkipLocalEnabled()

local settings = player:FindFirstChild("Settings")
if settings then
	local autoSkip = settings:FindFirstChild("AutoSkip")
	if autoSkip then
		autoSkip:GetPropertyChangedSignal("Value"):Connect(syncAutoSkipLocalEnabled)
	end

	settings.ChildAdded:Connect(function(child)
		if child.Name == "AutoSkip" and child:IsA("BoolValue") then
			child:GetPropertyChangedSignal("Value"):Connect(syncAutoSkipLocalEnabled)
			syncAutoSkipLocalEnabled()
		end
	end)
end

SkipUI:GetAttributeChangedSignal("AutoSkipLocalEnabled"):Connect(function()
	tryHandleWaveSkipAutoVote()
end)

task.delay(0.1, function()
	tryHandleWaveSkipAutoVote()
end)

ReplicatedStorage.Events.SkipGui.OnClientEvent:Connect(function(visible, secondArgument: {})
	if secondArgument then
		if secondArgument.Yes then
			local voteText = SkipUI:FindFirstChild("PlayersVoteText", true)
			if voteText then
				voteText.Text = `{secondArgument.Yes}/{math.ceil(#Players:GetPlayers())}`
			end
			UIHandler.PlaySound("Skip")
			return
		end

		if secondArgument.Required then
			local voteText = SkipUI:FindFirstChild("PlayersVoteText", true)
			if voteText then
				voteText.Text = `{0}/{math.ceil(#Players:GetPlayers())}`
			end
		end
	end

	if visible == false then
		hideWaveSkipUI()
		return
	end

	if visible ~= true then
		return
	end

	SkipUI.Visible = visible

	if visible == true then
		SkipUI:SetAttribute("InteractionContext", "WaveSkip")

		if tryHandleWaveSkipAutoVote() then
			return
		end

		SkipUI.Position = SKIP_HIDDEN_POSITION
		TweenService:Create(SkipUI, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
			Position = SKIP_CENTER_POSITION,
		}):Play()

		if UserInputService.GamepadEnabled then
			local btnToSelect = SkipUI:IsA("GuiButton") and SkipUI or SkipUI:FindFirstChildWhichIsA("GuiButton", true)
			if btnToSelect then
				GuiService.SelectedObject = btnToSelect
			end
		end
	end
end)

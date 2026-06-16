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
local function hasAutoSkipEnabled()
	local settings = player:FindFirstChild("Settings")
	local autoSkip = settings and settings:FindFirstChild("AutoSkip")
	return autoSkip and autoSkip.Value == true
end

-- INIT
repeat task.wait() until player:FindFirstChild("DataLoaded")

ReplicatedStorage.Events.SkipGui.OnClientEvent:Connect(function(visible, secondArgument: {})
	if hasAutoSkipEnabled() and visible ~= false then
		SkipUI:SetAttribute("InteractionContext", nil)
		SkipUI.Position = SKIP_HIDDEN_POSITION
		SkipUI.Visible = false
		return
	end

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
		SkipUI:SetAttribute("InteractionContext", nil)
		SkipUI.Position = SKIP_HIDDEN_POSITION
		SkipUI.Visible = false
		return
	end

	SkipUI.Visible = visible

	if visible == true then
		SkipUI:SetAttribute("InteractionContext", "WaveSkip")
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

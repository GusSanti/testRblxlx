-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- CONSTANTS

-- VARIABLES
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Referenciando a nova UI que configuramos anteriormente
local SkipUI = playerGui:WaitForChild("NewUI"):WaitForChild("Skip")

local UIHandler = require(ReplicatedStorage.Modules.Client.UIHandler)

-- FUNCTIONS
local function hasAutoSkipEnabled()
	local settings = player:FindFirstChild("Settings")
	local autoSkip = settings and settings:FindFirstChild("AutoSkip")
	return autoSkip and autoSkip.Value == true
end

-- INIT
repeat task.wait() until player:FindFirstChild('DataLoaded')

ReplicatedStorage.Events.SkipGui.OnClientEvent:Connect(function(visible, SecondArgument : {})
	if hasAutoSkipEnabled() and visible ~= false then
		SkipUI.Visible = false
		return
	end

	if SecondArgument then
		if SecondArgument.Yes then
			-- Verifica se o texto existe antes de alterar para evitar erros na nova UI
			local voteText = SkipUI:FindFirstChild("PlayersVoteText", true)
			if voteText then
				voteText.Text = `{SecondArgument.Yes}/{math.ceil(#Players:GetPlayers()) }`
			end
			UIHandler.PlaySound("Skip")
			return
		end

		if SecondArgument.Required then
			local voteText = SkipUI:FindFirstChild("PlayersVoteText", true)
			if voteText then
				voteText.Text = `{0}/{math.ceil(#Players:GetPlayers())}`
			end
		end
	end

	SkipUI.Visible = visible

	if visible == true then
		-- A animação agora ocorre na nova UI
		TweenService:Create(SkipUI, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.786, 0, 0.34, 0)}):Play()

		if UserInputService.GamepadEnabled then
			local btnToSelect = SkipUI:IsA("GuiButton") and SkipUI or SkipUI:FindFirstChildWhichIsA("GuiButton", true)
			if btnToSelect then
				GuiService.SelectedObject = btnToSelect
			end
		end
	end
end)

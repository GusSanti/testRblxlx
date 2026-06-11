local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Simplebar = require(ReplicatedStorage.Modules.Client.Simplebar)
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

repeat task.wait() until Player:FindFirstChild('DataLoaded')

local conn = nil

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

conn = UserInputService.InputBegan:Connect(function(key, gp)
	if not gp and not _G.CurrentlyOpen then
		if key.KeyCode == Enum.KeyCode.Tab then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
			_G.PlayerlistEnabled = true
			conn:Disconnect()
			conn = nil
		end
	end
end)


local UIHandler = require(ReplicatedStorage.Modules.Client.UIHandler)
local PlayerGui = Player:WaitForChild('PlayerGui')

local size = 0.7
local XSize = 85

local GameUI = PlayerGui:WaitForChild('GameGui')


local settingsFrame = GameUI:WaitForChild('Settings'):WaitForChild('SettingsFrame')
local name = 'Settings'
local button = Simplebar.createButton(name)
	:singleBind(true)
	--:setColor(script[name]) -- white by default
	:setImage('rbxassetid://131059016517582')
	:setSize(size)
	:setSide('Left')
	:setCustomXSize(44)
	--:bindToFrame(CoreUI:WaitForChild('DailyReward'):WaitForChild('DailyRewardFrame'))
	:bindToFrame(settingsFrame)

button:bindEvent(true, function()
	settingsFrame.Visible = true
end)

button:bindEvent(false, function()
	if typeof(_G.CloseSettings) == "function" then
		_G.CloseSettings()
	else
		settingsFrame.Visible = false
	end
end)

return {}

--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local SoundService = game:GetService("SoundService")

--local Players = game:GetService('Players')
--local Player = Players.LocalPlayer

--repeat task.wait() until Player:FindFirstChild('DataLoaded')

--local sinans_modules = ReplicatedStorage:WaitForChild("sinans_modules")

--local UI = SoundService:WaitForChild("UI")
--local Game_sound = SoundService:WaitForChild("Game")
--local Music = SoundService:WaitForChild("Music")
--local updateSettingEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("UpdateSetting")

--local contents = script.Parent.Frame.Settings.Contents

--local musicvolume = contents.Music_Volume.Contents.Bar.Contents
--local gamevolume = contents.Game_Volume.Contents.Bar.Contents
--local uivolume = contents.UI_Volume.Contents.Bar.Contents

--local Auto_Skip_Waves = contents.Auto_Skip_Waves
--local Disable_VFX = contents.Disable_VFX
--local Disable_Damage_Indicator = contents.Disable_Damage_Indicator
--local Skip_Summon_Animation = contents.Skip_Summon_Animation
--local Reduce_Motion = contents.Reduce_Motion
--local Auto_3x_Speed= contents.Auto_3x_Speed

--local toggleoffposition = UDim2.fromScale(0.09, 0.5)
--local toggleonposition = UDim2.fromScale(0.6, 0.5)

--function toggleon(gui)
--	gui.Contents.Toggle.Toggle.Circle.Position = toggleonposition
--	gui.Contents.Toggle.Toggle.Circle.BackgroundColor3 = Color3.fromRGB(34, 223, 119)
--	gui.Contents.Toggle.Toggle.BackgroundColor3 = Color3.fromRGB(13, 115, 28)
--end

--function toggleoff(gui)
--	gui.Contents.Toggle.Toggle.Circle.Position = toggleoffposition
--	gui.Contents.Toggle.Toggle.Circle.BackgroundColor3 = Color3.fromRGB(244, 75, 83)
--	gui.Contents.Toggle.Toggle.BackgroundColor3 = Color3.fromRGB(81, 24, 24)
--end

--function toggle(gui)
--	if gui.Contents.Toggle.Toggle.BackgroundColor3 == Color3.fromRGB(13, 115, 28) then
--		toggleoff(gui)
--		return false
--	else
--		toggleon(gui)
--		return true
--	end
--end

--function getpercentage(gui)
--	local percentage = gui.Position.X.Scale/0.936
--	return percentage
--end

--musicvolume.bettercircle:GetPropertyChangedSignal("Position"):Connect(function()
--	local percentage = getpercentage(musicvolume.bettercircle)

--	print('Percentage:')
--	print(percentage)

--	Music.Volume = percentage

--	musicvolume.Parent.Parent.Parent.Contents.Percentage.Text = (math.round(percentage * 100)).."%"
--	musicvolume.Bar.Size = UDim2.fromScale(musicvolume.bettercircle.Position.X.Scale + 0.03, 1)

--	updateSettingEvent:FireServer("MusicVolume", percentage)
--end)

---- set volume slider default

--local saved = Player.Settings.MusicVolume.Value

--if saved > 100 then
--	saved = 1
--end

--musicvolume.Parent.Parent.Parent.Contents.Percentage.Text = (math.round(saved * 100)).."%"
--musicvolume.bettercircle.Position = UDim2.fromScale(saved, 0)
--musicvolume.Bar.Size = UDim2.fromScale(musicvolume.bettercircle.Position.X.Scale + 0.03, 1)

--local percentage = getpercentage(musicvolume.bettercircle)
--Music.Volume = percentage

--uivolume.bettercircle:GetPropertyChangedSignal("Position"):Connect(function()
--	local percentage = getpercentage(uivolume.bettercircle)
--	UI.Volume = percentage

--	uivolume.Parent.Parent.Parent.Contents.Percentage.Text = (math.round(percentage * 100)).."%"
--	uivolume.Bar.Size = UDim2.fromScale(uivolume.bettercircle.Position.X.Scale + 0.03, 1)
--end)
--gamevolume.bettercircle:GetPropertyChangedSignal("Position"):Connect(function()
--	local percentage = getpercentage(gamevolume.bettercircle)
--	Game_sound.Volume = percentage

--	gamevolume.Parent.Parent.Parent.Contents.Percentage.Text = (math.round(percentage * 100)).."%"
--	gamevolume.Bar.Size = UDim2.fromScale(gamevolume.bettercircle.Position.X.Scale + 0.03, 1)
--end)



--local btnTable = {
--	["VFX"] = Disable_VFX,
--	['DamageIndicator'] = Disable_Damage_Indicator,
--	['AutoSkip'] = Auto_Skip_Waves,
--	['ReduceMotion'] = Reduce_Motion,
--	['SummonSkip'] = Skip_Summon_Animation,
--	["Auto3x"] = Auto_3x_Speed
--}

--for i,v in Player.Settings:GetChildren() do
--	if v.Value and btnTable[v.Name] then
--		toggleon(btnTable[v.Name])
--	end
--end

--Disable_VFX.Contents.Toggle.Activated:Connect(function()
--	--updateSettingEvent:FireServer(settingName, currentPercent)
--	local result = toggle(Disable_VFX)
--	updateSettingEvent:FireServer("VFX", result)
--end)
--Disable_Damage_Indicator.Contents.Toggle.Activated:Connect(function()
--	local result = toggle(Disable_Damage_Indicator)
--	updateSettingEvent:FireServer("DamageIndicator", result)
--end)
--Auto_Skip_Waves.Contents.Toggle.Activated:Connect(function()
--	local result = toggle(Auto_Skip_Waves)
--	updateSettingEvent:FireServer("AutoSkip", result)
--end)
--Reduce_Motion.Contents.Toggle.Activated:Connect(function()
--	local result = toggle(Reduce_Motion)
--	updateSettingEvent:FireServer("ReduceMotion", result)
--end)
--Skip_Summon_Animation.Contents.Toggle.Activated:Connect(function()
--	local result = toggle(Skip_Summon_Animation)
--	updateSettingEvent:FireServer("SummonSkip", result)--, currentPercent)
--end)
--Auto_3x_Speed.Contents.Toggle.Activated:Connect(function()
--	if Player.OwnGamePasses["3x Speed"].Value then
--		local result = toggle(Auto_3x_Speed)
--		updateSettingEvent:FireServer("Auto3x", result)--, currentPercent)
--	else
--		print("no own.")
--	end
--end)

--script.Parent.Frame.X_Close.Activated:Connect(function()
--	script.Parent.Visible = false -- note from Ace: WHO DID THIS LOL
--end)






local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local HIGHER_SPEED_GAMEPASS_ID = 1823132888

local Players = game:GetService('Players')
local Player = Players.LocalPlayer

repeat task.wait() until Player:FindFirstChild('DataLoaded')

local sinans_modules = ReplicatedStorage:WaitForChild("sinans_modules")

local UI = SoundService:WaitForChild("UI")
local Game_sound = SoundService:WaitForChild("Game")
local Music = SoundService:WaitForChild("Music")
local updateSettingEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("UpdateSetting")

local contents = script.Parent.Frame.Settings.Contents

local musicvolume = contents.Music_Volume.Contents.Bar.Contents
local gamevolume = contents.Game_Volume.Contents.Bar.Contents
local uivolume = contents.UI_Volume.Contents.Bar.Contents

local Auto_Skip_Waves = contents.Auto_Skip_Waves
local Disable_VFX = contents.Disable_VFX
local Disable_Damage_Indicator = contents.Disable_Damage_Indicator
local Skip_Summon_Animation = contents.Skip_Summon_Animation
local Reduce_Motion = contents.Reduce_Motion
local Auto_3x_Speed= contents.Auto_3x_Speed

local toggleoffposition = UDim2.fromScale(0.09, 0.5)
local toggleonposition = UDim2.fromScale(0.6, 0.5)

local function hasHigherSpeedAccess()
	local ownGamePasses = Player:FindFirstChild("OwnGamePasses")
	if ownGamePasses then
		local speed3x = ownGamePasses:FindFirstChild("3x Speed")
		local speed5x = ownGamePasses:FindFirstChild("5x Speed")

		if (speed3x and speed3x.Value) or (speed5x and speed5x.Value) then
			return true
		end
	end

	local success, ownsPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, HIGHER_SPEED_GAMEPASS_ID)
	end)

	return success and ownsPass or false
end

function toggleon(gui)
	gui.Contents.Toggle.Toggle.Circle.Position = toggleonposition
	gui.Contents.Toggle.Toggle.Circle.BackgroundColor3 = Color3.fromRGB(34, 223, 119)
	gui.Contents.Toggle.Toggle.BackgroundColor3 = Color3.fromRGB(13, 115, 28)
end

function toggleoff(gui)
	gui.Contents.Toggle.Toggle.Circle.Position = toggleoffposition
	gui.Contents.Toggle.Toggle.Circle.BackgroundColor3 = Color3.fromRGB(244, 75, 83)
	gui.Contents.Toggle.Toggle.BackgroundColor3 = Color3.fromRGB(81, 24, 24)
end

function toggle(gui)
	if gui.Contents.Toggle.Toggle.BackgroundColor3 == Color3.fromRGB(13, 115, 28) then
		toggleoff(gui)
		return false
	else
		toggleon(gui)
		return true
	end
end

function getpercentage(gui)
	local percentage = gui.Position.X.Scale/0.936
	return percentage
end

local initializingSliders = true

local function normalizeVolume(value)
	if typeof(value) ~= "number" then
		return 0.5
	end

	if value > 1 then
		value /= 100
	end

	return math.clamp(value, 0, 1)
end

local function setVolumeSlider(slider, soundGroup, settingName)
	local setting = Player.Settings:FindFirstChild(settingName)
	local saved = normalizeVolume(setting and setting.Value)
	local circle = slider.bettercircle

	slider.Parent.Parent.Parent.Contents.Percentage.Text = (math.round(saved * 100)).."%"
	circle.Position = UDim2.fromScale(saved * 0.936, 0)
	slider.Bar.Size = UDim2.fromScale(circle.Position.X.Scale + 0.03, 1)
	soundGroup.Volume = saved
end

local function connectVolumeSlider(slider, soundGroup, settingName)
	slider.bettercircle:GetPropertyChangedSignal("Position"):Connect(function()
		local percentage = normalizeVolume(getpercentage(slider.bettercircle))

		soundGroup.Volume = percentage

		slider.Parent.Parent.Parent.Contents.Percentage.Text = (math.round(percentage * 100)).."%"
		slider.Bar.Size = UDim2.fromScale(slider.bettercircle.Position.X.Scale + 0.03, 1)

		if not initializingSliders then
			updateSettingEvent:FireServer(settingName, percentage)
		end
	end)
end

connectVolumeSlider(musicvolume, Music, "MusicVolume")
connectVolumeSlider(gamevolume, Game_sound, "GameVolume")
connectVolumeSlider(uivolume, UI, "UIVolume")

setVolumeSlider(musicvolume, Music, "MusicVolume")
setVolumeSlider(gamevolume, Game_sound, "GameVolume")
setVolumeSlider(uivolume, UI, "UIVolume")
initializingSliders = false



local btnTable = {
	["VFX"] = Disable_VFX,
	['DamageIndicator'] = Disable_Damage_Indicator,
	['AutoSkip'] = Auto_Skip_Waves,
	['ReduceMotion'] = Reduce_Motion,
	['SummonSkip'] = Skip_Summon_Animation,
	["Auto3x"] = Auto_3x_Speed
}

for i,v in Player.Settings:GetChildren() do
	if v.Value and btnTable[v.Name] then
		toggleon(btnTable[v.Name])
	end
end

Disable_VFX.Contents.Toggle.Activated:Connect(function()
	--updateSettingEvent:FireServer(settingName, currentPercent)
	local result = toggle(Disable_VFX)
	updateSettingEvent:FireServer("VFX", result)
end)
Disable_Damage_Indicator.Contents.Toggle.Activated:Connect(function()
	local result = toggle(Disable_Damage_Indicator)
	updateSettingEvent:FireServer("DamageIndicator", result)
end)
Auto_Skip_Waves.Contents.Toggle.Activated:Connect(function()
	local result = toggle(Auto_Skip_Waves)
	updateSettingEvent:FireServer("AutoSkip", result)
end)
Reduce_Motion.Contents.Toggle.Activated:Connect(function()
	local result = toggle(Reduce_Motion)
	updateSettingEvent:FireServer("ReduceMotion", result)
end)
Skip_Summon_Animation.Contents.Toggle.Activated:Connect(function()
	local result = toggle(Skip_Summon_Animation)
	updateSettingEvent:FireServer("SummonSkip", result)--, currentPercent)
end)
Auto_3x_Speed.Contents.Toggle.Activated:Connect(function()
	if hasHigherSpeedAccess() then
		local result = toggle(Auto_3x_Speed)
		updateSettingEvent:FireServer("Auto3x", result)--, currentPercent)
	else
		MarketplaceService:PromptGamePassPurchase(Player, HIGHER_SPEED_GAMEPASS_ID)
		if typeof(_G.Message) == "function" then
			_G.Message("Auto 3x requires the speed gamepass.", Color3.fromRGB(255, 0, 0))
		end
	end
end)

local function closeSettings()
	script.Parent.Visible = false

	local settingsContainer = script.Parent.Parent
	if settingsContainer and settingsContainer:IsA("ScreenGui") then
		settingsContainer.Enabled = true
	end
end

_G.CloseSettings = closeSettings

local function connectCloseTarget(target, connected)
	if not target or connected[target] then
		return
	end

	connected[target] = true

	if target:IsA("GuiButton") then
		target.Activated:Connect(closeSettings)
	elseif target:IsA("GuiObject") then
		target.Active = true
		target.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				closeSettings()
			end
		end)
	end
end

local function connectCloseButtons()
	local connected = {}
	local frame = script.Parent:FindFirstChild("Frame")
	local settingsPanel = frame and frame:FindFirstChild("Settings")
	local closeContainer = settingsPanel and settingsPanel:FindFirstChild("Closebtn")

	connectCloseTarget(closeContainer, connected)

	if closeContainer then
		for _, descendant in closeContainer:GetDescendants() do
			connectCloseTarget(descendant, connected)
		end
	end

	local legacyCloseContainer = script.Parent.Frame:FindFirstChild("X_Close")
	connectCloseTarget(legacyCloseContainer, connected)

	if legacyCloseContainer then
		for _, descendant in legacyCloseContainer:GetDescendants() do
			connectCloseTarget(descendant, connected)
		end
	end

	if frame then
		connectCloseTarget(frame:FindFirstChild("X_Close"), connected)
	end

	if next(connected) == nil then
		warn("[SettingsHandler] Close button not found")
	end
end

connectCloseButtons()

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

repeat
	task.wait()
until player:FindFirstChild("DataLoaded")

local settings = player:WaitForChild("Settings")
local musicVolumeSetting = settings:WaitForChild("MusicVolume")
local gameVolumeSetting = settings:WaitForChild("GameVolume")
local uiVolumeSetting = settings:WaitForChild("UIVolume")

local CATEGORY_ATTRIBUTE = "AudioCategory"

local function normalizeVolume(value)
	if typeof(value) ~= "number" then
		return 0.5
	end

	if value > 1 then
		value /= 100
	end

	return math.clamp(value, 0, 1)
end

local function ensureSoundGroup(name)
	local soundGroup = SoundService:FindFirstChild(name)
	if soundGroup and soundGroup:IsA("SoundGroup") then
		return soundGroup
	end

	soundGroup = Instance.new("SoundGroup")
	soundGroup.Name = name
	soundGroup.Parent = SoundService
	return soundGroup
end

local soundGroups = {
	Game = ensureSoundGroup("Game"),
	UI = ensureSoundGroup("UI"),
	Music = ensureSoundGroup("Music"),
}

local function getCategoryFromSoundGroup(sound)
	local soundGroup = sound.SoundGroup
	if not soundGroup then
		return nil
	end

	if soundGroup == soundGroups.Game then
		return "Game"
	end
	if soundGroup == soundGroups.UI then
		return "UI"
	end
	if soundGroup == soundGroups.Music then
		return "Music"
	end

	return nil
end

local function classifySound(sound)
	local explicitCategory = sound:GetAttribute(CATEGORY_ATTRIBUTE)
	if explicitCategory and soundGroups[explicitCategory] then
		return explicitCategory
	end

	local groupedCategory = getCategoryFromSoundGroup(sound)
	if groupedCategory then
		return groupedCategory
	end

	if sound.Name == "MusicPlayer" then
		return "Music"
	end

	if sound:IsDescendantOf(playerGui) then
		return "UI"
	end

	if sound.Parent == SoundService then
		local lowerName = string.lower(sound.Name)
		if string.find(lowerName, "music", 1, true) then
			return "Music"
		end
	end

	return "Game"
end

local function routeSound(sound)
	if not sound:IsA("Sound") then
		return
	end

	local category = classifySound(sound)
	local targetSoundGroup = soundGroups[category]
	if targetSoundGroup and sound.SoundGroup ~= targetSoundGroup then
		sound.SoundGroup = targetSoundGroup
	end
end

local function routeSoundTree(root)
	if not root then
		return
	end

	if root:IsA("Sound") then
		routeSound(root)
	end

	for _, descendant in root:GetDescendants() do
		if descendant:IsA("Sound") then
			routeSound(descendant)
		end
	end
end

local function applySoundGroupVolumes()
	soundGroups.Music.Volume = normalizeVolume(musicVolumeSetting.Value)
	soundGroups.Game.Volume = normalizeVolume(gameVolumeSetting.Value)
	soundGroups.UI.Volume = normalizeVolume(uiVolumeSetting.Value)
end

local function connectVolumeSetting(setting)
	setting.Changed:Connect(function()
		applySoundGroupVolumes()
	end)
end

local function watchRoot(root)
	if not root then
		return
	end

	routeSoundTree(root)
	root.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Sound") then
			routeSound(descendant)
		end
	end)
end

local function watchCharacter(character)
	watchRoot(character)
end

connectVolumeSetting(musicVolumeSetting)
connectVolumeSetting(gameVolumeSetting)
connectVolumeSetting(uiVolumeSetting)

watchRoot(Workspace)
watchRoot(SoundService)
watchRoot(playerGui)

if player.Character then
	watchCharacter(player.Character)
end

player.CharacterAdded:Connect(function(character)
	watchCharacter(character)
end)

applySoundGroupVolumes()

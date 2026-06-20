local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local DEBUG_PREFIX = "[MusicPlayer][Match]"
local WAIT_TIMEOUT = 10

local function debugWarn(message: string, ...)
	warn((DEBUG_PREFIX .. " " .. message):format(...))
end

local function waitForChild(parent: Instance, childName: string, timeout: number?)
	local child = parent:WaitForChild(childName, timeout or WAIT_TIMEOUT)
	if not child then
		debugWarn("Missing %s under %s after %ss", childName, parent:GetFullName(), tostring(timeout or WAIT_TIMEOUT))
	end
	return child
end

local player = game.Players.LocalPlayer
repeat task.wait() until player:FindFirstChild("DataLoaded")
local playerSettings = waitForChild(player, "Settings")

local musicFolder = waitForChild(ReplicatedStorage, "Music")
local musicTemplate = musicFolder and waitForChild(musicFolder, "MusicPlayer")
local musicPlayer = SoundService:FindFirstChild("MusicPlayer")
local MusicSoundGroup = SoundService:FindFirstChild("Music")
if not MusicSoundGroup or not MusicSoundGroup:IsA("SoundGroup") then
	debugWarn("SoundService.Music SoundGroup was missing; creating a client fallback")
	MusicSoundGroup = Instance.new("SoundGroup")
	MusicSoundGroup.Name = "Music"
	MusicSoundGroup.Parent = SoundService
end

local MusicLibrary = waitForChild(ReplicatedStorage, "MusicLibrary")
local InGameFolder = MusicLibrary and waitForChild(MusicLibrary, "InGame")

local StoryModeStatsModule = require(ReplicatedStorage:WaitForChild("StoryModeStats"))
local infoFolder = waitForChild(workspace, "Info")
local World = infoFolder and waitForChild(infoFolder, "World")
local WorldName = World and StoryModeStatsModule.Worlds[World.Value]

if not musicPlayer or not musicPlayer:IsA("Sound") then
	if musicTemplate and musicTemplate:IsA("Sound") then
		musicPlayer = musicTemplate:Clone()
		musicPlayer.Name = musicTemplate.Name
	else
		debugWarn("ReplicatedStorage.Music.MusicPlayer was missing; creating a client fallback Sound")
		musicPlayer = Instance.new("Sound")
		musicPlayer.Name = "MusicPlayer"
		musicPlayer.Volume = 0.5
	end
	musicPlayer.Parent = SoundService
end

musicPlayer.SoundGroup = MusicSoundGroup
if musicTemplate and musicTemplate:IsA("Sound") then
	musicPlayer.Volume = musicTemplate.Volume
end

local function applySavedMusicVolume()
	local musicVolume = playerSettings and playerSettings:FindFirstChild("MusicVolume")
	if musicVolume and musicVolume:IsA("NumberValue") then
		local savedVolume = musicVolume.Value
		if savedVolume > 1 then
			savedVolume /= 100
		end

		MusicSoundGroup.Volume = math.clamp(savedVolume, 0, 1)
		if MusicSoundGroup.Volume <= 0 then
			debugWarn("MusicVolume setting is 0, so music is intentionally silent")
		end
	else
		debugWarn("Player.Settings.MusicVolume was missing; using current SoundGroup volume %s", tostring(MusicSoundGroup.Volume))
	end
end

local function normalizeSoundId(id: number | string)
	local stringId = tostring(id)
	if not stringId:find("rbxassetid://", 1, true) then
		stringId = ("rbxassetid://%s"):format(stringId)
	end
	return stringId
end

local function LoadNewMusic(id: number | string)
	local stringId = normalizeSoundId(id)
	local totalLoadCount = 0

	if stringId == "" or stringId == "rbxassetid://" then
		debugWarn("Cannot load an empty SoundId")
		return false
	end

	musicPlayer.SoundId = stringId

	local preloadOk, preloadErr = pcall(function()
		ContentProvider:PreloadAsync({ musicPlayer })
	end)
	if not preloadOk then
		debugWarn("PreloadAsync failed for %s: %s", stringId, tostring(preloadErr))
	end

	while not musicPlayer.IsLoaded and totalLoadCount < 10 do
		totalLoadCount += 1
		task.wait(0.5)
	end

	if musicPlayer.IsLoaded then
		return true, musicPlayer
	end

	debugWarn("Sound did not report IsLoaded after %ss, trying Play() anyway: %s", tostring(totalLoadCount * 0.5), stringId)
	return true, musicPlayer
end

local function reportPlaybackState(soundInstance: Sound)
	local groupVolume = soundInstance.SoundGroup and soundInstance.SoundGroup.Volume or nil
	debugWarn(
		"Play() did not start audio. SoundId=%s IsLoaded=%s IsPlaying=%s TimeLength=%s Volume=%s SoundGroupVolume=%s. Check if the asset is public/allowed for this experience.",
		tostring(soundInstance.SoundId),
		tostring(soundInstance.IsLoaded),
		tostring(soundInstance.IsPlaying),
		tostring(soundInstance.TimeLength),
		tostring(soundInstance.Volume),
		tostring(groupVolume)
	)
end

function PlayMusic()
	local MusicInstances = {}
	local currentMusicIndex = 1

	if not WorldName then
		WorldName = "Death Star"
	end

	local function PreloadMusicAssets()
		local loadList = {}
		if not InGameFolder then
			debugWarn("Missing MusicLibrary.InGame; match music cannot start")
			return
		end

		local worldFolder = InGameFolder:FindFirstChild(WorldName) or InGameFolder:FindFirstChild("Death Star")

		if not worldFolder then
			debugWarn("No music folder found for world '%s' and no Death Star fallback exists", tostring(WorldName))
			return
		end

		for _, sound in worldFolder:GetDescendants() do
			if not sound:IsA("Sound") then
				continue
			end

			table.insert(loadList, sound)
			table.insert(MusicInstances, sound)
		end

		if #loadList > 0 then
			local preloadOk, preloadErr = pcall(function()
				ContentProvider:PreloadAsync(loadList)
			end)
			if not preloadOk then
				debugWarn("Playlist preload failed for world '%s': %s", tostring(worldFolder.Name), tostring(preloadErr))
			end
		end
	end

	applySavedMusicVolume()
	PreloadMusicAssets()

	if #MusicInstances == 0 then
		debugWarn("No Sound instances found in playlist for world '%s'", tostring(WorldName))
		return
	end

	debugWarn("Starting playlist for world '%s' with %d track(s)", tostring(WorldName), #MusicInstances)

	while true do
		local currentSound = MusicInstances[currentMusicIndex]
		if not currentSound then
			debugWarn("Playlist index %d was nil; restarting playlist", currentMusicIndex)
			currentMusicIndex = 1
			task.wait(1)
			continue
		end

		local successfulLoad, soundInstance = LoadNewMusic(currentSound.SoundId)
		currentMusicIndex = (currentMusicIndex < #MusicInstances and currentMusicIndex + 1) or 1
		if successfulLoad and soundInstance then
			soundInstance:Stop()
			soundInstance.TimePosition = 0
			soundInstance:Play()
			task.wait(0.25)

			if not soundInstance.IsPlaying then
				reportPlaybackState(soundInstance)
				task.wait(10)
			end

			local waitDuration = soundInstance.TimeLength > 0 and soundInstance.TimeLength or 30
			task.wait(waitDuration)
		else
			task.wait(1)
		end
	end
end

repeat task.wait(1) until game:IsLoaded()
PlayMusic()

-- SERVICES

local TweenService    = game:GetService("TweenService")
local SoundService    = game:GetService("SoundService")

-- CONSTANTS

local SoundAssets = require(script.Parent.SoundAssets)

local MUSIC_FADE_TIME      = 1.5
local MUSIC_DEFAULT_VOLUME = 0.6
local SFX_DEFAULT_VOLUME   = 0.8
local TWEEN_INFO_FADE      = TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- VARIABLES

local SoundModule = {}
SoundModule.__index = SoundModule

local musicFolder  = Instance.new("Folder")
musicFolder.Name   = "MusicFolder"
musicFolder.Parent = SoundService

local sfxFolder    = Instance.new("Folder")
sfxFolder.Name     = "SFXFolder"
sfxFolder.Parent   = SoundService

local settings = {
	musicVolume  = MUSIC_DEFAULT_VOLUME,
	sfxVolume    = SFX_DEFAULT_VOLUME,
	musicMuted   = false,
	sfxMuted     = false,
}

local musicCache   = {}
local sfxCache     = {}
local currentMusic = nil
local fadeTween    = nil
local queueIndex   = 1
local musicQueue   = {}

-- FUNCTIONS

local function createSound(id, parent, volume, looped)
	local sound        = Instance.new("Sound")
	sound.SoundId      = "rbxassetid://" .. tostring(id)
	sound.Volume       = volume
	sound.Looped       = looped
	sound.Parent       = parent
	return sound
end

local function getOrCreateMusic(name)
	if not musicCache[name] then
		local id = SoundAssets.Musics[name]
		if not id then return nil end
		musicCache[name] = createSound(id, musicFolder, settings.musicVolume, false)
		musicCache[name].Name = name
	end
	return musicCache[name]
end

local function getOrCreateSfx(name)
	if not sfxCache[name] then
		local id = SoundAssets.Effects[name]
		if not id then return nil end
		sfxCache[name] = createSound(id, sfxFolder, settings.sfxVolume, false)
		sfxCache[name].Name = name
	end
	return sfxCache[name]
end

local function applyMusicVolume(sound)
	if sound then
		sound.Volume = settings.musicMuted and 0 or settings.musicVolume
	end
end

local function applyAllSfxVolume()
	for _, sound in pairs(sfxCache) do
		sound.Volume = settings.sfxMuted and 0 or settings.sfxVolume
	end
end

local function playMusicByName(name, fadeIn)
	local sound = getOrCreateMusic(name)
	if not sound then return end

	if currentMusic and currentMusic ~= sound then
		local previous = currentMusic
		if fadeTween then fadeTween:Cancel() end

		fadeTween = TweenService:Create(previous, TWEEN_INFO_FADE, { Volume = 0 })
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			previous:Stop()
		end)
	end

	currentMusic = sound
	applyMusicVolume(sound)

	if fadeIn then
		sound.Volume = 0
		sound:Play()
		local targetVolume = settings.musicMuted and 0 or settings.musicVolume
		TweenService:Create(sound, TWEEN_INFO_FADE, { Volume = targetVolume }):Play()
	else
		sound:Play()
	end
end

function SoundModule:PlayMusicQueue()
	musicQueue = {}
	for name in pairs(SoundAssets.Musics) do
		table.insert(musicQueue, name)
	end

	if #musicQueue == 0 then return end

	queueIndex = 1

	local function playNext()
		local name  = musicQueue[queueIndex]
		local sound = getOrCreateMusic(name)
		if not sound then return end

		playMusicByName(name, true)

		sound.Ended:Connect(function()
			queueIndex = (queueIndex % #musicQueue) + 1
			playNext()
		end)
	end

	playNext()
end

function SoundModule:PlayMusic(name, fadeIn)
	playMusicByName(name, fadeIn)
end

function SoundModule:StopMusic(fadeOut)
	if not currentMusic then return end

	if fadeOut then
		if fadeTween then fadeTween:Cancel() end
		local stopping = currentMusic
		fadeTween = TweenService:Create(stopping, TWEEN_INFO_FADE, { Volume = 0 })
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			stopping:Stop()
		end)
	else
		currentMusic:Stop()
	end

	currentMusic = nil
end

function SoundModule:PlaySfx(name)
	local sound = getOrCreateSfx(name)
	if not sound then return end

	sound.Volume = settings.sfxMuted and 0 or settings.sfxVolume
	sound:Play()
end

function SoundModule:SetMusicVolume(volume)
	settings.musicVolume = math.clamp(volume, 0, 1)
	if not settings.musicMuted then
		applyMusicVolume(currentMusic)
	end
end

function SoundModule:SetSfxVolume(volume)
	settings.sfxVolume = math.clamp(volume, 0, 1)
	if not settings.sfxMuted then
		applyAllSfxVolume()
	end
end

function SoundModule:MuteMusic(muted)
	settings.musicMuted = muted
	if currentMusic then
		if muted then
			TweenService:Create(currentMusic, TWEEN_INFO_FADE, { Volume = 0 }):Play()
		else
			TweenService:Create(currentMusic, TWEEN_INFO_FADE, { Volume = settings.musicVolume }):Play()
		end
	end
end

function SoundModule:MuteSfx(muted)
	settings.sfxMuted = muted
	applyAllSfxVolume()
end

function SoundModule:GetSettings()
	return {
		musicVolume = settings.musicVolume,
		sfxVolume   = settings.sfxVolume,
		musicMuted  = settings.musicMuted,
		sfxMuted    = settings.sfxMuted,
	}
end

function SoundModule:LoadSettings(data)
	if data.musicVolume ~= nil then settings.musicVolume = data.musicVolume end
	if data.sfxVolume   ~= nil then settings.sfxVolume   = data.sfxVolume   end
	if data.musicMuted  ~= nil then settings.musicMuted  = data.musicMuted  end
	if data.sfxMuted    ~= nil then settings.sfxMuted    = data.sfxMuted    end

	if currentMusic then
		applyMusicVolume(currentMusic)
	end
	applyAllSfxVolume()
end

function SoundModule:GetCurrentMusic()
	return currentMusic and currentMusic.Name or nil
end

function SoundModule:IsPlayingMusic()
	return currentMusic ~= nil and currentMusic.IsPlaying
end

-- INIT

setmetatable(SoundModule, { __index = SoundModule })

return SoundModule
local SoundService = game:GetService("SoundService")

local module = {}

function module.playSound(soundName)
	local sound : Sound = script[soundName]:Clone()

	sound:SetAttribute("AudioCategory", "Game")
	local gameSoundGroup = SoundService:FindFirstChild("Game")
	if gameSoundGroup and gameSoundGroup:IsA("SoundGroup") then
		sound.SoundGroup = gameSoundGroup
	end

	sound.Parent = SoundService
	
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	
	sound:Play()
end

return module

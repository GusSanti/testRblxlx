local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local Info = workspace.Info
local BASIC_MOB_SPAWN_DELAY = 1
local MIN_MOB_SPAWN_DELAY = 1
--local GameStarted = Info.GameRunning

local function ensureInfoBoolValue(name, defaultValue)
	local value = Info:FindFirstChild(name)
	if value and value:IsA("BoolValue") then
		return value
	end

	if value then
		value:Destroy()
	end

	value = Instance.new("BoolValue")
	value.Name = name
	value.Value = defaultValue
	value.Parent = Info
	return value
end

local versusValue = ensureInfoBoolValue("Versus", false)

--if not GameStarted.Value then
--GameStarted:GetPropertyChangedSignal('Value'):Wait()
--end

--if not Info.Versus.Value then return {} end
repeat task.wait(1) until versusValue.Value 

local Wave = Info.Wave

-- ramp up speed based on wave
local speed = 1
local function adjustSpeed(speedMultiplier)
	local randomPlayer = Players:GetChildren()[1]

	workspace.Info.GameSpeed.Value = speedMultiplier
	ReplicatedStorage.Events.ChangeSpeed:FireAllClients(`{speedMultiplier}x`, randomPlayer)
	script:SetAttribute('MobSpawnDelay', math.max(MIN_MOB_SPAWN_DELAY, BASIC_MOB_SPAWN_DELAY / speedMultiplier))
	for _, player in ipairs(Players:GetPlayers()) do
		if player:FindFirstChild('Speed') then
			player.Speed.Value = speedMultiplier
		end
	end
end
function round2(n)
	return math.floor(n * 100 + 0.5) / 100
end

warn('CONNECTED!')

Wave.Changed:Connect(function()
	speed = round2(1 + ((Wave.Value / 50) * 3))

	adjustSpeed(speed)
end)

return {}

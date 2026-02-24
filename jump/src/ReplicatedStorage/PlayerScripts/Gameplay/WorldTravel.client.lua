------------------//SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

------------------//MODULES
local DataUtility = require(ReplicatedStorage.Modules.Utility.DataUtility)
local WorldConfig = require(ReplicatedStorage.Modules.Datas.WorldConfig)
local NotificationUtility = require(ReplicatedStorage.Modules.Utility.NotificationUtility)

------------------//VARIABLES
local player = Players.LocalPlayer
local travelEvent = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("TravelAction")
local portalsFolder = Workspace:WaitForChild("Portals")

local currentWorldId = 1
local currentPower = 0
local currentRebirths = 0
local lastTouch = 0

------------------//FUNCTIONS
local function update_lighting(worldId)
	local mapFolder = Workspace:FindFirstChild(tostring(worldId))
	if not mapFolder then return end

	local lightingSets = mapFolder:FindFirstChild("Lighting Sets")
	if not lightingSets then return end

	local preset = lightingSets:FindFirstChild("LightingPreset")
	local stylized = lightingSets:FindFirstChild("Stylized")

	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") or child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("SunRaysEffect") then
			child:Destroy()
		end
	end

	if preset then
		for _, effect in preset:GetChildren() do
			local clone = effect:Clone()
			clone.Parent = Lighting
		end
	end

	if stylized then
		local attributes = stylized:GetAttributes()
		for propName, propValue in attributes do
			pcall(function()
				Lighting[propName] = propValue
			end)
		end
	end
end

local function setup_portals()
	for _, part in portalsFolder:GetChildren() do
		local destId = tonumber(part.Name)

		if destId then
			local worldData = WorldConfig.GetWorld(destId)
			if worldData then
				part.Touched:Connect(function(hit)
					if os.clock() - lastTouch < 1 then return end

					if hit.Parent == player.Character then

						if destId == currentWorldId then
							lastTouch = os.clock()
							part.Transparency = 0.2
							task.delay(0.2, function() part.Transparency = 0.8 end)
							travelEvent:FireServer(destId - 1)

						elseif destId == currentWorldId + 1 then
							local powerOk = currentPower >= worldData.requiredPogoPower
							local rebirthsOk = currentRebirths >= worldData.requiredRebirths

							if powerOk and rebirthsOk then
								lastTouch = os.clock()
								part.Transparency = 0.2
								task.delay(0.2, function() part.Transparency = 0.8 end)
								travelEvent:FireServer(destId)
							end

						elseif destId < currentWorldId then
							lastTouch = os.clock()
							travelEvent:FireServer(destId)
						end
					end
				end)
			end
		end
	end
end

------------------//BINDS
DataUtility.client.ensure_remotes()

DataUtility.client.bind("CurrentWorld", function(val)
	if currentWorldId == val then return end
	currentWorldId = val
	update_lighting(val) -- Atualiza a iluminação quando o mundo muda

	local worldData = WorldConfig.GetWorld(val)
	if worldData then
		local msg = string.format("%s - Gravity: %sx", string.upper(worldData.name), tostring(worldData.gravityMult))
		NotificationUtility:Success(msg, 5)
	end
end)

DataUtility.client.bind("PogoSettings.base_jump_power", function(val)
	currentPower = val
end)

DataUtility.client.bind("Rebirths", function(val)
	currentRebirths = val
end)

currentWorldId = DataUtility.client.get("CurrentWorld") or 1
currentPower = DataUtility.client.get("PogoSettings.base_jump_power") or 0
currentRebirths = DataUtility.client.get("Rebirths") or 0

setup_portals()
update_lighting(currentWorldId) -- Atualiza a iluminação inicial ao entrar no jogo
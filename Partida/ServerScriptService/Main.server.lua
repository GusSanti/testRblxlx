local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService('RunService')
local ServerStorage = game:GetService('ServerStorage')
local ErrorCatcher = require(ServerStorage.ServerModules.ErrorService)
local Parties = require(script.Parties)


-- reset everything to normal
if not RunService:IsStudio() then
	workspace.Info:Destroy()
	script.Info:Clone().Parent = workspace -- restore values
end

local info = workspace.Info

local function ensureInfoIntValue(name, defaultValue)
	local value = info:FindFirstChild(name)
	if value and value:IsA("IntValue") then
		return value
	end

	if value then
		value:Destroy()
	end

	value = Instance.new("IntValue")
	value.Name = name
	value.Value = defaultValue
	value.Parent = info
	return value
end

-- Older Info templates can be missing challenge-specific values. Default them so
-- normal matches do not fail placement checks that read challenge state.
local challengeNumberValue = ensureInfoIntValue("ChallengeNumber", -1)
local challengeRewardValue = ensureInfoIntValue("ChallengRewardeNumber", 0)
local challengeUniqueIdValue = ensureInfoIntValue("ChallengeUniqueId", 0)


local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")

local mob = require(script.Mob)
local tower = require(script.Tower)
local round = require(script.Round)

local RS = game:GetService("ReplicatedStorage")

local event = require(game.ReplicatedStorage.EventFunctions)
local minPlayers = 1 -- сколько игроков на сервере
local readyToStart = true

local StoryModeStats = require(ReplicatedStorage.StoryModeStats)


local admins = {}

local DEFAULT = 
	{
		World = 1,
		Level = 1,
		Mode = 0, 
		Versus = true, 
		Competitive = true
	}

local function resolveTeleportDifficulty(teleportData)
	if type(teleportData) ~= "table" then
		return "Normal"
	end

	if type(teleportData.Difficulty) == "string" and teleportData.Difficulty ~= "" then
		return teleportData.Difficulty
	end

	if teleportData.Infinity or teleportData.Level == 0 then
		return "Hard"
	end

	if teleportData.Mode == 3 then
		return "Hellfire"
	elseif teleportData.Mode == 2 then
		return "Hard"
	end

	return "Normal"
end

local function handlePlayerJoin(player)
	AnalyticsService:LogOnboardingFunnelStepEvent(
		player,
		3,
		"loaded into story mode"
	)
	local teleportData = player:GetJoinData()["TeleportData"] or DEFAULT

	if not teleportData.OwnerId then
		teleportData.OwnerId = player.UserId
	end

	if RunService:IsStudio() then teleportData = nil end

	warn('teleport data:')
	print(teleportData)
	if teleportData then
		for i,v in pairs(teleportData) do
			warn(i, v)
		end
	end


	if teleportData then
		workspace.Info.World.Value = teleportData.World
		workspace.Info.Level.Value = teleportData.Level
		workspace.Info.Mode.Value = teleportData.Mode
		workspace.Info.Raid.Value = teleportData.Raid or false
		workspace.Info.Infinity.Value = teleportData.Level == 0 or teleportData.Infinity
		workspace.Info.Event.Value = teleportData.Event
		workspace.Info.Difficulty.Value = resolveTeleportDifficulty(teleportData)

		if StoryModeStats.Maps[teleportData.World] then
			info.WorldString.Value = StoryModeStats.Maps[teleportData.World]
		end

		if teleportData.OwnerId then
			workspace.Info.OwnerId.Value = teleportData.OwnerId
		end

		if teleportData.Versus then
			info.Versus.Value = teleportData.Versus

			if info.WorldString.Value == '' then
				local randomMap = ServerStorage.CompetitiveMaps:GetChildren()
				local selectedMap = randomMap[math.random(#randomMap)]

				info.WorldString.Value = selectedMap.Name
			end
		end

		if teleportData.Competitive then
			info.Competitive.Value = teleportData.Competitive
		end


		if teleportData.ChallengeNumber == nil or teleportData.ChallengeNumber == -1 then
			challengeNumberValue.Value = -1
			challengeRewardValue.Value = 0
			challengeUniqueIdValue.Value = 0
		else
			challengeNumberValue.Value = teleportData.ChallengeNumber
			challengeRewardValue.Value = teleportData.ChallengeRewardNumber or 0
			challengeUniqueIdValue.Value = teleportData.ChallengeUniqueId or 0
		end
	end

	if workspace.Info.Raid.Value then
		task.spawn(function()
			repeat task.wait() until not player.Parent or player:FindFirstChild('DataLoaded')

			if player.Parent then
				if player.RaidLimitData.Attempts.Value == 0 then
					game:GetService('TeleportService'):Teleport(130340586645002, player)
					return
				end

				player.RaidLimitData.Attempts.Value -= 1
			end
		end)
	end


	if game.Workspace.Info.World.Value == -1 then
		game.Workspace.Info.Event.Value = true
		event[event.EventNames[game.Workspace.Info.Level.Value]]()
	end

	local currentPlayers = #Players:GetPlayers()

	if table.find(admins,player.UserId) then
		local gui = game.ServerStorage.AdminGui:Clone()
		for i, v in RS.Enemies:GetChildren() do
			local button = script.TextButton:Clone()
			button.Text = v.Name
			button.Name = v.Name
			button.Parent = gui.Frame
		end
		gui.Parent = player:WaitForChild("PlayerGui")
	end

	if currentPlayers >= minPlayers and readyToStart then
		readyToStart = false



		round.StartGame(player)



		readyToStart = true
	else
		workspace.Info.Message.Value = "Waiting for " .. (minPlayers - currentPlayers) .. " more player(s)"
	end
end

for i, player in Players:GetChildren() do
	repeat task.wait() until player:FindFirstChild("Settings")
	handlePlayerJoin(player)
end

Players.PlayerAdded:Connect(handlePlayerJoin)

--RS.Events.SpawnMob.OnServerEvent:Connect(function(player,mobName)
--	if table.find(admins,player.UserId) then
--		mob.Spawn(mobName,1,game.Workspace.Map:FindFirstChildOfClass("Folder"))
--	else
--		player:Kick("Lolololololol")
--	end
--end)

--main()


local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local AnalyticsService = game:GetService("AnalyticsService")
local RaidDataSync = require(ServerScriptService.ProfileServiceMain.Main.RaidDataSync)
local AchievementHandler = require(ServerStorage.ServerModules.AchievementHandler)
local QuestConfig = require(ReplicatedStorage.Configs.QuestConfig)
local CurrentRaidEventMap = ReplicatedStorage.CurrentRaidEventMap.Value


local ChallengeModule = require(ReplicatedStorage.Modules.ChallengeModule)
local ClanLib = require(ServerScriptService.ClanService.ClansHandler.ClanLib)
local ClanLeaderboardQueue = require(ServerScriptService.ClanService.ClanLoader.ClanLeaderboardQueue)

local Variables = require(ServerScriptService.Main.Round.Variables)
local GetPlayerBoost = require(ReplicatedStorage.Modules.GetPlayerBoost)
local GetVipsBoost = require(ReplicatedStorage.Modules.GetVipsBoost)
local StoryModeStats = require(ReplicatedStorage.StoryModeStats)
local ReceiveRewardsEvent = ReplicatedStorage.Events.Client.ReceiveRewards
local info = workspace.Info

local module = {}
local Selected = false
print('[REWARDSLIB] ACTIVATED')

local function didMainBaseFall()
	if info.Versus.Value then
		return false
	end

	local map = Variables.map
	local base = map and map:FindFirstChild("Base")
	local humanoid = base and base:FindFirstChildOfClass("Humanoid")

	return humanoid and humanoid.Health <= 0
end

local roundWon = Variables.win and not Variables.died and not didMainBaseFall()

for _, player in Players:GetPlayers() do
	if info.Versus.Value then
		require(script.Versus)(player)
	end
	if not Variables.infinity and game.Workspace.Info.Event.Value then
		require(script.Event)(player)
		Selected = true
	elseif Variables.infinity and Variables.raid and Variables.died then	
		require(script.RaidInfinite)(player)
	elseif Variables.infinity and Variables.died then
		print('Giving inf rewards...')
		require(script.Infinite)(player)
	elseif (Variables.challenge ~= -1 or Variables.challenge == 10) and roundWon then
		require(script.Challenge)(player)
	elseif not Variables.infinity and Variables.challenge == -1 and roundWon and not Selected then -- includes raid win too
		print('Giving story rewards...')
		require(script.Story)(player)
	end
end

return module

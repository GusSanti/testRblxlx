local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Variables = require(script.Parent.Parent.Variables)
local Events = ReplicatedStorage.Events
local info = workspace.Info

local module = {}
local AUTO_SKIP_RETRY_DELAYS = {0.1, 0.35, 0.75, 1.5}

local function hasAutoSkipEnabled(player)
	local settings = player:FindFirstChild("Settings")
	local autoSkip = settings and settings:FindFirstChild("AutoSkip")
	return autoSkip and autoSkip.Value == true
end

local function debugSkip(message, source)
	if RunService:IsStudio() then
		warn(string.format(
			"[SkipDebug][Round %s/%s] %s | source=%s skip=%s open=%s votes=%s players=%s",
			tostring(Variables.CurrentRound),
			tostring(Variables.MaxWave),
			message,
			tostring(source or "Unknown"),
			tostring(Variables.Skip),
			tostring(Variables.SkipVoteOpen),
			tostring(Variables.SkipVotes),
			tostring(#Players:GetPlayers())
			))
	end
end

local function tryAutoVoteForPlayer(player, source)
	if Variables.SkipVoteOpen and hasAutoSkipEnabled(player) then
		module.TryVote(player, source)
	end
end

function module.HasAutoSkipEnabled(player)
	return hasAutoSkipEnabled(player)
end

function module.TryVote(player, source)
	if not Variables.SkipVoteOpen then
		debugSkip("Ignored vote from " .. player.Name .. " because the vote window is closed", source)
		return false
	end

	local totalMobs = 0
	local limit = Variables.mobLimit 

	if info.Versus.Value then
		limit *= 2
		totalMobs = #workspace.BlueMobs:GetChildren() + #workspace.RedMobs:GetChildren() 
	else
		totalMobs = #workspace.Mobs:GetChildren()
	end

	if totalMobs > limit then
		debugSkip(string.format("Denied vote from %s because total mobs is %s/%s", player.Name, totalMobs, limit), source)
		return "Too many enemies to skip wave! "..tostring(totalMobs).."/"..tostring(limit)
	end
	if Variables.CurrentRound >= Variables.MaxWave then
		debugSkip("Denied vote from " .. player.Name .. " on the final wave", source)
		return "Cannot skip on the final wave!"
	end
	if not Variables.Players[player.Name] then		
		Variables.SkipVotes += 1
		Variables.Players[player.Name] = true
		debugSkip("Accepted vote from " .. player.Name, source)

		ReplicatedStorage.Events.SkipGui:FireAllClients(nil, {
			Yes = Variables.SkipVotes,

		})

		local playerCount = #Players:GetPlayers()
		if playerCount > 0 and Variables.SkipVotes/playerCount >= 0.5 then
			debugSkip("Vote threshold reached, firing skip event", source)
			script.Parent.Parent.Parent.Skip:Fire()
		end
		return true
	end

	debugSkip("Ignored duplicate vote from " .. player.Name, source)
	return false
end

function module.TryAutoVotes(allowRetry)
	if not Variables.SkipVoteOpen then
		return
	end

	for _, player in Players:GetPlayers() do
		if hasAutoSkipEnabled(player) then
			tryAutoVoteForPlayer(player, "AutoSkip")
		end
	end

	if allowRetry == false then
		return
	end

	local retryRound = Variables.CurrentRound
	for _, delayTime in AUTO_SKIP_RETRY_DELAYS do
		task.delay(delayTime, function()
			if Variables.CurrentRound ~= retryRound or not Variables.SkipVoteOpen or Variables.Skip then
				return
			end

			module.TryAutoVotes(false)
		end)
	end
end

local function bindAutoSkipSetting(player)
	local function bindSettings(settings)
		local function bindAutoSkip(autoSkip)
			if not autoSkip or autoSkip:GetAttribute("AutoSkipVoteBound") then
				return
			end

			autoSkip:SetAttribute("AutoSkipVoteBound", true)
			tryAutoVoteForPlayer(player, "AutoSkipLoaded")

			autoSkip.Changed:Connect(function()
				if autoSkip.Value == true then
					tryAutoVoteForPlayer(player, "AutoSkipChanged")
				end
			end)
		end

		bindAutoSkip(settings:FindFirstChild("AutoSkip"))
		settings.ChildAdded:Connect(function(child)
			if child.Name == "AutoSkip" then
				bindAutoSkip(child)
			end
		end)
	end

	local settings = player:FindFirstChild("Settings")
	if settings then
		bindSettings(settings)
	end

	player.ChildAdded:Connect(function(child)
		if child.Name == "Settings" then
			bindSettings(child)
		end
	end)
end

for _, player in Players:GetPlayers() do
	bindAutoSkipSetting(player)
end

Players.PlayerAdded:Connect(bindAutoSkipSetting)

ReplicatedStorage.Functions.VoteForSkip.OnServerInvoke = function(player, source) 
	return module.TryVote(player, source)
end

script.Parent.Parent.Parent.Skip.Event:Connect(function()
	if Variables.CurrentRound >= Variables.MaxWave then return end
	Variables.Skip = true
	Variables.SkipVoteOpen = false
	ReplicatedStorage.Events.SkipGui:FireAllClients(false)
	debugSkip("Skip event applied to the current round")
end)

Events.Client.VoteStartGame.OnServerEvent:Connect(function(player)
	if Variables.startTime ~= nil then
		debugSkip("Ignored start vote from " .. player.Name .. " because the match has already started", "StartVote")
		return
	end

	if not table.find(Variables.PlayersVotedForStart,player.Name) then
		table.insert(Variables.PlayersVotedForStart,player.Name)
	end

	if #Variables.PlayersVotedForStart/#Players:GetChildren() >= 0.5 then
		Variables.voteStart = true
	end
end)



return module

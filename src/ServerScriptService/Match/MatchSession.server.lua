------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")
local Teams: Teams = game:GetService("Teams")
local TeleportService: TeleportService = game:GetService("TeleportService")
local MemoryStoreService: MemoryStoreService = game:GetService("MemoryStoreService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local MapVoteService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("MapVoteService"))
local MapVoteBridge = require(ServerStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("MapVoteBridge"))

local WIN_SCORE = 5
local WIN_SHOW_TIME = 10
local LOAD_TIMEOUT = 30
local MAP_VOTE_TIME = 2--0
local FREEZE_TIME = 5
local ROUND_TIME = 450
local ROUND_BREAK_TIME = 5
local ROUND_RESPAWN_WAIT = 5

local TEAM_RED_NAME = "Red"
local TEAM_BLUE_NAME = "Blue"
local DEATHMATCH_MODE = MatchmakingDictionary.DEATHMATCH_MODE
local DEATHMATCH_MAP_NAME = "DeathmatchMap"
local DEATHMATCH_REGISTRY_UPDATE_INTERVAL = 10
local DEATHMATCH_RESPAWN_DELAY = 0.35
local DEATHMATCH_MAX_PLAYERS = MatchmakingDictionary.DEATHMATCH_MAX_PLAYERS
local DEATHMATCH_SERVER_TTL = MatchmakingDictionary.DEATHMATCH_SERVER_TTL

local MAP_FOLDER_NAME = "Map"
local MAP_SPAWN_FOLDER_NAME = "Spawn"
local CHARACTERS_FOLDER_NAME = "Characters"
local FORCE_MATCH_VALUE_NAME = "ForceMatch"
local FORCE_MATCH_MODE = "1v1"
local FORCE_MATCH_PLAYERS_REQUIRED = 2
local MATCH_WORKSPACE_ATTRIBUTE_NAME = "IsMatch"
local PLAYER_FROZEN_ATTRIBUTE_NAME = "GS_IsFrozen"

local DATA_UTILITY_MODULE_NAME = "DataUtility"
local KILL_COINS_REWARD = 15
local KILL_XP_REWARD = 15
local XP_PER_LEVEL = 100

------------------//VARIABLES
type MatchConfig = {
	mode: string,
	playersRequired: number,
	matchId: string?,
	teamByUserId: { [number]: string }?,
	isDeathmatch: boolean?,
	deathmatchServerKey: string?,
	maxPlayers: number?,
}

type FreezeCache = {
	walkSpeed: number,
	useJumpPower: boolean,
	jumpPower: number,
	jumpHeight: number,
	autoRotate: boolean,
}

type Participant = {
	model: Model,
	player: Player?,
	teamName: string?,
}

type AnchorCache = {
	rootPart: BasePart,
	anchored: boolean,
}

local remotesFolderInstance: Folder? = ReplicatedStorage:FindFirstChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder?

if not remotesFolderInstance then
	remotesFolderInstance = Instance.new("Folder")
	remotesFolderInstance.Name = MatchmakingDictionary.REMOTE_FOLDER_NAME
	remotesFolderInstance.Parent = ReplicatedStorage
end

local remotesFolder: Folder = remotesFolderInstance :: Folder
local matchRemoteInstance: RemoteEvent? = remotesFolder:FindFirstChild(MatchmakingDictionary.MATCH_SESSION_REMOTE_EVENT_NAME) :: RemoteEvent?

if not matchRemoteInstance then
	matchRemoteInstance = Instance.new("RemoteEvent")
	matchRemoteInstance.Name = MatchmakingDictionary.MATCH_SESSION_REMOTE_EVENT_NAME
	matchRemoteInstance.Parent = remotesFolder
end

local matchRemote: RemoteEvent = matchRemoteInstance :: RemoteEvent

local matchConfig: MatchConfig? = nil
local matchSource = "None"
local matchRunning = false
local matchStarted = false
local roundNumber = 0
local redScore = 0
local blueScore = 0
local phase = "Lobby"
local phaseEndsAt = 0
local phaseRoundToken = 0
local pendingRoundWinner: string? = nil
local winnerTeamName: string? = nil
local winnerName: string? = nil
local quitWinnerTeamName: string? = nil
local quitLoserTeamName: string? = nil
local quitWinnerName: string? = nil
local quitLoserUserId: number? = nil
local matchEndedByQuit = false
local matchStatsApplied = false

local freezeCaches: { [Model]: FreezeCache } = {}
local deathConnections: { [Model]: RBXScriptConnection } = {}
local anchorCacheByModel: { [Model]: AnchorCache } = {}
local didWarnMissingCharactersFolder = false
local dataUtility: any = nil
local mapVoteService: any = nil
local deathmatchServerMap = MemoryStoreService:GetSortedMap(MatchmakingDictionary.DEATHMATCH_SERVER_MAP_NAME)

local randomizer = Random.new()

------------------//FUNCTIONS
local function debug_log(message: string): ()
	print("[MatchSession] " .. message)
end

local function set_match_workspace_attribute(isMatch: boolean): ()
	workspace:SetAttribute(MATCH_WORKSPACE_ATTRIBUTE_NAME, isMatch)
end

local function load_data_utility(): ()
	local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")

	if not modulesFolder or not modulesFolder:IsA("Folder") then
		debug_log("ReplicatedStorage.Modules nao encontrado para DataUtility.")
		return
	end

	local utilityFolder = modulesFolder:FindFirstChild("Utility")

	if not utilityFolder or not utilityFolder:IsA("Folder") then
		debug_log("ReplicatedStorage.Modules.Utility nao encontrado para DataUtility.")
		return
	end

	local moduleScript = utilityFolder:FindFirstChild(DATA_UTILITY_MODULE_NAME)

	if not moduleScript or not moduleScript:IsA("ModuleScript") then
		debug_log("DataUtility nao encontrado em ReplicatedStorage.Modules.Utility.")
		return
	end

	local success, result = pcall(function()
		return require(moduleScript)
	end)

	if not success then
		debug_log("Falha ao carregar DataUtility: " .. tostring(result))
		return
	end

	dataUtility = result

	local ensureRemotes = dataUtility and dataUtility.server and dataUtility.server.ensure_remotes

	if ensureRemotes then
		pcall(function()
			ensureRemotes()
		end)
	end

	debug_log("DataUtility carregado.")
end

local function get_opposite_team_name(teamName: string?): string?
	if teamName == TEAM_RED_NAME then
		return TEAM_BLUE_NAME
	end

	if teamName == TEAM_BLUE_NAME then
		return TEAM_RED_NAME
	end

	return nil
end

local function is_deathmatch_config(config: MatchConfig?): boolean
	return config ~= nil and (config.isDeathmatch == true or config.mode == DEATHMATCH_MODE)
end

local function get_player_number_stat(player: Player, path: string, defaultValue: number): number
	if not dataUtility or not dataUtility.server or not dataUtility.server.get then
		return defaultValue
	end

	local getFn = dataUtility.server.get
	local success, result = pcall(function()
		return getFn(player, path)
	end)

	if not success then
		return defaultValue
	end

	if typeof(result) ~= "number" then
		return defaultValue
	end

	return math.floor(result)
end

local function set_player_number_stat(player: Player, path: string, value: number): ()
	if not dataUtility or not dataUtility.server or not dataUtility.server.set then
		return
	end

	local setFn = dataUtility.server.set
	pcall(function()
		setFn(player, path, math.floor(value))
	end)
end

local function get_level_from_xp(totalXp: number): number
	if totalXp <= 0 then
		return 1
	end

	return math.max(1, math.floor(totalXp / XP_PER_LEVEL))
end

local function reward_player_for_kill(player: Player): ()
	local coins = get_player_number_stat(player, "Coins", 0) + KILL_COINS_REWARD
	local xp = get_player_number_stat(player, "XP", 0) + KILL_XP_REWARD
	local level = get_level_from_xp(xp)

	set_player_number_stat(player, "Coins", coins)
	set_player_number_stat(player, "XP", xp)
	set_player_number_stat(player, "Level", level)
	debug_log("Reward kill: " .. player.Name .. " Coins=" .. tostring(coins) .. " XP=" .. tostring(xp) .. " Level=" .. tostring(level))
end

local function add_player_win(player: Player): ()
	local wins = get_player_number_stat(player, "Wins", 0) + 1
	set_player_number_stat(player, "Wins", wins)
	debug_log("Win +1 para " .. player.Name .. " => " .. tostring(wins))
end

local function add_player_lose(player: Player): ()
	local loses = get_player_number_stat(player, "Loses", 0) + 1
	set_player_number_stat(player, "Loses", loses)
	debug_log("Lose +1 para " .. player.Name .. " => " .. tostring(loses))
end

local function get_force_match_value(): BoolValue?
	local value = workspace:FindFirstChild(FORCE_MATCH_VALUE_NAME)

	if value and value:IsA("BoolValue") then
		return value
	end

	return nil
end

local function is_force_match_enabled(): boolean
	local forceMatchValue = get_force_match_value()
	return forceMatchValue ~= nil and forceMatchValue.Value == true
end

local function get_team(teamName: string): Team?
	local team = Teams:FindFirstChild(teamName) :: Team?
	return team
end

local function get_spawn_folder(): Folder?
	local mapFolder = workspace:FindFirstChild(MAP_FOLDER_NAME)

	if not mapFolder then
		return nil
	end

	local spawnFolder = mapFolder:FindFirstChild(MAP_SPAWN_FOLDER_NAME)

	if spawnFolder and spawnFolder:IsA("Folder") then
		return spawnFolder
	end

	return nil
end

local function get_team_spawn_folder(teamName: string): Folder?
	local spawnFolder = get_spawn_folder()

	if not spawnFolder then
		return nil
	end

	local teamFolder = spawnFolder:FindFirstChild(teamName)

	if teamFolder and teamFolder:IsA("Folder") then
		return teamFolder
	end

	return nil
end

local function get_team_spawn_slots(teamName: string): { BasePart }
	local slots: { BasePart } = {}
	local teamFolder = get_team_spawn_folder(teamName)

	if not teamFolder then
		return slots
	end

	for _, child in teamFolder:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(slots, child)
		end
	end

	table.sort(slots, function(a: BasePart, b: BasePart): boolean
		local aNumber = tonumber(a.Name)
		local bNumber = tonumber(b.Name)

		if aNumber and bNumber then
			return aNumber < bNumber
		end

		if aNumber then
			return true
		end

		if bNumber then
			return false
		end

		return a.Name < b.Name
	end)

	return slots
end

local function get_team_spawn_slot(teamName: string, slotIndex: number): BasePart?
	local slots = get_team_spawn_slots(teamName)

	if #slots == 0 then
		return nil
	end

	local index = math.max(1, math.floor(slotIndex))

	if index > #slots then
		index = ((index - 1) % #slots) + 1
	end

	return slots[index]
end

local function clear_workspace_map(): ()
	local mapFolder = workspace:FindFirstChild(MAP_FOLDER_NAME)

	if mapFolder then
		mapFolder:Destroy()
	end
end

local function load_deathmatch_map(): boolean
	local template = ReplicatedStorage:FindFirstChild(DEATHMATCH_MAP_NAME)

	if not template or (not template:IsA("Folder") and not template:IsA("Model")) then
		debug_log("ReplicatedStorage." .. DEATHMATCH_MAP_NAME .. " nao encontrado ou invalido.")
		return false
	end

	clear_workspace_map()

	local mapClone = template:Clone()
	mapClone.Name = MAP_FOLDER_NAME
	mapClone.Parent = workspace
	debug_log("Mapa Deathmatch carregado.")
	return true
end

local function get_deathmatch_spawn_slots(): { BasePart }
	local slots: { BasePart } = {}
	local spawnFolder = get_spawn_folder()

	if not spawnFolder then
		return slots
	end

	for _, child in spawnFolder:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(slots, child)
		end
	end

	table.sort(slots, function(a: BasePart, b: BasePart): boolean
		local aNumber = tonumber(a.Name)
		local bNumber = tonumber(b.Name)

		if aNumber and bNumber then
			return aNumber < bNumber
		end

		if aNumber then
			return true
		end

		if bNumber then
			return false
		end

		return a.Name < b.Name
	end)

	return slots
end

local function get_random_deathmatch_spawn_slot(): BasePart?
	local slots = get_deathmatch_spawn_slots()

	if #slots == 0 then
		return nil
	end

	return slots[randomizer:NextInteger(1, #slots)]
end

local function get_characters_folder(): Folder?
	local folder = workspace:FindFirstChild(CHARACTERS_FOLDER_NAME)

	if folder and folder:IsA("Folder") then
		didWarnMissingCharactersFolder = false
		return folder
	end

	if not didWarnMissingCharactersFolder then
		didWarnMissingCharactersFolder = true
		debug_log("workspace." .. CHARACTERS_FOLDER_NAME .. " ainda nao encontrado.")
	end

	return nil
end

local function get_humanoid(model: Model): Humanoid?
	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if humanoid then
		return humanoid
	end

	return nil
end

local function get_root(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")

	if root and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function set_model_anchored(model: Model, anchored: boolean): ()
	local root = get_root(model)

	if not root then
		return
	end

	local ownerPlayer = Players:GetPlayerFromCharacter(model)

	if ownerPlayer then
		if not anchored then
			root.Anchored = false
		end

		anchorCacheByModel[model] = nil
		return
	end

	if anchored then
		if anchorCacheByModel[model] then
			return
		end

		anchorCacheByModel[model] = {
			rootPart = root,
			anchored = root.Anchored,
		}

		root.Anchored = true
		return
	end

	local cache = anchorCacheByModel[model]

	if cache then
		if cache.rootPart and cache.rootPart.Parent then
			cache.rootPart.Anchored = cache.anchored
		end

		anchorCacheByModel[model] = nil
		return
	end

	root.Anchored = false
end

local function set_participants_anchored(participants: { Participant }, anchored: boolean): ()
	for _, participant in participants do
		set_model_anchored(participant.model, anchored)
	end
end

local function clear_all_anchor_cache(): ()
	for model in anchorCacheByModel do
		set_model_anchored(model, false)
	end
end

local function get_timer_remaining(): number
	if phaseEndsAt <= 0 then
		return 0
	end

	return math.max(0, phaseEndsAt - os.time())
end

local function send_hud_state(player: Player): ()
	local isMatchServer = matchConfig ~= nil
	local mapVotePayload = {}

	if mapVoteService and mapVoteService.get_hud_payload then
		mapVotePayload = mapVoteService.get_hud_payload(player.UserId, phase)
	end

	matchRemote:FireClient(player, "State", {
		isMatch = isMatchServer,
		mode = if isMatchServer and matchConfig then matchConfig.mode else nil,
		source = if isMatchServer then matchSource else "None",
		forceMatchEnabled = is_force_match_enabled(),
		redScore = redScore,
		blueScore = blueScore,
		winnerTeam = winnerTeamName,
		winnerName = winnerName,
		phase = phase,
		round = roundNumber,
		phaseEndsAt = phaseEndsAt,
		timerRemaining = get_timer_remaining(),
		maps = mapVotePayload.maps,
		mapVotes = mapVotePayload.mapVotes,
		mapVoteVoters = mapVotePayload.mapVoteVoters,
		mapVoteOpen = mapVotePayload.mapVoteOpen,
		myMapVote = mapVotePayload.myMapVote,
		myTeamName = mapVotePayload.myTeamName,
		selectedMapId = mapVotePayload.selectedMapId,
		selectedMapName = mapVotePayload.selectedMapName,
	})
end

local function broadcast_hud_state(): ()
	for _, player in Players:GetPlayers() do
		send_hud_state(player)
	end
end

local function set_phase(phaseName: string, durationSeconds: number): ()
	phase = phaseName

	if durationSeconds > 0 then
		phaseEndsAt = os.time() + durationSeconds
	else
		phaseEndsAt = 0
	end

	broadcast_hud_state()
end

local function wait_phase_timer(seconds: number, token: number): ()
	local finishAt = os.clock() + seconds

	while os.clock() < finishAt do
		if token ~= phaseRoundToken then
			return
		end

		task.wait(0.1)
	end
end

local function is_phase_token_valid(token: number): boolean
	return token == phaseRoundToken
end

local function parse_match_config_from_player(player: Player): MatchConfig?
	local joinData = player:GetJoinData()

	if typeof(joinData) ~= "table" then
		return nil
	end

	local teleportData = joinData.TeleportData

	if typeof(teleportData) ~= "table" then
		return nil
	end

	local mode = if typeof(teleportData.mode) == "string" then teleportData.mode else nil

	if not mode then
		return nil
	end

	local modeConfig = MatchmakingDictionary.get_mode(mode)

	if not modeConfig then
		return nil
	end

	local playersRequired = modeConfig.playersRequired

	if typeof(teleportData.playersRequired) == "number" then
		playersRequired = math.max(2, math.floor(teleportData.playersRequired))
	end

	local matchId = if typeof(teleportData.matchId) == "string" then teleportData.matchId else nil
	local isDeathmatch = modeConfig.isDeathmatch == true or teleportData.isDeathmatch == true or mode == DEATHMATCH_MODE
	local deathmatchServerKey = if typeof(teleportData.deathmatchServerKey) == "string" then teleportData.deathmatchServerKey else matchId
	local maxPlayers = if typeof(teleportData.maxPlayers) == "number" then math.max(1, math.floor(teleportData.maxPlayers)) else modeConfig.maxPlayers
	local teamByUserId: { [number]: string }? = nil

	if not isDeathmatch and typeof(teleportData.teamByUserId) == "table" then
		teamByUserId = {}

		for key, value in teleportData.teamByUserId do
			local userId = tonumber(key)

			if userId and typeof(value) == "string" and (value == TEAM_RED_NAME or value == TEAM_BLUE_NAME) then
				teamByUserId[userId] = value
			end
		end
	end

	return {
		mode = mode,
		playersRequired = playersRequired,
		matchId = matchId,
		teamByUserId = teamByUserId,
		isDeathmatch = isDeathmatch,
		deathmatchServerKey = deathmatchServerKey,
		maxPlayers = maxPlayers,
	}
end

local function make_force_match_config(): MatchConfig
	return {
		mode = FORCE_MATCH_MODE,
		playersRequired = FORCE_MATCH_PLAYERS_REQUIRED,
		matchId = "ForceMatch",
		teamByUserId = nil,
	}
end

local function is_valid_participant_model(model: Model): boolean
	local humanoid = get_humanoid(model)
	local root = get_root(model)

	if not humanoid or not root then
		return false
	end

	return humanoid.Health > 0
end

local function get_participant_from_model(model: Model): Participant?
	if not is_valid_participant_model(model) then
		return nil
	end

	local player = Players:GetPlayerFromCharacter(model)
	local teamName = if typeof(model:GetAttribute("MatchTeam")) == "string" then model:GetAttribute("MatchTeam") :: string else nil

	if player and player.Team then
		teamName = player.Team.Name
	end

	return {
		model = model,
		player = player,
		teamName = teamName,
	}
end

local function get_round_participants(): { Participant }
	local participants: { Participant } = {}
	local charactersFolder = get_characters_folder()

	if not charactersFolder then
		return participants
	end

	for _, child in charactersFolder:GetChildren() do
		if child:IsA("Model") then
			local participant = get_participant_from_model(child)

			if participant then
				table.insert(participants, participant)
			end
		end
	end

	return participants
end

local function count_round_participants(): number
	local participants = get_round_participants()
	return #participants
end

local function get_player_team_name(player: Player): string?
	if player.Team then
		local teamName = player.Team.Name

		if teamName == TEAM_RED_NAME or teamName == TEAM_BLUE_NAME then
			return teamName
		end
	end

	local character = player.Character

	if character and character:IsA("Model") then
		local teamNameAttr = character:GetAttribute("MatchTeam")

		if typeof(teamNameAttr) == "string" and (teamNameAttr == TEAM_RED_NAME or teamNameAttr == TEAM_BLUE_NAME) then
			return teamNameAttr
		end
	end

	return nil
end

local function get_current_players_on_team(teamName: string, excludedUserId: number?): { Player }
	local teamPlayers: { Player } = {}

	for _, currentPlayer in Players:GetPlayers() do
		if excludedUserId and currentPlayer.UserId == excludedUserId then
			continue
		end

		if get_player_team_name(currentPlayer) == teamName then
			table.insert(teamPlayers, currentPlayer)
		end
	end

	return teamPlayers
end

local function get_first_remaining_player_name(excludedUserId: number?): string?
	for _, currentPlayer in Players:GetPlayers() do
		if not excludedUserId or currentPlayer.UserId ~= excludedUserId then
			return currentPlayer.Name
		end
	end

	return nil
end

local function apply_match_stats(winnerTeam: string?, loserTeam: string?, excludedLoserUserId: number?): ()
	if matchStatsApplied then
		return
	end

	matchStatsApplied = true

	if not dataUtility then
		return
	end

	if winnerTeam then
		for _, winnerPlayer in get_current_players_on_team(winnerTeam, nil) do
			add_player_win(winnerPlayer)
		end
	elseif excludedLoserUserId then
		for _, winnerPlayer in Players:GetPlayers() do
			if winnerPlayer.UserId ~= excludedLoserUserId then
				add_player_win(winnerPlayer)
			end
		end
	end

	if loserTeam then
		for _, loserPlayer in get_current_players_on_team(loserTeam, nil) do
			if not excludedLoserUserId or loserPlayer.UserId ~= excludedLoserUserId then
				add_player_lose(loserPlayer)
			end
		end
	end
end

local function clear_death_connection(model: Model): ()
	local connection = deathConnections[model]

	if connection then
		connection:Disconnect()
		deathConnections[model] = nil
	end
end

local function clear_all_death_connections(): ()
	for model, connection in deathConnections do
		connection:Disconnect()
		deathConnections[model] = nil
	end
end

local function set_freeze_for_participant(participant: Participant, frozen: boolean): ()
	participant.model:SetAttribute(PLAYER_FROZEN_ATTRIBUTE_NAME, frozen)

	if participant.player then
		participant.player:SetAttribute(PLAYER_FROZEN_ATTRIBUTE_NAME, frozen)
	end

	local humanoid = get_humanoid(participant.model)

	if not humanoid then
		return
	end

	if frozen then
		if not freezeCaches[participant.model] then
			freezeCaches[participant.model] = {
				walkSpeed = humanoid.WalkSpeed,
				useJumpPower = humanoid.UseJumpPower,
				jumpPower = humanoid.JumpPower,
				jumpHeight = humanoid.JumpHeight,
				autoRotate = humanoid.AutoRotate,
			}
		end

		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
		humanoid.Jump = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

		if humanoid.UseJumpPower then
			humanoid.JumpPower = 0
		else
			humanoid.JumpHeight = 0
		end

		return
	end

	local cache = freezeCaches[participant.model]
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

	if cache then
		humanoid.WalkSpeed = cache.walkSpeed
		humanoid.AutoRotate = cache.autoRotate
		humanoid.UseJumpPower = cache.useJumpPower

		if cache.useJumpPower then
			humanoid.JumpPower = cache.jumpPower
		else
			humanoid.JumpHeight = cache.jumpHeight
		end

		freezeCaches[participant.model] = nil
		return
	end

	humanoid.WalkSpeed = 16
	humanoid.AutoRotate = true

	if humanoid.UseJumpPower then
		humanoid.JumpPower = 50
	else
		humanoid.JumpHeight = 7.2
	end
end

local function set_freeze_for_all(participants: { Participant }, frozen: boolean): ()
	for _, participant in participants do
		set_freeze_for_participant(participant, frozen)
	end
end

local function set_participant_team(participant: Participant, teamName: string): ()
	local team = get_team(teamName)

	if not team then
		return
	end

	participant.teamName = teamName
	participant.model:SetAttribute("MatchTeam", teamName)

	if participant.player then
		participant.player.Team = team
		participant.player.Neutral = false
	end
end

local function assign_teams_random(participants: { Participant }): ()
	local lockedTeamByUserId = if matchConfig then matchConfig.teamByUserId else nil
	local unlocked: { Participant } = {}
	local redCount = 0
	local blueCount = 0

	for _, participant in participants do
		local lockedTeamName: string? = nil

		if lockedTeamByUserId and participant.player then
			lockedTeamName = lockedTeamByUserId[participant.player.UserId]
		end

		if lockedTeamName == TEAM_RED_NAME then
			set_participant_team(participant, TEAM_RED_NAME)
			redCount += 1
			continue
		end

		if lockedTeamName == TEAM_BLUE_NAME then
			set_participant_team(participant, TEAM_BLUE_NAME)
			blueCount += 1
			continue
		end

		table.insert(unlocked, participant)
	end

	local pool = table.clone(unlocked)

	while #pool > 0 do
		local pickIndex = randomizer:NextInteger(1, #pool)
		local participant = table.remove(pool, pickIndex)
		local teamName = TEAM_RED_NAME

		if redCount == blueCount then
			if randomizer:NextNumber() < 0.5 then
				teamName = TEAM_RED_NAME
			else
				teamName = TEAM_BLUE_NAME
			end
		elseif redCount > blueCount then
			teamName = TEAM_BLUE_NAME
		end

		set_participant_team(participant, teamName)

		if teamName == TEAM_RED_NAME then
			redCount += 1
		else
			blueCount += 1
		end
	end
end

local function move_participant_to_spawn(participant: Participant, preferredSlot: number?): ()
	if not participant.teamName then
		return
	end

	local slotIndex = preferredSlot or 1
	local spawnPart = get_team_spawn_slot(participant.teamName, slotIndex)

	if not spawnPart then
		return
	end

	local root = get_root(participant.model)

	if not root then
		return
	end

	local targetCFrame = spawnPart.CFrame * CFrame.new(0, 3, 0)
	participant.model:PivotTo(targetCFrame)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

local function move_all_to_spawn(participants: { Participant }): ()
	local byTeam: { [string]: { Participant } } = {
		[TEAM_RED_NAME] = {},
		[TEAM_BLUE_NAME] = {},
	}

	for _, participant in participants do
		if participant.teamName == TEAM_RED_NAME then
			table.insert(byTeam[TEAM_RED_NAME], participant)
			continue
		end

		if participant.teamName == TEAM_BLUE_NAME then
			table.insert(byTeam[TEAM_BLUE_NAME], participant)
		end
	end

	for _, teamName in { TEAM_RED_NAME, TEAM_BLUE_NAME } do
		local teamParticipants = byTeam[teamName]

		for index, participant in teamParticipants do
			move_participant_to_spawn(participant, index)
		end
	end
end

local function respawn_players_for_round(): ()
	for _, player in Players:GetPlayers() do
		player:LoadCharacter()
	end
end

local function get_loaded_players_in_characters(): (number, number)
	local loadedCount = 0
	local totalPlayers = #Players:GetPlayers()
	local charactersFolder = get_characters_folder()

	if not charactersFolder then
		return 0, totalPlayers
	end

	for _, player in Players:GetPlayers() do
		local character = player.Character

		if character and character.Parent == charactersFolder and get_humanoid(character) and get_root(character) then
			loadedCount += 1
		end
	end

	return loadedCount, totalPlayers
end

local function wait_round_participants_ready(token: number): boolean
	local finishAt = os.clock() + ROUND_RESPAWN_WAIT

	while os.clock() < finishAt do
		if token ~= phaseRoundToken or not matchRunning then
			return false
		end

		local participants = get_round_participants()

		if #participants >= 2 then
			return true
		end

		task.wait(0.1)
	end

	return count_round_participants() >= 2
end

local function apply_freeze_spawn_start(token: number): ()
	if token ~= phaseRoundToken or not matchRunning then
		return
	end

	local participants = get_round_participants()

	if #participants == 0 then
		return
	end

	move_all_to_spawn(participants)
	set_participants_anchored(participants, true)
	set_freeze_for_all(participants, true)

	task.delay(0.2, function()
		if token ~= phaseRoundToken or not matchRunning or phase ~= "Freeze" then
			return
		end

		local refreshParticipants = get_round_participants()

		if #refreshParticipants == 0 then
			return
		end

		move_all_to_spawn(refreshParticipants)
		set_participants_anchored(refreshParticipants, true)
		set_freeze_for_all(refreshParticipants, true)
	end)
end

local function resolve_round_by_death(token: number, deadTeamName: string?): ()
	if token ~= phaseRoundToken or phase ~= "Round" or pendingRoundWinner ~= nil then
		return
	end

	if deadTeamName == TEAM_RED_NAME then
		pendingRoundWinner = TEAM_BLUE_NAME
		return
	end

	if deadTeamName == TEAM_BLUE_NAME then
		pendingRoundWinner = TEAM_RED_NAME
	end
end

local function force_end_match_by_quit(player: Player): ()
	if not matchConfig or matchStatsApplied then
		return
	end

	if string.sub(phase, 1, 8) == "Finished" or phase == "MatchCancelled" then
		return
	end

	if matchEndedByQuit then
		return
	end

	local quitterTeam = get_player_team_name(player)
	local winnerTeam = get_opposite_team_name(quitterTeam)
	local loserTeam = quitterTeam

	if not winnerTeam then
		local redPlayers = get_current_players_on_team(TEAM_RED_NAME, player.UserId)
		local bluePlayers = get_current_players_on_team(TEAM_BLUE_NAME, player.UserId)

		if #redPlayers > 0 and #bluePlayers == 0 then
			winnerTeam = TEAM_RED_NAME
			loserTeam = TEAM_BLUE_NAME
		elseif #bluePlayers > 0 and #redPlayers == 0 then
			winnerTeam = TEAM_BLUE_NAME
			loserTeam = TEAM_RED_NAME
		end
	end

	matchEndedByQuit = true
	quitWinnerTeamName = winnerTeam
	quitLoserTeamName = loserTeam
	quitLoserUserId = player.UserId
	quitWinnerName = get_first_remaining_player_name(player.UserId)

	if winnerTeam == TEAM_RED_NAME then
		redScore = math.max(redScore, WIN_SCORE)
	elseif winnerTeam == TEAM_BLUE_NAME then
		blueScore = math.max(blueScore, WIN_SCORE)
	end

	add_player_lose(player)
	matchRunning = false
	phaseRoundToken += 1

	debug_log("Partida encerrada por quit de " .. player.Name .. ".")
end

local function bind_death_for_participant(participant: Participant, token: number): ()
	clear_death_connection(participant.model)

	local humanoid = get_humanoid(participant.model)

	if not humanoid then
		return
	end

	deathConnections[participant.model] = humanoid.Died:Connect(function()
		local creator = humanoid:FindFirstChild("creator")

		if matchRunning and phase == "Round" and creator and creator:IsA("ObjectValue") and creator.Value and creator.Value:IsA("Player") then
			local killerPlayer = creator.Value :: Player

			if not participant.player or killerPlayer.UserId ~= participant.player.UserId then
				reward_player_for_kill(killerPlayer)
			end
		end

		resolve_round_by_death(token, participant.teamName)
	end)
end

local function bind_deaths_for_round(participants: { Participant }, token: number): ()
	for _, participant in participants do
		bind_death_for_participant(participant, token)
	end
end

local function update_deathmatch_registry(): ()
	if not is_deathmatch_config(matchConfig) then
		return
	end

	local serverKey = matchConfig.deathmatchServerKey or matchConfig.matchId

	if not serverKey or serverKey == "" then
		return
	end

	pcall(function()
		deathmatchServerMap:UpdateAsync(serverKey, function(oldValue: any, oldSortKey: any)
			if typeof(oldValue) ~= "table" then
				return oldValue, oldSortKey
			end

			local record = oldValue
			local maxPlayers = matchConfig and matchConfig.maxPlayers or record.maxPlayers

			record.mode = DEATHMATCH_MODE
			record.currentPlayers = #Players:GetPlayers()
			record.maxPlayers = if typeof(maxPlayers) == "number" then math.max(1, math.floor(maxPlayers)) else DEATHMATCH_MAX_PLAYERS
			record.updatedAt = os.time()
			return record, record.currentPlayers
		end, DEATHMATCH_SERVER_TTL)
	end)
end

local function move_character_to_deathmatch_spawn(character: Model): ()
	local root = get_root(character)
	local spawnPart = get_random_deathmatch_spawn_slot()

	if not root or not spawnPart then
		return
	end

	character:PivotTo(spawnPart.CFrame * CFrame.new(0, 3, 0))
end

local function bind_deathmatch_death(player: Player, character: Model): ()
	clear_death_connection(character)

	local humanoid = get_humanoid(character)

	if not humanoid then
		return
	end

	deathConnections[character] = humanoid.Died:Connect(function()
		local creator = humanoid:FindFirstChild("creator")

		if creator and creator:IsA("ObjectValue") and creator.Value and creator.Value:IsA("Player") then
			local killerPlayer = creator.Value :: Player

			if killerPlayer.UserId ~= player.UserId then
				reward_player_for_kill(killerPlayer)
			end
		end

		task.delay(DEATHMATCH_RESPAWN_DELAY, function()
			if not is_deathmatch_config(matchConfig) or not player.Parent then
				return
			end

			player:LoadCharacter()
		end)
	end)
end

local function configure_deathmatch_character(player: Player, character: Model): ()
	task.defer(function()
		if not is_deathmatch_config(matchConfig) or not character.Parent then
			return
		end

		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)

		if not humanoid or not root then
			return
		end

		player.Neutral = true
		character:SetAttribute("MatchTeam", nil)

		local participant: Participant = {
			model = character,
			player = player,
			teamName = nil,
		}

		set_freeze_for_participant(participant, false)
		set_model_anchored(character, false)
		move_character_to_deathmatch_spawn(character)
		bind_deathmatch_death(player, character)
	end)
end

local function run_deathmatch(): ()
	if not load_deathmatch_map() then
		matchRunning = false
		set_match_workspace_attribute(false)
		set_phase("MatchCancelled", 0)
		return
	end

	clear_all_death_connections()
	clear_all_anchor_cache()
	set_phase("Deathmatch", 0)
	broadcast_hud_state()

	for _, player in Players:GetPlayers() do
		player.Neutral = true
		player:LoadCharacter()
	end

	update_deathmatch_registry()

	while matchRunning and is_deathmatch_config(matchConfig) do
		task.wait(DEATHMATCH_REGISTRY_UPDATE_INTERVAL)
		update_deathmatch_registry()
	end
end

local function apply_round_winner_score(teamName: string?): ()
	if not teamName then
		return
	end

	if teamName == TEAM_RED_NAME then
		redScore += 1
		return
	end

	if teamName == TEAM_BLUE_NAME then
		blueScore += 1
	end
end

local function round_has_winner_score(): boolean
	return redScore >= WIN_SCORE or blueScore >= WIN_SCORE
end

local function teleport_players_to_public_lobby(): boolean
	set_match_workspace_attribute(false)

	local playersToTeleport = Players:GetPlayers()

	if #playersToTeleport == 0 then
		return true
	end

	local success, result = pcall(function()
		return TeleportService:TeleportAsync(game.PlaceId, playersToTeleport)
	end)

	if success then
		debug_log("Jogadores enviados para lobby publico.")
		return true
	end

	debug_log("Falha ao teleportar para lobby publico: " .. tostring(result))
	return false
end

local function get_winner_name_for_team(teamName: string): string
	local participants = get_round_participants()

	for _, participant in participants do
		if participant.teamName == teamName then
			if participant.player then
				return participant.player.Name
			end

			return participant.model.Name
		end
	end

	return teamName
end

local function run_round(token: number): boolean
	respawn_players_for_round()

	if not wait_round_participants_ready(token) then
		return false
	end

	if token ~= phaseRoundToken or not matchRunning then
		return false
	end

	local participants = get_round_participants()

	if #participants < 2 then
		return false
	end

	-- trava ANTES de qualquer coisa, para o jogador nunca andar no carregamento
	set_participants_anchored(participants, true)
	set_freeze_for_all(participants, true)

	assign_teams_random(participants)
	set_phase("Freeze", FREEZE_TIME)
	apply_freeze_spawn_start(token)
	wait_phase_timer(FREEZE_TIME, token)

	if token ~= phaseRoundToken or not matchRunning then
		return false
	end

	pendingRoundWinner = nil
	clear_all_death_connections()
	bind_deaths_for_round(participants, token)
	set_participants_anchored(participants, false)
	set_freeze_for_all(participants, false)

	set_phase("Round", ROUND_TIME)

	local roundStart = os.clock()

	while os.clock() - roundStart < ROUND_TIME do
		if token ~= phaseRoundToken or not matchRunning then
			return false
		end

		if pendingRoundWinner ~= nil then
			break
		end

		task.wait(0.1)
	end

	apply_round_winner_score(pendingRoundWinner)
	clear_all_death_connections()

	if token ~= phaseRoundToken or not matchRunning then
		return false
	end

	set_phase("RoundBreak", ROUND_BREAK_TIME)
	set_participants_anchored(participants, false)
	set_freeze_for_all(participants, false)
	wait_phase_timer(ROUND_BREAK_TIME, token)

	return token == phaseRoundToken and matchRunning
end

local function start_match_if_needed(): ()
	if matchStarted or not matchConfig then
		return
	end

	matchStarted = true
	matchRunning = true
	set_match_workspace_attribute(true)
	redScore = 0
	blueScore = 0
	roundNumber = 0
	phaseRoundToken += 1
	winnerTeamName = nil
	winnerName = nil
	quitWinnerTeamName = nil
	quitLoserTeamName = nil
	quitWinnerName = nil
	quitLoserUserId = nil
	matchEndedByQuit = false
	matchStatsApplied = false

	if mapVoteService then
		mapVoteService.reset_votes()
	end

	if is_deathmatch_config(matchConfig) then
		run_deathmatch()
		return
	end

	if not get_team(TEAM_RED_NAME) or not get_team(TEAM_BLUE_NAME) then
		matchRunning = false
		set_match_workspace_attribute(false)
		set_phase("MatchCancelled", 0)
		clear_all_death_connections()
		set_freeze_for_all(get_round_participants(), false)
		clear_all_anchor_cache()
		debug_log("Times Red/Blue nao encontrados em Teams.")
		return
	end

	respawn_players_for_round()
	phaseRoundToken += 1
	local setupToken = phaseRoundToken

	local loadedForVote = mapVoteService and mapVoteService.wait_players_loaded_for_vote(setupToken) or false

	if not loadedForVote and not matchEndedByQuit then
		matchRunning = false
		set_match_workspace_attribute(false)
		set_phase("MatchCancelled", 0)
		clear_all_death_connections()
		set_freeze_for_all(get_round_participants(), false)
		clear_all_anchor_cache()
		debug_log("Partida cancelada por falta de jogadores carregados.")
		return
	end

	local ranVote = mapVoteService and mapVoteService.run_vote_and_load_map(setupToken) or false

	if not ranVote and not matchEndedByQuit then
		matchRunning = false
		set_match_workspace_attribute(false)
		set_phase("MatchCancelled", 0)
		clear_all_death_connections()
		set_freeze_for_all(get_round_participants(), false)
		clear_all_anchor_cache()
		debug_log("Partida cancelada ao executar votacao de mapa.")
		return
	end

	if matchRunning and (not get_team_spawn_slot(TEAM_RED_NAME, 1) or not get_team_spawn_slot(TEAM_BLUE_NAME, 1)) then
		matchRunning = false
		set_match_workspace_attribute(false)
		set_phase("MatchCancelled", 0)
		clear_all_death_connections()
		set_freeze_for_all(get_round_participants(), false)
		clear_all_anchor_cache()
		debug_log("Slots de spawn Red/Blue nao encontrados no mapa escolhido.")
		return
	end

	if matchRunning and count_round_participants() < 2 and not matchEndedByQuit then
		matchRunning = false
		set_match_workspace_attribute(false)
		set_phase("MatchCancelled", 0)
		clear_all_death_connections()
		set_freeze_for_all(get_round_participants(), false)
		clear_all_anchor_cache()
		debug_log("Partida cancelada por falta de participantes.")
		return
	end

	while matchRunning do
		if count_round_participants() < 2 then
			break
		end

		roundNumber += 1
		phaseRoundToken += 1
		local token = phaseRoundToken

		local roundDone = run_round(token)

		if not roundDone then
			break
		end

		if round_has_winner_score() then
			break
		end
	end

	matchRunning = false
	clear_all_death_connections()
	set_freeze_for_all(get_round_participants(), false)
	clear_all_anchor_cache()

	local finalWinnerTeamName = "Draw"
	local finalLoserTeamName: string? = nil
	local finalWinnerNameOverride: string? = nil

	if matchEndedByQuit then
		if quitWinnerTeamName then
			finalWinnerTeamName = quitWinnerTeamName
		elseif redScore > blueScore then
			finalWinnerTeamName = TEAM_RED_NAME
		elseif blueScore > redScore then
			finalWinnerTeamName = TEAM_BLUE_NAME
		end

		finalLoserTeamName = quitLoserTeamName or get_opposite_team_name(finalWinnerTeamName)
		finalWinnerNameOverride = quitWinnerName
	else
		if redScore > blueScore then
			finalWinnerTeamName = TEAM_RED_NAME
		elseif blueScore > redScore then
			finalWinnerTeamName = TEAM_BLUE_NAME
		end

		if finalWinnerTeamName ~= "Draw" then
			finalLoserTeamName = get_opposite_team_name(finalWinnerTeamName)
		end
	end

	if finalWinnerTeamName ~= "Draw" then
		apply_match_stats(finalWinnerTeamName, finalLoserTeamName, quitLoserUserId)
		winnerTeamName = finalWinnerTeamName
		winnerName = finalWinnerNameOverride or get_winner_name_for_team(finalWinnerTeamName)
		set_phase("MatchWin", WIN_SHOW_TIME)
		wait_phase_timer(WIN_SHOW_TIME, phaseRoundToken)
		if matchEndedByQuit then
			set_phase("FinishedQuit:" .. finalWinnerTeamName, 0)
		else
			set_phase("Finished:" .. finalWinnerTeamName, 0)
		end
		teleport_players_to_public_lobby()
		return
	end

	if matchEndedByQuit then
		apply_match_stats(nil, finalLoserTeamName, quitLoserUserId)
		winnerTeamName = "Quit"
		winnerName = finalWinnerNameOverride or "Winner"
		set_phase("MatchWin", WIN_SHOW_TIME)
		wait_phase_timer(WIN_SHOW_TIME, phaseRoundToken)
		set_phase("FinishedQuit", 0)
		teleport_players_to_public_lobby()
		return
	end

	winnerTeamName = "Draw"
	winnerName = "Draw"
	set_phase("Finished:Draw", 0)
	teleport_players_to_public_lobby()
end

local function try_enable_force_match(): ()
	if matchConfig or matchStarted then
		return
	end

	if not is_force_match_enabled() then
		return
	end

	if #Players:GetPlayers() == 0 then
		return
	end

	matchConfig = make_force_match_config()
	matchSource = "ForceMatch"
	set_match_workspace_attribute(true)
	debug_log("ForceMatch habilitado.")
	task.spawn(start_match_if_needed)
end

local function on_character_added(player: Player, character: Model): ()
	if not matchConfig then
		return
	end

	if is_deathmatch_config(matchConfig) then
		configure_deathmatch_character(player, character)
		return
	end

	task.defer(function()
		local participant: Participant = {
			model = character,
			player = player,
			teamName = if player.Team then player.Team.Name else nil,
		}

		local shouldFreeze = phase == "LoadingPlayers" or phase == "MapVote" or phase == "Freeze"

		if shouldFreeze then
			set_freeze_for_participant(participant, true)
			set_model_anchored(participant.model, true)
		else
			set_freeze_for_participant(participant, false)
			set_model_anchored(participant.model, false)
		end

		if participant.teamName == TEAM_RED_NAME or participant.teamName == TEAM_BLUE_NAME then
			move_participant_to_spawn(participant)
		end

		if matchRunning and phase == "Round" then
			bind_death_for_participant(participant, phaseRoundToken)
		end
	end)
end

local function on_player_added(player: Player): ()
	local parsedConfig = parse_match_config_from_player(player)
	local detectedSource = "None"

	if parsedConfig then
		detectedSource = "TeleportData"
	end

	if not parsedConfig and is_force_match_enabled() then
		parsedConfig = make_force_match_config()
		detectedSource = "ForceMatch"
	end

	if parsedConfig and not matchConfig then
		matchConfig = parsedConfig
		matchSource = detectedSource
		set_match_workspace_attribute(true)
		debug_log("Partida detectada: " .. parsedConfig.mode .. " / " .. tostring(parsedConfig.playersRequired) .. " jogadores.")
		task.spawn(start_match_if_needed)
	end

	player.CharacterAdded:Connect(function(character: Model)
		on_character_added(player, character)
	end)

	if matchConfig and is_deathmatch_config(matchConfig) then
		if player.Character then
			configure_deathmatch_character(player, player.Character)
		end

		update_deathmatch_registry()
	end

	send_hud_state(player)
end

local function on_player_removing(player: Player): ()
	local removedVote = false

	if mapVoteService and mapVoteService.remove_player_vote then
		removedVote = mapVoteService.remove_player_vote(player.UserId) == true
	end

	local character = player.Character

	if character and character:IsA("Model") then
		clear_death_connection(character)
		freezeCaches[character] = nil
		set_model_anchored(character, false)
		anchorCacheByModel[character] = nil
	end

	if matchConfig and is_deathmatch_config(matchConfig) then
		task.defer(update_deathmatch_registry)
	elseif matchConfig and matchStarted and not matchStatsApplied then
		force_end_match_by_quit(player)
	end

	if removedVote then
		broadcast_hud_state()
	end
end

local function configure_map_vote_service(): ()
	mapVoteService = MapVoteService.create({
		debugLog = debug_log,
		broadcastHudState = broadcast_hud_state,
		setPhase = set_phase,
		waitPhaseTimer = wait_phase_timer,
		getRoundParticipants = get_round_participants,
		setParticipantsAnchored = set_participants_anchored,
		setFreezeForAll = set_freeze_for_all,
		getLoadedPlayersInCharacters = get_loaded_players_in_characters,
		isMatchRunning = function(): boolean
			return matchRunning and matchConfig ~= nil
		end,
		isTokenValid = is_phase_token_valid,
		getVoteTeamName = function(userId: number): string?
			if matchConfig and matchConfig.teamByUserId and matchConfig.teamByUserId[userId] then
				return matchConfig.teamByUserId[userId]
			end

			local targetPlayer = Players:GetPlayerByUserId(userId)

			if targetPlayer then
				return get_player_team_name(targetPlayer)
			end

			return nil
		end,
	}, {
		loadTimeout = LOAD_TIMEOUT,
		mapVoteTime = MAP_VOTE_TIME,
	})

	MapVoteBridge.set_handler(function(player: Player, mapId: string): ()
		if not mapVoteService then
			return
		end

		mapVoteService.register_vote(player, mapId, phase)
	end)
end

------------------//MAIN FUNCTIONS
load_data_utility()
set_match_workspace_attribute(false)
configure_map_vote_service()

for _, team in Teams:GetTeams() do
	if team.Name == TEAM_RED_NAME or team.Name == TEAM_BLUE_NAME then
		team.AutoAssignable = false
	end
end

for _, player in Players:GetPlayers() do
	on_player_added(player)
end

Players.PlayerAdded:Connect(on_player_added)
Players.PlayerRemoving:Connect(on_player_removing)

local forceMatchValue = get_force_match_value()

if forceMatchValue then
	forceMatchValue:GetPropertyChangedSignal("Value"):Connect(function()
		try_enable_force_match()
	end)
end

try_enable_force_match()

task.spawn(function()
	while true do
		if matchConfig then
			broadcast_hud_state()
		end

		task.wait(1)
	end
end)

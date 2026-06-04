------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")
local MemoryStoreService: MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService: TeleportService = game:GetService("TeleportService")
local HttpService: HttpService = game:GetService("HttpService")
local RunService: RunService = game:GetService("RunService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local PartyService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("PartyService"))
local MatchCreationService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("MatchCreationService"))

local SOURCE_JOB_ID = if game.JobId ~= "" then game.JobId else "Studio_" .. tostring(game.PlaceId)

local QUEUE_ENTRY_TTL = 1800
local PLAYER_STATE_TTL = 300
local ASSIGNMENT_TTL = 120
local PLAYER_STATE_STALE_SECONDS = 240
local MODE_COUNT_TTL = 600

local MATCH_SCAN_INTERVAL = 5
local MODE_SCAN_SPACING = 0.25
local ASSIGNMENT_SCAN_INTERVAL = 2
local STATE_REFRESH_INTERVAL = 120
local QUEUE_COUNT_REFRESH_INTERVAL = 10
local QUEUE_COUNT_FAST_REFRESH_INTERVAL = 1
local REQUEST_COOLDOWN = 1
local MAX_ASSIGNMENTS_PER_READ = 10
local MAX_TICKETS_READ_PER_MODE = 20
local MAX_GROUPS_FOR_COMBINATION = 14
local DEATHMATCH_MODE = MatchmakingDictionary.DEATHMATCH_MODE
local DEATHMATCH_SERVER_STALE_SECONDS = MatchmakingDictionary.DEATHMATCH_SERVER_STALE_SECONDS
local DEATHMATCH_QUEUE_REFRESH_BINDABLE_NAME = "DeathmatchQueueRefreshRequest"

------------------//VARIABLES
type LocalQueueState = {
	mode: string,
	ticketId: string,
	groupId: string,
	leaderUserId: number,
	queuedAt: number,
	teleporting: boolean,
}

type LocalQueuedGroup = {
	groupId: string,
	mode: string,
	behavior: string,
	leaderUserId: number,
	userIds: { number },
	queuedAt: number,
	teleporting: boolean,
}

type QueueTicket = {
	userId: number,
	mode: string,
	sourceJobId: string,
	ticketId: string,
	groupId: string,
	groupLeaderUserId: number,
	groupUserIds: { number },
	behavior: string,
	groupSize: number,
	queuedAt: number,
}

type TicketGroup = {
	groupId: string,
	mode: string,
	sourceJobId: string,
	behavior: string,
	leaderUserId: number,
	userIds: { number },
	queuedAt: number,
	tickets: { QueueTicket },
}

type MatchAssignment = {
	matchId: string,
	mode: string,
	teamSize: number,
	playersRequired: number,
	placeId: number,
	reservedServerAccessCode: string,
	privateServerId: string,
	users: { number },
	localUsers: { number },
	teamByUserId: { [string]: string },
	groupBehaviorById: { [string]: string },
	createdAt: number,
}

type ModeConfig = MatchmakingDictionary.ModeConfig
type QueueCounts = { [string]: number }

local remotesFolderInstance: Folder? = ReplicatedStorage:FindFirstChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder?

if not remotesFolderInstance then
	remotesFolderInstance = Instance.new("Folder")
	remotesFolderInstance.Name = MatchmakingDictionary.REMOTE_FOLDER_NAME
	remotesFolderInstance.Parent = ReplicatedStorage
end

local remotesFolder: Folder = remotesFolderInstance :: Folder
local remoteEventInstance: RemoteEvent? = remotesFolder:FindFirstChild(MatchmakingDictionary.REMOTE_EVENT_NAME) :: RemoteEvent?

if not remoteEventInstance then
	remoteEventInstance = Instance.new("RemoteEvent")
	remoteEventInstance.Name = MatchmakingDictionary.REMOTE_EVENT_NAME
	remoteEventInstance.Parent = remotesFolder
end

local remoteEvent: RemoteEvent = remoteEventInstance :: RemoteEvent
local playerStateMap: MemoryStoreHashMap = MemoryStoreService:GetHashMap(MatchmakingDictionary.PLAYER_STATE_MAP_NAME)
local assignmentQueue: MemoryStoreQueue = MemoryStoreService:GetQueue(
	MatchmakingDictionary.get_assignment_queue_name(SOURCE_JOB_ID),
	MatchmakingDictionary.ASSIGNMENT_QUEUE_INVISIBILITY_TIMEOUT
)

local matchQueues: { [string]: MemoryStoreQueue } = {}
local localQueuedPlayers: { [number]: LocalQueueState } = {}
local localQueuedGroups: { [string]: LocalQueuedGroup } = {}
local localQueuedModeCounts: { [string]: number } = {}
local lastRequests: { [number]: number } = {}
local currentQueueCounts: QueueCounts = {}
local queueCountsNeedsRefresh = true

for _, modeConfig in MatchmakingDictionary.get_modes() do
	currentQueueCounts[modeConfig.mode] = 0
end

local modeCountMap: MemoryStoreHashMap = MemoryStoreService:GetHashMap("MatchmakingModeCount_v2")
local deathmatchServerMap = MemoryStoreService:GetSortedMap(MatchmakingDictionary.DEATHMATCH_SERVER_MAP_NAME)
local deathmatchQueueRefreshEventInstance: BindableEvent? = ServerStorage:FindFirstChild(DEATHMATCH_QUEUE_REFRESH_BINDABLE_NAME) :: BindableEvent?

if not deathmatchQueueRefreshEventInstance then
	deathmatchQueueRefreshEventInstance = Instance.new("BindableEvent")
	deathmatchQueueRefreshEventInstance.Name = DEATHMATCH_QUEUE_REFRESH_BINDABLE_NAME
	deathmatchQueueRefreshEventInstance.Parent = ServerStorage
end

local deathmatchQueueRefreshEvent: BindableEvent = deathmatchQueueRefreshEventInstance :: BindableEvent

------------------//FUNCTIONS
local function debug_log(message: string): ()
	print(MatchmakingDictionary.DEBUG_PREFIX .. " " .. message)
end

local function debug_player(player: Player, message: string, colorName: string?): ()
	debug_log(player.Name .. ": " .. message)
	remoteEvent:FireClient(player, "Debug", {
		message = message,
		colorName = colorName or "Info",
	})
end

local function debug_group_players(userIds: { number }, message: string, colorName: string?): ()
	for _, userId in userIds do
		local player = Players:GetPlayerByUserId(userId)

		if player then
			debug_player(player, message, colorName)
		end
	end
end

local function clone_queue_counts(): QueueCounts
	local copy: QueueCounts = {}

	for mode, countValue in currentQueueCounts do
		copy[mode] = countValue
	end

	return copy
end

local function send_queue_counts(player: Player): ()
	remoteEvent:FireClient(player, "QueueCounts", clone_queue_counts())
end

local function broadcast_queue_counts(): ()
	for _, player in Players:GetPlayers() do
		send_queue_counts(player)
	end
end

local function send_state(player: Player, state: LocalQueueState?): ()
	player:SetAttribute("IsMatchmakingQueued", state ~= nil)
	player:SetAttribute("MatchmakingMode", state and state.mode or nil)

	remoteEvent:FireClient(player, "State", {
		isQueued = state ~= nil,
		mode = state and state.mode or nil,
		queuedAt = state and state.queuedAt or nil,
		teleporting = state and state.teleporting == true or false,
	})
end

local function build_empty_queue_counts(): QueueCounts
	local counts: QueueCounts = {}

	for _, modeConfig in MatchmakingDictionary.get_modes() do
		counts[modeConfig.mode] = 0
	end

	return counts
end

local function get_mode_count_key(mode: string): string
	return "mode_" .. mode
end

local function read_mode_count(mode: string): number
	local success, result = pcall(function()
		return modeCountMap:GetAsync(get_mode_count_key(mode))
	end)

	if not success then
		debug_log("Falha ao ler contador do modo " .. mode .. ": " .. tostring(result))
		return 0
	end

	if typeof(result) == "number" then
		return math.max(0, math.floor(result))
	end

	return 0
end

local function is_fresh_deathmatch_record(record: any): boolean
	if typeof(record) ~= "table" then
		return false
	end

	if record.mode ~= DEATHMATCH_MODE then
		return false
	end

	if typeof(record.reservedServerAccessCode) ~= "string" or record.reservedServerAccessCode == "" then
		return false
	end

	if typeof(record.updatedAt) ~= "number" then
		return false
	end

	return os.time() - record.updatedAt <= DEATHMATCH_SERVER_STALE_SECONDS
end

local function read_deathmatch_server_entries(): { any }
	local success, entries = pcall(function()
		return deathmatchServerMap:GetRangeAsync(Enum.SortDirection.Ascending, 100)
	end)

	if not success or typeof(entries) ~= "table" then
		if not success then
			debug_log("Falha ao ler servidores Deathmatch: " .. tostring(entries))
		end

		return {}
	end

	return entries
end

local function read_deathmatch_total_count(): number
	local total = 0

	for _, entry in read_deathmatch_server_entries() do
		local record = entry.value

		if is_fresh_deathmatch_record(record) and typeof(record.currentPlayers) == "number" then
			total += math.max(0, math.floor(record.currentPlayers))
		end
	end

	return total
end

local function change_global_mode_count(mode: string, amount: number): ()
	if amount == 0 then
		return
	end

	local success, result = pcall(function()
		return modeCountMap:UpdateAsync(get_mode_count_key(mode), function(oldValue: any)
			local base = 0

			if typeof(oldValue) == "number" then
				base = oldValue
			end

			local nextValue = math.max(0, math.floor(base + amount))
			return nextValue
		end, MODE_COUNT_TTL)
	end)

	if not success then
		debug_log("Falha ao atualizar contador do modo " .. mode .. ": " .. tostring(result))
	end
end

local function refresh_queue_counts(forceBroadcast: boolean?): ()
	local nextCounts = build_empty_queue_counts()
	local changed = false

	for _, modeConfig in MatchmakingDictionary.get_modes() do
		local nextValue = if modeConfig.isDeathmatch then read_deathmatch_total_count() else read_mode_count(modeConfig.mode)
		nextCounts[modeConfig.mode] = nextValue

		if currentQueueCounts[modeConfig.mode] ~= nextValue then
			changed = true
		end
	end

	currentQueueCounts = nextCounts

	if changed or forceBroadcast then
		broadcast_queue_counts()
	end
end

local function request_queue_count_refresh(): ()
	queueCountsNeedsRefresh = true
end

deathmatchQueueRefreshEvent.Event:Connect(request_queue_count_refresh)

local function get_match_queue(mode: string): MemoryStoreQueue
	local queue = matchQueues[mode]

	if queue then
		return queue
	end

	queue = MemoryStoreService:GetQueue(
		MatchmakingDictionary.get_match_queue_name(mode),
		MatchmakingDictionary.MATCH_QUEUE_INVISIBILITY_TIMEOUT
	)

	matchQueues[mode] = queue
	return queue
end

local function get_player_state_value(player: Player, state: LocalQueueState): { [string]: any }
	return {
		userId = player.UserId,
		mode = state.mode,
		sourceJobId = SOURCE_JOB_ID,
		ticketId = state.ticketId,
		groupId = state.groupId,
		queuedAt = state.queuedAt,
		updatedAt = os.time(),
	}
end

local function write_player_state(player: Player, state: LocalQueueState): boolean
	local key = MatchmakingDictionary.get_player_key(player.UserId)
	local value = get_player_state_value(player, state)
	local success, result = pcall(function()
		playerStateMap:SetAsync(key, value, PLAYER_STATE_TTL)
	end)

	if not success then
		debug_player(player, "Falha ao salvar estado no MemoryStore: " .. tostring(result), "Error")
		return false
	end

	return true
end

local function remove_player_state(userId: number): ()
	pcall(function()
		playerStateMap:RemoveAsync(MatchmakingDictionary.get_player_key(userId))
	end)
end

local function change_mode_count(mode: string, amount: number): ()
	local current = localQueuedModeCounts[mode] or 0
	local nextValue = math.max(0, current + amount)

	if nextValue == 0 then
		localQueuedModeCounts[mode] = nil
		return
	end

	localQueuedModeCounts[mode] = nextValue
end

local function get_total_local_queued(): number
	local total = 0

	for _, state in localQueuedPlayers do
		if not state.teleporting then
			total += 1
		end
	end

	return total
end

local function has_active_local_mode(mode: string): boolean
	for _, group in localQueuedGroups do
		if group.mode == mode and not group.teleporting then
			return true
		end
	end

	return false
end

local function build_ticket(userId: number, state: LocalQueueState, group: LocalQueuedGroup): QueueTicket
	return {
		userId = userId,
		mode = state.mode,
		sourceJobId = SOURCE_JOB_ID,
		ticketId = state.ticketId,
		groupId = group.groupId,
		groupLeaderUserId = group.leaderUserId,
		groupUserIds = table.clone(group.userIds),
		behavior = group.behavior,
		groupSize = #group.userIds,
		queuedAt = state.queuedAt,
	}
end

local function enqueue_ticket(ticket: QueueTicket): boolean
	local modeConfig = MatchmakingDictionary.get_mode(ticket.mode)

	if not modeConfig then
		return false
	end

	local queue = get_match_queue(modeConfig.mode)
	local success = pcall(function()
		queue:AddAsync(ticket, QUEUE_ENTRY_TTL, 0)
	end)

	return success
end

local function clear_group_local_states(group: LocalQueuedGroup, removeMemoryState: boolean): ()
	for _, userId in group.userIds do
		localQueuedPlayers[userId] = nil

		if removeMemoryState then
			remove_player_state(userId)
		end

		local player = Players:GetPlayerByUserId(userId)

		if player then
			send_state(player, nil)
		end
	end

	change_mode_count(group.mode, -#group.userIds)
	localQueuedGroups[group.groupId] = nil
end

local function cancel_group(group: LocalQueuedGroup, silent: boolean?): ()
	if group.teleporting then
		return
	end

	clear_group_local_states(group, true)
	change_global_mode_count(group.mode, -#group.userIds)
	request_queue_count_refresh()

	if not silent then
		debug_group_players(group.userIds, "Fila cancelada.", "Warn")
	end
end

local function get_group_from_player_state(player: Player): LocalQueuedGroup?
	local state = localQueuedPlayers[player.UserId]

	if not state then
		return nil
	end

	return localQueuedGroups[state.groupId]
end

local function all_group_players_online(userIds: { number }): (boolean, { Player })
	local players: { Player } = {}

	for _, userId in userIds do
		local memberPlayer = Players:GetPlayerByUserId(userId)

		if not memberPlayer then
			return false, {}
		end

		table.insert(players, memberPlayer)
	end

	return true, players
end

-- Fluxo de entrada/teleporte do Deathmatch foi movido para ServerScriptService/Match/DeathmatchMode.server.lua.

local function join_queue(player: Player, mode: string): ()
	local now = os.clock()
	local lastRequest = lastRequests[player.UserId] or 0

	if now - lastRequest < REQUEST_COOLDOWN then
		debug_player(player, "Aguarde antes de enviar outro pedido.", "Warn")
		return
	end

	lastRequests[player.UserId] = now

	local modeConfig = MatchmakingDictionary.get_mode(mode)

	if not modeConfig then
		debug_player(player, "Modo invalido: " .. tostring(mode), "Error")
		send_state(player, localQueuedPlayers[player.UserId])
		return
	end

	if modeConfig.isDeathmatch then
		return
	end

	local successQueueGroup, queueGroup, reason = PartyService.get_queue_group_for_player(player, modeConfig)

	if not successQueueGroup or not queueGroup then
		debug_player(player, reason or "Nao foi possivel preparar a party para fila.", "Warn")
		return
	end

	local isOnline, memberPlayers = all_group_players_online(queueGroup.userIds)

	if not isOnline then
		debug_player(player, "Todos os membros da party precisam estar no servidor.", "Warn")
		return
	end

	for _, memberPlayer in memberPlayers do
		local existingState = localQueuedPlayers[memberPlayer.UserId]

		if existingState then
			local existingGroup = localQueuedGroups[existingState.groupId]

			if existingGroup and existingGroup.mode == modeConfig.mode and existingGroup.leaderUserId == queueGroup.leaderUserId then
				debug_player(player, "Sua party ja esta na fila " .. modeConfig.mode .. ".", "Info")
				return
			end

			debug_player(player, memberPlayer.Name .. " ja esta em outra fila.", "Warn")
			return
		end
	end

	local queuedAt = os.time()
	local queueTicketGroupId = queueGroup.groupId .. "_" .. HttpService:GenerateGUID(false)
	local localGroup: LocalQueuedGroup = {
		groupId = queueTicketGroupId,
		mode = modeConfig.mode,
		behavior = queueGroup.behavior,
		leaderUserId = queueGroup.leaderUserId,
		userIds = table.clone(queueGroup.userIds),
		queuedAt = queuedAt,
		teleporting = false,
	}

	local preparedStates: { [number]: LocalQueueState } = {}

	for _, memberPlayer in memberPlayers do
		preparedStates[memberPlayer.UserId] = {
			mode = modeConfig.mode,
			ticketId = HttpService:GenerateGUID(false),
			groupId = localGroup.groupId,
			leaderUserId = localGroup.leaderUserId,
			queuedAt = queuedAt,
			teleporting = false,
		}
	end

	for _, memberPlayer in memberPlayers do
		local state = preparedStates[memberPlayer.UserId]

		if not state or not write_player_state(memberPlayer, state) then
			for _, rollbackPlayer in memberPlayers do
				remove_player_state(rollbackPlayer.UserId)
			end

			return
		end
	end

	for _, memberPlayer in memberPlayers do
		local state = preparedStates[memberPlayer.UserId]
		local ticket = build_ticket(memberPlayer.UserId, state, localGroup)

		if not enqueue_ticket(ticket) then
			for _, rollbackPlayer in memberPlayers do
				remove_player_state(rollbackPlayer.UserId)
			end

			debug_group_players(localGroup.userIds, "Falha ao entrar na fila global.", "Error")
			return
		end
	end

	localQueuedGroups[localGroup.groupId] = localGroup

	for _, memberPlayer in memberPlayers do
		local state = preparedStates[memberPlayer.UserId]
		localQueuedPlayers[memberPlayer.UserId] = state
		send_state(memberPlayer, state)
	end

	change_mode_count(localGroup.mode, #localGroup.userIds)
	change_global_mode_count(localGroup.mode, #localGroup.userIds)
	request_queue_count_refresh()
	debug_group_players(localGroup.userIds, "Entrou na fila " .. localGroup.mode .. ".", "Success")
end

local function cancel_queue(player: Player, silent: boolean?): ()
	local group = get_group_from_player_state(player)

	if not group then
		send_state(player, nil)

		if not silent then
			debug_player(player, "Voce nao esta em nenhuma fila.", "Warn")
		end

		return
	end

	if group.teleporting then
		debug_player(player, "Teleport em andamento, cancelamento ignorado.", "Warn")
		return
	end

	cancel_group(group, silent)
end

local function get_local_players_from_users(userIds: { number }, mode: string): { Player }
	local playersToTeleport: { Player } = {}

	for _, userId in userIds do
		local localPlayer = Players:GetPlayerByUserId(userId)
		local state = localQueuedPlayers[userId]

		if localPlayer and state and state.mode == mode and not state.teleporting then
			table.insert(playersToTeleport, localPlayer)
		end
	end

	return playersToTeleport
end

local function requeue_group_after_teleport_failure(group: LocalQueuedGroup, reason: string): ()
	group.teleporting = false
	local queuedAt = os.time()
	local preparedTickets: { QueueTicket } = {}
	local preparedStates: { [number]: LocalQueueState } = {}

	for _, userId in group.userIds do
		local memberPlayer = Players:GetPlayerByUserId(userId)

		if not memberPlayer then
			continue
		end

		local state: LocalQueueState = {
			mode = group.mode,
			ticketId = HttpService:GenerateGUID(false),
			groupId = group.groupId,
			leaderUserId = group.leaderUserId,
			queuedAt = queuedAt,
			teleporting = false,
		}

		preparedStates[userId] = state

		table.insert(preparedTickets, {
			userId = userId,
			mode = group.mode,
			sourceJobId = SOURCE_JOB_ID,
			ticketId = state.ticketId,
			groupId = group.groupId,
			groupLeaderUserId = group.leaderUserId,
			groupUserIds = table.clone(group.userIds),
			behavior = group.behavior,
			groupSize = #group.userIds,
			queuedAt = queuedAt,
		})
	end

	for userId, state in preparedStates do
		local memberPlayer = Players:GetPlayerByUserId(userId)

		if memberPlayer then
			if not write_player_state(memberPlayer, state) then
				clear_group_local_states(group, true)
				request_queue_count_refresh()
				debug_group_players(group.userIds, "Falha ao voltar para fila depois do erro: " .. reason, "Error")
				return
			end
		end
	end

	for _, ticket in preparedTickets do
		if not enqueue_ticket(ticket) then
			clear_group_local_states(group, true)
			request_queue_count_refresh()
			debug_group_players(group.userIds, "Falha ao voltar para fila depois do erro: " .. reason, "Error")
			return
		end
	end

	for userId, state in preparedStates do
		local memberPlayer = Players:GetPlayerByUserId(userId)

		if memberPlayer then
			localQueuedPlayers[userId] = state
			send_state(memberPlayer, state)
		end
	end

	change_global_mode_count(group.mode, #group.userIds)
	request_queue_count_refresh()
	debug_group_players(group.userIds, "Teleport falhou e a party voltou para fila. Motivo: " .. reason, "Warn")
end

local function send_teleport(playersToTeleport: { Player }, assignment: MatchAssignment): ()
	local groupsTouched: { [string]: boolean } = {}

	for _, player in playersToTeleport do
		local state = localQueuedPlayers[player.UserId]

		if state then
			local group = localQueuedGroups[state.groupId]

			if group then
				group.teleporting = true
				groupsTouched[group.groupId] = true
			end

			state.teleporting = true
			remove_player_state(player.UserId)
			change_global_mode_count(state.mode, -1)
			send_state(player, state)
		end
	end

	for groupId in groupsTouched do
		local group = localQueuedGroups[groupId]

		if group then
			debug_group_players(group.userIds, "Match encontrado. Preparando server privado " .. assignment.mode .. "...", "Success")
		end
	end

	request_queue_count_refresh()

	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ReservedServerAccessCode = assignment.reservedServerAccessCode
	teleportOptions:SetTeleportData({
		mode = assignment.mode,
		teamSize = assignment.teamSize,
		playersRequired = assignment.playersRequired,
		matchId = assignment.matchId,
		privateServerId = assignment.privateServerId,
		userIds = assignment.users,
		teamByUserId = assignment.teamByUserId,
		groupBehaviorById = assignment.groupBehaviorById,
		sourceJobId = SOURCE_JOB_ID,
		sourcePlaceId = game.PlaceId,
	})

	local success, result = pcall(function()
		return TeleportService:TeleportAsync(assignment.placeId, playersToTeleport, teleportOptions)
	end)

	if success then
		for _, player in playersToTeleport do
			local state = localQueuedPlayers[player.UserId]

			if state then
				local group = localQueuedGroups[state.groupId]

				if group then
					clear_group_local_states(group, false)
				else
					localQueuedPlayers[player.UserId] = nil
					send_state(player, nil)
				end
			else
				send_state(player, nil)
			end
		end

		request_queue_count_refresh()
		return
	end

	local handledGroups: { [string]: boolean } = {}

	for _, player in playersToTeleport do
		local state = localQueuedPlayers[player.UserId]

		if state then
			local group = localQueuedGroups[state.groupId]

			if group and not handledGroups[group.groupId] then
				handledGroups[group.groupId] = true
				requeue_group_after_teleport_failure(group, tostring(result))
			end
		end
	end
end

local function process_assignment(value: any): ()
	if typeof(value) ~= "table" then
		return
	end

	local assignment = value :: MatchAssignment

	if assignment.placeId ~= MatchmakingDictionary.DESTINATION_PLACE_ID then
		return
	end

	if typeof(assignment.reservedServerAccessCode) ~= "string" or assignment.reservedServerAccessCode == "" then
		return
	end

	local localUsers = assignment.localUsers or assignment.users
	local playersToTeleport = get_local_players_from_users(localUsers, assignment.mode)

	if #playersToTeleport == 0 then
		return
	end

	send_teleport(playersToTeleport, assignment)
end

local function process_assignment_queue(): ()
	local success, values, readId = pcall(function()
		return assignmentQueue:ReadAsync(MAX_ASSIGNMENTS_PER_READ, false, 0)
	end)

	if not success then
		debug_log("Falha ao ler assignments: " .. tostring(values))
		return
	end

	if not values or #values == 0 or not readId then
		return
	end

	for _, value in values do
		process_assignment(value)
	end

	pcall(function()
		assignmentQueue:RemoveAsync(readId)
	end)
end

local function get_ticket_from_value(value: any): QueueTicket?
	if typeof(value) ~= "table" then
		return nil
	end

	if typeof(value.userId) ~= "number" then
		return nil
	end

	if typeof(value.mode) ~= "string" or typeof(value.sourceJobId) ~= "string" or typeof(value.ticketId) ~= "string" then
		return nil
	end

	if typeof(value.groupId) ~= "string" or typeof(value.groupLeaderUserId) ~= "number" then
		return nil
	end

	if typeof(value.groupUserIds) ~= "table" then
		return nil
	end

	if typeof(value.behavior) ~= "string" or typeof(value.groupSize) ~= "number" or typeof(value.queuedAt) ~= "number" then
		return nil
	end

	return value :: QueueTicket
end

local function validate_ticket(ticket: QueueTicket, mode: string, seenUsers: { [number]: boolean }): (QueueTicket?, boolean)
	if ticket.mode ~= mode or seenUsers[ticket.userId] then
		return nil, false
	end

	local localState = localQueuedPlayers[ticket.userId]

	if localState then
		if localState.mode ~= ticket.mode or localState.ticketId ~= ticket.ticketId or localState.groupId ~= ticket.groupId then
			return nil, false
		end

		seenUsers[ticket.userId] = true
		return ticket, false
	end

	local success, stateValue = pcall(function()
		return playerStateMap:GetAsync(MatchmakingDictionary.get_player_key(ticket.userId))
	end)

	if not success then
		return nil, true
	end

	if typeof(stateValue) ~= "table" then
		return nil, false
	end

	if typeof(stateValue.updatedAt) ~= "number" or os.time() - stateValue.updatedAt > PLAYER_STATE_STALE_SECONDS then
		return nil, false
	end

	if stateValue.mode ~= ticket.mode or stateValue.ticketId ~= ticket.ticketId or stateValue.sourceJobId ~= ticket.sourceJobId then
		return nil, false
	end

	if stateValue.groupId ~= ticket.groupId then
		return nil, false
	end

	seenUsers[ticket.userId] = true
	return ticket, false
end

local function validate_tickets(values: { any }, mode: string): ({ QueueTicket }, boolean)
	local validTickets: { QueueTicket } = {}
	local seenUsers: { [number]: boolean } = {}

	for _, value in values do
		local ticket = get_ticket_from_value(value)

		if ticket then
			local validTicket, shouldRetry = validate_ticket(ticket, mode, seenUsers)

			if shouldRetry then
				return validTickets, true
			end

			if validTicket then
				table.insert(validTickets, validTicket)
			end
		end
	end

	return validTickets, false
end

local function requeue_tickets(tickets: { QueueTicket }): boolean
	for _, ticket in tickets do
		local queue = get_match_queue(ticket.mode)
		local success = pcall(function()
			queue:AddAsync(ticket, QUEUE_ENTRY_TTL, 0)
		end)

		if not success then
			return false
		end
	end

	return true
end

local function build_groups_from_valid_tickets(validTickets: { QueueTicket }): { TicketGroup }
	local grouped: { [string]: { tickets: { QueueTicket }, expected: { [number]: boolean }, seen: { [number]: boolean } } } = {}

	for _, ticket in validTickets do
		local bucket = grouped[ticket.groupId]

		if not bucket then
			bucket = {
				tickets = {},
				expected = {},
				seen = {},
			}

			grouped[ticket.groupId] = bucket
		end

		table.insert(bucket.tickets, ticket)

		for _, memberUserId in ticket.groupUserIds do
			bucket.expected[memberUserId] = true
		end

		bucket.seen[ticket.userId] = true
	end

	local groups: { TicketGroup } = {}

	for groupId, bucket in grouped do
		local expectedCount = 0
		local complete = true
		local userIds: { number } = {}

		for memberUserId in bucket.expected do
			expectedCount += 1
			table.insert(userIds, memberUserId)

			if not bucket.seen[memberUserId] then
				complete = false
			end
		end

		if complete and #bucket.tickets == expectedCount then
			local first = bucket.tickets[1]

			table.sort(userIds, function(a: number, b: number): boolean
				return a < b
			end)

			table.insert(groups, {
				groupId = groupId,
				mode = first.mode,
				sourceJobId = first.sourceJobId,
				behavior = first.behavior,
				leaderUserId = first.groupLeaderUserId,
				userIds = userIds,
				queuedAt = first.queuedAt,
				tickets = bucket.tickets,
			})
		end
	end

	table.sort(groups, function(a: TicketGroup, b: TicketGroup): boolean
		if a.queuedAt == b.queuedAt then
			return a.groupId < b.groupId
		end

		return a.queuedAt < b.queuedAt
	end)

	return groups
end

local function build_team_assignment(groups: { TicketGroup }, modeConfig: ModeConfig): { [number]: string }?
	local teamSize = modeConfig.teamSize
	local redCount = 0
	local blueCount = 0
	local teamByUserId: { [number]: string } = {}
	local pending: { TicketGroup } = {}

	local function assign_user(userId: number, teamName: string): boolean
		if teamName == "Red" then
			if redCount + 1 > teamSize then
				return false
			end

			redCount += 1
			teamByUserId[userId] = "Red"
			return true
		end

		if teamName == "Blue" then
			if blueCount + 1 > teamSize then
				return false
			end

			blueCount += 1
			teamByUserId[userId] = "Blue"
			return true
		end

		return false
	end

	for _, group in groups do
		if group.behavior == "SplitDuel" then
			if #group.userIds ~= 2 then
				return nil
			end

			if not assign_user(group.userIds[1], "Red") then
				return nil
			end

			if not assign_user(group.userIds[2], "Blue") then
				return nil
			end
		else
			table.insert(pending, group)
		end
	end

	table.sort(pending, function(a: TicketGroup, b: TicketGroup): boolean
		if #a.userIds == #b.userIds then
			return a.groupId < b.groupId
		end

		return #a.userIds > #b.userIds
	end)

	for _, group in pending do
		local groupSize = #group.userIds
		local canRed = redCount + groupSize <= teamSize
		local canBlue = blueCount + groupSize <= teamSize

		if not canRed and not canBlue then
			return nil
		end

		local targetTeam = "Red"

		if canRed and canBlue then
			if redCount <= blueCount then
				targetTeam = "Red"
			else
				targetTeam = "Blue"
			end
		elseif canBlue then
			targetTeam = "Blue"
		end

		for _, userId in group.userIds do
			if not assign_user(userId, targetTeam) then
				return nil
			end
		end
	end

	if redCount ~= teamSize or blueCount ~= teamSize then
		return nil
	end

	return teamByUserId
end

local function choose_groups_for_match(groups: { TicketGroup }, modeConfig: ModeConfig): ({ TicketGroup }?, { [number]: string }?)
	local limited: { TicketGroup } = {}

	for index, group in groups do
		if index > MAX_GROUPS_FOR_COMBINATION then
			break
		end

		table.insert(limited, group)
	end

	local targetPlayers = modeConfig.playersRequired
	local chosen: { TicketGroup } = {}
	local chosenResult: { TicketGroup }? = nil
	local chosenTeamMap: { [number]: string }? = nil

	local function dfs(position: number, totalPlayers: number): ()
		if chosenResult then
			return
		end

		if totalPlayers == targetPlayers then
			local teamMap = build_team_assignment(chosen, modeConfig)

			if teamMap then
				chosenResult = table.clone(chosen)
				chosenTeamMap = teamMap
			end

			return
		end

		if totalPlayers > targetPlayers or position > #limited then
			return
		end

		local group = limited[position]
		table.insert(chosen, group)
		dfs(position + 1, totalPlayers + #group.userIds)
		table.remove(chosen)

		if chosenResult then
			return
		end

		dfs(position + 1, totalPlayers)
	end

	dfs(1, 0)
	return chosenResult, chosenTeamMap
end

local function get_users_from_groups(groups: { TicketGroup }): { number }
	local users: { number } = {}

	for _, group in groups do
		for _, userId in group.userIds do
			table.insert(users, userId)
		end
	end

	return users
end

local function get_user_groups_by_source(groups: { TicketGroup }): { [string]: { number } }
	local sourceGroups: { [string]: { number } } = {}

	for _, group in groups do
		local sourceUsers = sourceGroups[group.sourceJobId]

		if not sourceUsers then
			sourceUsers = {}
			sourceGroups[group.sourceJobId] = sourceUsers
		end

		for _, userId in group.userIds do
			table.insert(sourceUsers, userId)
		end
	end

	return sourceGroups
end

local function get_group_behavior_map(groups: { TicketGroup }): { [string]: string }
	local map: { [string]: string } = {}

	for _, group in groups do
		map[group.groupId] = group.behavior
	end

	return map
end

local function push_assignments(
	groups: { TicketGroup },
	matchPackage: any
): boolean
	local usersBySource = get_user_groups_by_source(groups)

	for sourceJobId, localUsers in usersBySource do
		local queue = MemoryStoreService:GetQueue(
			MatchmakingDictionary.get_assignment_queue_name(sourceJobId),
			MatchmakingDictionary.ASSIGNMENT_QUEUE_INVISIBILITY_TIMEOUT
		)

		local assignment: MatchAssignment = {
			matchId = matchPackage.matchId,
			mode = matchPackage.mode,
			teamSize = matchPackage.teamSize,
			playersRequired = matchPackage.playersRequired,
			placeId = matchPackage.placeId,
			reservedServerAccessCode = matchPackage.reservedServerAccessCode,
			privateServerId = matchPackage.privateServerId,
			users = matchPackage.users,
			localUsers = localUsers,
			teamByUserId = matchPackage.teamByUserId,
			groupBehaviorById = matchPackage.groupBehaviorById,
			createdAt = matchPackage.createdAt,
		}

		local success, result = pcall(function()
			queue:AddAsync(assignment, ASSIGNMENT_TTL, 0)
		end)

		if not success then
			debug_log("Falha ao enviar assignment " .. matchPackage.matchId .. " para " .. sourceJobId .. ": " .. tostring(result))
			return false
		end
	end

	return true
end

local function create_match(groups: { TicketGroup }, teamByUserId: { [number]: string }, modeConfig: ModeConfig): boolean
	local users = get_users_from_groups(groups)
	local behaviorMap = get_group_behavior_map(groups)
	local successCreate, createResult = MatchCreationService.create_reserved_match(modeConfig, users, teamByUserId, behaviorMap)

	if not successCreate then
		debug_log("Falha ao reservar server privado: " .. tostring(createResult))
		return false
	end

	local matchPackage = createResult
	local pushed = push_assignments(groups, matchPackage)

	if not pushed then
		return false
	end

	for _, userId in users do
		local localPlayer = Players:GetPlayerByUserId(userId)

		if localPlayer then
			debug_player(localPlayer, "Match " .. modeConfig.mode .. " criado. Aguardando assignment local.", "Success")
		end
	end

	return true
end

local function get_selected_ticket_lookup(groups: { TicketGroup }): { [string]: boolean }
	local lookup: { [string]: boolean } = {}

	for _, group in groups do
		for _, ticket in group.tickets do
			lookup[ticket.ticketId] = true
		end
	end

	return lookup
end

local function scan_mode(modeConfig: ModeConfig): ()
	local queue = get_match_queue(modeConfig.mode)
	local ticketsToRead = math.min(
		MAX_TICKETS_READ_PER_MODE,
		math.max(modeConfig.playersRequired * 3, modeConfig.playersRequired + 2)
	)
	local success, values, readId = pcall(function()
		return queue:ReadAsync(ticketsToRead, false, 0)
	end)

	if not success then
		debug_log("Falha ao ler fila " .. modeConfig.mode .. ": " .. tostring(values))
		return
	end

	if not values or #values == 0 or not readId then
		return
	end

	local validTickets, shouldRetry = validate_tickets(values, modeConfig.mode)

	if shouldRetry then
		debug_log("Validacao da fila " .. modeConfig.mode .. " falhou; batch voltara apos invisibility timeout.")
		return
	end

	if #validTickets == 0 then
		pcall(function()
			queue:RemoveAsync(readId)
		end)
		return
	end

	local groups = build_groups_from_valid_tickets(validTickets)
	local selectedGroups, teamByUserId = choose_groups_for_match(groups, modeConfig)

	if not selectedGroups or not teamByUserId then
		local requeued = requeue_tickets(validTickets)

		if requeued then
			pcall(function()
				queue:RemoveAsync(readId)
			end)
		end

		return
	end

	local created = create_match(selectedGroups, teamByUserId, modeConfig)

	if not created then
		return
	end

	local selectedLookup = get_selected_ticket_lookup(selectedGroups)
	local leftovers: { QueueTicket } = {}

	for _, ticket in validTickets do
		if not selectedLookup[ticket.ticketId] then
			table.insert(leftovers, ticket)
		end
	end

	local requeuedLeftovers = requeue_tickets(leftovers)

	if not requeuedLeftovers then
		debug_log("Falha ao re-enfileirar tickets restantes em " .. modeConfig.mode .. ".")
		return
	end

	pcall(function()
		queue:RemoveAsync(readId)
	end)

	request_queue_count_refresh()
end

local function refresh_local_states(): ()
	for userId, state in localQueuedPlayers do
		local player = Players:GetPlayerByUserId(userId)

		if not player then
			localQueuedPlayers[userId] = nil
			continue
		end

		if not state.teleporting then
			write_player_state(player, state)
		end
	end
end

local function on_player_removing(player: Player): ()
	local group = get_group_from_player_state(player)

	if group then
		if not group.teleporting then
			change_global_mode_count(group.mode, -#group.userIds)
		end

		clear_group_local_states(group, not group.teleporting)
		request_queue_count_refresh()
	end
end

local function on_remote_event(player: Player, action: string, mode: string?): ()
	if action == "Join" and mode then
		if mode == DEATHMATCH_MODE then
			return
		end

		join_queue(player, mode)
		return
	end

	if action == "Leave" then
		cancel_queue(player)
		return
	end

	if action == "Sync" then
		local isDeathmatchQueued = player:GetAttribute("IsMatchmakingQueued") == true and player:GetAttribute("MatchmakingMode") == DEATHMATCH_MODE

		if not isDeathmatchQueued then
			send_state(player, localQueuedPlayers[player.UserId])
		end

		send_queue_counts(player)
	end
end

------------------//MAIN FUNCTIONS
TeleportService.TeleportInitFailed:Connect(function(player: Player, teleportResult: Enum.TeleportResult, errorMessage: string)
	local group = get_group_from_player_state(player)

	if not group or not group.teleporting then
		return
	end

	requeue_group_after_teleport_failure(group, errorMessage ~= "" and errorMessage or teleportResult.Name)
end)

remoteEvent.OnServerEvent:Connect(on_remote_event)
Players.PlayerRemoving:Connect(on_player_removing)

task.spawn(function()
	while true do
		if get_total_local_queued() > 0 then
			process_assignment_queue()
		end

		task.wait(ASSIGNMENT_SCAN_INTERVAL)
	end
end)

task.spawn(function()
	while true do
		for _, modeConfig in MatchmakingDictionary.get_modes() do
			if has_active_local_mode(modeConfig.mode) then
				scan_mode(modeConfig)
				task.wait(MODE_SCAN_SPACING)
			end
		end

		task.wait(MATCH_SCAN_INTERVAL)
	end
end)

task.spawn(function()
	while true do
		task.wait(STATE_REFRESH_INTERVAL)
		refresh_local_states()
	end
end)

task.spawn(function()
	while true do
		if #Players:GetPlayers() > 0 then
			local shouldForceRefresh = queueCountsNeedsRefresh
			queueCountsNeedsRefresh = false
			refresh_queue_counts(shouldForceRefresh)

			if shouldForceRefresh then
				task.wait(QUEUE_COUNT_FAST_REFRESH_INTERVAL)
			else
				task.wait(QUEUE_COUNT_REFRESH_INTERVAL)
			end
		else
			task.wait(QUEUE_COUNT_REFRESH_INTERVAL)
		end
	end
end)

------------------//INIT
if RunService:IsStudio() then
	for _, modeConfig in MatchmakingDictionary.get_modes() do
		pcall(function()
			modeCountMap:SetAsync(get_mode_count_key(modeConfig.mode), 0, MODE_COUNT_TTL)
		end)
	end
end

refresh_queue_counts(true)

for _, player in Players:GetPlayers() do
	send_state(player, nil)
	send_queue_counts(player)
end

debug_log("Servidor iniciado em " .. SOURCE_JOB_ID .. ".")

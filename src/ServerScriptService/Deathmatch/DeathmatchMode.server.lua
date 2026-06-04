------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")
local MemoryStoreService: MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService: TeleportService = game:GetService("TeleportService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local PartyService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("PartyService"))
local MatchCreationService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("MatchCreationService"))

local DEATHMATCH_MODE = MatchmakingDictionary.DEATHMATCH_MODE
local DEATHMATCH_MAX_PLAYERS = MatchmakingDictionary.DEATHMATCH_MAX_PLAYERS
local DEATHMATCH_SERVER_TTL = MatchmakingDictionary.DEATHMATCH_SERVER_TTL
local DEATHMATCH_SERVER_STALE_SECONDS = MatchmakingDictionary.DEATHMATCH_SERVER_STALE_SECONDS
local REQUEST_COOLDOWN_SECONDS = 1
local BACK_TO_LOBBY_ACTION = "DeathmatchBackToLobby"
local DEATHMATCH_QUEUE_REFRESH_BINDABLE_NAME = "DeathmatchQueueRefreshRequest"

------------------//VARIABLES
type ModeConfig = MatchmakingDictionary.ModeConfig

type DeathmatchServerRecord = {
	matchId: string,
	mode: string,
	placeId: number,
	reservedServerAccessCode: string,
	privateServerId: string,
	currentPlayers: number,
	maxPlayers: number,
	createdAt: number,
	updatedAt: number,
}

type PendingDeathmatchTeleport = {
	serverKey: string,
	mode: string,
}

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local matchmakingRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.REMOTE_EVENT_NAME) :: RemoteEvent
local matchSessionRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.MATCH_SESSION_REMOTE_EVENT_NAME) :: RemoteEvent

local deathmatchQueueRefreshEventInstance: BindableEvent? = ServerStorage:FindFirstChild(DEATHMATCH_QUEUE_REFRESH_BINDABLE_NAME) :: BindableEvent?

if not deathmatchQueueRefreshEventInstance then
	deathmatchQueueRefreshEventInstance = Instance.new("BindableEvent")
	deathmatchQueueRefreshEventInstance.Name = DEATHMATCH_QUEUE_REFRESH_BINDABLE_NAME
	deathmatchQueueRefreshEventInstance.Parent = ServerStorage
end

local deathmatchQueueRefreshEvent: BindableEvent = deathmatchQueueRefreshEventInstance :: BindableEvent
local deathmatchServerMap = MemoryStoreService:GetSortedMap(MatchmakingDictionary.DEATHMATCH_SERVER_MAP_NAME)

local requestTimesByUserId: { [number]: number } = {}
local pendingDeathmatchTeleports: { [number]: PendingDeathmatchTeleport } = {}

------------------//FUNCTIONS
local function debug_log(message: string): ()
	print(MatchmakingDictionary.DEBUG_PREFIX .. " [Deathmatch] " .. message)
end

local function debug_player(player: Player, message: string, colorName: string?): ()
	debug_log(player.Name .. ": " .. message)
	matchmakingRemote:FireClient(player, "Debug", {
		message = message,
		colorName = colorName or "Info",
	})
end

local function debug_group_players(userIds: { number }, message: string, colorName: string?): ()
	for _, userId in userIds do
		local memberPlayer = Players:GetPlayerByUserId(userId)

		if memberPlayer then
			debug_player(memberPlayer, message, colorName)
		end
	end
end

local function request_queue_count_refresh(): ()
	deathmatchQueueRefreshEvent:Fire()
end

local function send_state(player: Player, mode: string?, queuedAt: number?, teleporting: boolean): ()
	local isQueued = mode ~= nil

	player:SetAttribute("IsMatchmakingQueued", isQueued)
	player:SetAttribute("MatchmakingMode", mode)

	matchmakingRemote:FireClient(player, "State", {
		isQueued = isQueued,
		mode = mode,
		queuedAt = queuedAt,
		teleporting = teleporting == true,
	})
end

local function is_request_on_cooldown(player: Player): boolean
	local now = os.clock()
	local lastRequestAt = requestTimesByUserId[player.UserId] or 0

	if now - lastRequestAt < REQUEST_COOLDOWN_SECONDS then
		return true
	end

	requestTimesByUserId[player.UserId] = now
	return false
end

local function get_deathmatch_max_players(modeConfig: ModeConfig?): number
	if modeConfig and typeof(modeConfig.maxPlayers) == "number" then
		return math.max(1, math.floor(modeConfig.maxPlayers))
	end

	return DEATHMATCH_MAX_PLAYERS
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

local function is_player_busy(memberPlayer: Player): boolean
	local queued = memberPlayer:GetAttribute("IsMatchmakingQueued") == true
	return queued or pendingDeathmatchTeleports[memberPlayer.UserId] ~= nil
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
		return {}
	end

	return entries
end

local function get_record_from_deathmatch_entry(entry: any): (string?, DeathmatchServerRecord?)
	if typeof(entry) ~= "table" then
		return nil, nil
	end

	local key = if typeof(entry.key) == "string" then entry.key else nil
	local record = entry.value

	if not key or not is_fresh_deathmatch_record(record) then
		return nil, nil
	end

	return key, record :: DeathmatchServerRecord
end

local function reserve_deathmatch_slots(serverKey: string, groupSize: number): DeathmatchServerRecord?
	local reservedRecord: DeathmatchServerRecord? = nil

	local success, result = pcall(function()
		return deathmatchServerMap:UpdateAsync(serverKey, function(oldValue: any, oldSortKey: any)
			if not is_fresh_deathmatch_record(oldValue) then
				return oldValue, oldSortKey
			end

			local record = oldValue :: DeathmatchServerRecord
			local currentPlayers = if typeof(record.currentPlayers) == "number" then math.max(0, math.floor(record.currentPlayers)) else 0
			local maxPlayers = if typeof(record.maxPlayers) == "number" then math.max(1, math.floor(record.maxPlayers)) else DEATHMATCH_MAX_PLAYERS

			if currentPlayers + groupSize > maxPlayers then
				return record, currentPlayers
			end

			local nextRecord: DeathmatchServerRecord = {
				matchId = record.matchId,
				mode = DEATHMATCH_MODE,
				placeId = record.placeId,
				reservedServerAccessCode = record.reservedServerAccessCode,
				privateServerId = record.privateServerId,
				currentPlayers = currentPlayers + groupSize,
				maxPlayers = maxPlayers,
				createdAt = record.createdAt,
				updatedAt = os.time(),
			}

			reservedRecord = nextRecord
			return nextRecord, nextRecord.currentPlayers
		end, DEATHMATCH_SERVER_TTL)
	end)

	if not success then
		debug_log("Falha ao reservar vagas Deathmatch em " .. serverKey .. ": " .. tostring(result))
		return nil
	end

	return reservedRecord
end

local function release_deathmatch_slots(serverKey: string, groupSize: number): ()
	pcall(function()
		deathmatchServerMap:UpdateAsync(serverKey, function(oldValue: any, oldSortKey: any)
			if typeof(oldValue) ~= "table" then
				return oldValue, oldSortKey
			end

			local record = oldValue :: DeathmatchServerRecord
			local currentPlayers = if typeof(record.currentPlayers) == "number" then math.max(0, math.floor(record.currentPlayers)) else 0
			local nextPlayers = math.max(0, currentPlayers - groupSize)

			record.currentPlayers = nextPlayers
			record.updatedAt = os.time()
			return record, nextPlayers
		end, DEATHMATCH_SERVER_TTL)
	end)
end

local function find_available_deathmatch_server(groupSize: number): (string?, DeathmatchServerRecord?)
	for _, entry in read_deathmatch_server_entries() do
		local serverKey, record = get_record_from_deathmatch_entry(entry)

		if serverKey and record then
			local currentPlayers = if typeof(record.currentPlayers) == "number" then math.max(0, math.floor(record.currentPlayers)) else 0
			local maxPlayers = if typeof(record.maxPlayers) == "number" then math.max(1, math.floor(record.maxPlayers)) else DEATHMATCH_MAX_PLAYERS

			if currentPlayers + groupSize <= maxPlayers then
				local reservedRecord = reserve_deathmatch_slots(serverKey, groupSize)

				if reservedRecord then
					return serverKey, reservedRecord
				end
			end
		end
	end

	return nil, nil
end

local function create_deathmatch_server(modeConfig: ModeConfig, userIds: { number }): (string?, DeathmatchServerRecord?)
	local users = table.clone(userIds)
	local successCreate, createResult = MatchCreationService.create_reserved_match(modeConfig, users, {}, nil)

	if not successCreate then
		debug_log("Falha ao reservar server Deathmatch: " .. tostring(createResult))
		return nil, nil
	end

	local matchPackage = createResult
	local maxPlayers = get_deathmatch_max_players(modeConfig)
	local record: DeathmatchServerRecord = {
		matchId = matchPackage.matchId,
		mode = DEATHMATCH_MODE,
		placeId = matchPackage.placeId,
		reservedServerAccessCode = matchPackage.reservedServerAccessCode,
		privateServerId = matchPackage.privateServerId,
		currentPlayers = #users,
		maxPlayers = maxPlayers,
		createdAt = matchPackage.createdAt,
		updatedAt = os.time(),
	}

	local successSet, result = pcall(function()
		deathmatchServerMap:SetAsync(record.matchId, record, DEATHMATCH_SERVER_TTL, record.currentPlayers)
	end)

	if not successSet then
		debug_log("Falha ao publicar server Deathmatch: " .. tostring(result))
		return nil, nil
	end

	return record.matchId, record
end

local function build_deathmatch_package(record: DeathmatchServerRecord, users: { number }): any
	return {
		matchId = record.matchId,
		mode = DEATHMATCH_MODE,
		teamSize = record.maxPlayers,
		playersRequired = record.maxPlayers,
		placeId = record.placeId,
		reservedServerAccessCode = record.reservedServerAccessCode,
		privateServerId = record.privateServerId,
		users = table.clone(users),
		teamByUserId = {},
		groupBehaviorById = {},
		createdAt = record.createdAt,
	}
end

local function send_deathmatch_teleport_state(playersToTeleport: { Player }, modeConfig: ModeConfig, teleporting: boolean): ()
	for _, memberPlayer in playersToTeleport do
		if teleporting then
			send_state(memberPlayer, modeConfig.mode, os.time(), true)
		else
			send_state(memberPlayer, nil, nil, false)
		end
	end
end

local function teleport_to_deathmatch(playersToTeleport: { Player }, userIds: { number }, modeConfig: ModeConfig, serverKey: string, record: DeathmatchServerRecord): ()
	for _, memberPlayer in playersToTeleport do
		pendingDeathmatchTeleports[memberPlayer.UserId] = {
			serverKey = serverKey,
			mode = modeConfig.mode,
		}
	end

	send_deathmatch_teleport_state(playersToTeleport, modeConfig, true)
	request_queue_count_refresh()

	local package = build_deathmatch_package(record, userIds)
	local success, result = MatchCreationService.teleport_players(playersToTeleport, package, {
		isDeathmatch = true,
		deathmatchServerKey = serverKey,
		maxPlayers = get_deathmatch_max_players(modeConfig),
		sourcePlaceId = game.PlaceId,
	})

	if success then
		debug_group_players(userIds, "Entrando no Deathmatch...", "Success")
		request_queue_count_refresh()
		return
	end

	release_deathmatch_slots(serverKey, #playersToTeleport)
	for _, memberPlayer in playersToTeleport do
		pendingDeathmatchTeleports[memberPlayer.UserId] = nil
	end
	send_deathmatch_teleport_state(playersToTeleport, modeConfig, false)
	request_queue_count_refresh()
	debug_group_players(userIds, "Falha ao entrar no Deathmatch: " .. tostring(result), "Error")
end

local function join_deathmatch(player: Player, modeConfig: ModeConfig): ()
	if is_request_on_cooldown(player) then
		debug_player(player, "Aguarde antes de enviar outro pedido.", "Warn")
		return
	end

	local successQueueGroup, queueGroup, reason = PartyService.get_queue_group_for_player(player, modeConfig)

	if not successQueueGroup or not queueGroup then
		debug_player(player, reason or "Nao foi possivel preparar a party para Deathmatch.", "Warn")
		return
	end

	local isOnline, memberPlayers = all_group_players_online(queueGroup.userIds)

	if not isOnline then
		debug_player(player, "Todos os membros da party precisam estar no servidor.", "Warn")
		return
	end

	local maxPlayers = get_deathmatch_max_players(modeConfig)
	if #memberPlayers > maxPlayers then
		debug_player(player, "Party maior que o Deathmatch.", "Warn")
		return
	end

	for _, memberPlayer in memberPlayers do
		if is_player_busy(memberPlayer) then
			debug_player(player, memberPlayer.Name .. " ja esta em outra fila.", "Warn")
			return
		end
	end

	local serverKey, record = find_available_deathmatch_server(#memberPlayers)

	if not serverKey or not record then
		serverKey, record = create_deathmatch_server(modeConfig, queueGroup.userIds)
	end

	if not serverKey or not record then
		debug_group_players(queueGroup.userIds, "Nao foi possivel criar Deathmatch agora.", "Error")
		return
	end

	teleport_to_deathmatch(memberPlayers, queueGroup.userIds, modeConfig, serverKey, record)
end

local function get_player_teleport_data(player: Player): any
	local joinData = player:GetJoinData()

	if typeof(joinData) ~= "table" then
		return nil
	end

	local teleportData = joinData.TeleportData

	if typeof(teleportData) ~= "table" then
		return nil
	end

	return teleportData
end

local function is_deathmatch_player(player: Player): boolean
	local teleportData = get_player_teleport_data(player)

	if typeof(teleportData) ~= "table" then
		return false
	end

	if teleportData.isDeathmatch == true then
		return true
	end

	return teleportData.mode == DEATHMATCH_MODE
end

local function resolve_lobby_place_id(player: Player): number?
	local joinData = player:GetJoinData()

	if typeof(joinData) ~= "table" then
		return nil
	end

	if typeof(joinData.SourcePlaceId) == "number" and joinData.SourcePlaceId > 0 then
		return joinData.SourcePlaceId
	end

	local teleportData = joinData.TeleportData

	if typeof(teleportData) ~= "table" then
		return nil
	end

	if typeof(teleportData.sourcePlaceId) == "number" and teleportData.sourcePlaceId > 0 then
		return teleportData.sourcePlaceId
	end

	return nil
end

local function send_player_to_lobby(player: Player): ()
	local targetPlaceId = resolve_lobby_place_id(player)

	if not targetPlaceId then
		warn("[DeathmatchMode] Lobby place id nao encontrado para " .. player.Name .. ".")
		return
	end

	local success, result = pcall(function()
		return TeleportService:TeleportAsync(targetPlaceId, { player })
	end)

	if not success then
		warn("[DeathmatchMode] Falha ao teleportar " .. player.Name .. " para lobby: " .. tostring(result))
	end
end

local function on_matchmaking_remote(player: Player, action: string, mode: string?): ()
	if action ~= "Join" or mode ~= DEATHMATCH_MODE then
		return
	end

	local modeConfig = MatchmakingDictionary.get_mode(mode)

	if not modeConfig or modeConfig.isDeathmatch ~= true then
		return
	end

	join_deathmatch(player, modeConfig)
end

local function on_match_session_remote(player: Player, action: string, _payload: any): ()
	if action ~= BACK_TO_LOBBY_ACTION then
		return
	end

	if is_request_on_cooldown(player) then
		return
	end

	if not is_deathmatch_player(player) then
		return
	end

	send_player_to_lobby(player)
end

local function on_player_removing(player: Player): ()
	pendingDeathmatchTeleports[player.UserId] = nil

	requestTimesByUserId[player.UserId] = nil
end

------------------//MAIN FUNCTIONS
matchmakingRemote.OnServerEvent:Connect(on_matchmaking_remote)
matchSessionRemote.OnServerEvent:Connect(on_match_session_remote)

TeleportService.TeleportInitFailed:Connect(function(player: Player, teleportResult: Enum.TeleportResult, errorMessage: string)
	local pendingDeathmatch = pendingDeathmatchTeleports[player.UserId]

	if not pendingDeathmatch then
		return
	end

	pendingDeathmatchTeleports[player.UserId] = nil
	release_deathmatch_slots(pendingDeathmatch.serverKey, 1)
	send_state(player, nil, nil, false)
	request_queue_count_refresh()
	debug_player(player, "Falha ao entrar no Deathmatch: " .. (errorMessage ~= "" and errorMessage or teleportResult.Name), "Error")
end)

Players.PlayerRemoving:Connect(on_player_removing)

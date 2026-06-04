------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local MapDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MapDictionary"))

local MAP_FOLDER_NAME = "Map"
local LOAD_TIMEOUT_DEFAULT = 30
local MAP_VOTE_TIME_DEFAULT = 20

------------------//VARIABLES
type Participant = {
	model: Model,
	player: Player?,
	teamName: string?,
}

type MapConfig = MapDictionary.MapConfig

type ServiceCallbacks = {
	debugLog: (message: string) -> (),
	broadcastHudState: () -> (),
	setPhase: (phaseName: string, durationSeconds: number) -> (),
	waitPhaseTimer: (seconds: number, token: number) -> (),
	getRoundParticipants: () -> { Participant },
	setParticipantsAnchored: (participants: { Participant }, anchored: boolean) -> (),
	setFreezeForAll: (participants: { Participant }, frozen: boolean) -> (),
	getLoadedPlayersInCharacters: () -> (number, number),
	isMatchRunning: () -> boolean,
	isTokenValid: (token: number) -> boolean,
}

type ServiceOptions = {
	loadTimeout: number?,
	mapVoteTime: number?,
}

------------------//FUNCTIONS
local function split_path(path: string): { string }
	local parts: { string } = {}

	for piece in string.gmatch(path, "[^%.]+") do
		table.insert(parts, piece)
	end

	return parts
end

local function resolve_instance_from_path(path: string): Instance?
	local parts = split_path(path)

	if #parts == 0 then
		return nil
	end

	local current: Instance? = nil
	local first = parts[1]
	local startIndex = 1

	if first == "game" then
		current = game
		startIndex = 2
	elseif first == "workspace" then
		current = workspace
		startIndex = 2
	else
		current = game:FindFirstChild(first)
		startIndex = 2
	end

	if not current then
		return nil
	end

	for index = startIndex, #parts do
		current = current:FindFirstChild(parts[index])

		if not current then
			return nil
		end
	end

	return current
end

------------------//MAIN FUNCTIONS
local MapVoteService = {}

function MapVoteService.create(callbacks: ServiceCallbacks, options: ServiceOptions?): any
	local mapConfigs: { MapConfig } = MapDictionary.get_maps()
	local mapVotes: { [string]: number } = {}
	local mapVoteByUserId: { [number]: string } = {}
	local selectedMapId: string? = nil
	local selectedMapName = ""

	local loadTimeout = LOAD_TIMEOUT_DEFAULT
	local mapVoteTime = MAP_VOTE_TIME_DEFAULT
	local randomizer = Random.new()

	if options then
		if typeof(options.loadTimeout) == "number" then
			loadTimeout = math.max(1, math.floor(options.loadTimeout))
		end

		if typeof(options.mapVoteTime) == "number" then
			mapVoteTime = math.max(1, math.floor(options.mapVoteTime))
		end
	end

	local function is_runtime_valid(token: number): boolean
		return callbacks.isMatchRunning() and callbacks.isTokenValid(token)
	end

	local function clear_workspace_map(): ()
		local currentMap = workspace:FindFirstChild(MAP_FOLDER_NAME)

		if currentMap then
			currentMap:Destroy()
		end
	end

	local function load_workspace_map(mapConfig: MapConfig): boolean
		local mapInstance = resolve_instance_from_path(mapConfig.path)

		if not mapInstance or (not mapInstance:IsA("Folder") and not mapInstance:IsA("Model")) then
			callbacks.debugLog("Mapa invalido no caminho: " .. mapConfig.path)
			return false
		end

		clear_workspace_map()

		local clonedMap = mapInstance:Clone()
		clonedMap.Name = MAP_FOLDER_NAME
		clonedMap.Parent = workspace

		callbacks.debugLog("Mapa carregado: " .. mapConfig.displayName .. " (" .. mapConfig.path .. ").")
		return true
	end

	local function get_map_config(mapId: string): MapConfig?
		return MapDictionary.get_map_by_id(mapId)
	end

	local function get_random_map_config(): MapConfig?
		if #mapConfigs == 0 then
			return nil
		end

		local index = randomizer:NextInteger(1, #mapConfigs)
		return mapConfigs[index]
	end

	local function get_vote_winner_map(): MapConfig?
		local highestVote = -1
		local tiedMapIds: { string } = {}

		for _, mapConfig in mapConfigs do
			local votes = mapVotes[mapConfig.id] or 0

			if votes > highestVote then
				highestVote = votes
				tiedMapIds = { mapConfig.id }
			elseif votes == highestVote then
				table.insert(tiedMapIds, mapConfig.id)
			end
		end

		if highestVote <= 0 then
			return get_random_map_config()
		end

		if #tiedMapIds == 0 then
			return get_random_map_config()
		end

		local winnerMapId = tiedMapIds[randomizer:NextInteger(1, #tiedMapIds)]
		return get_map_config(winnerMapId)
	end

	local service = {}

	function service.reset_votes(): ()
		mapVotes = {}
		mapVoteByUserId = {}
		selectedMapId = nil
		selectedMapName = ""

		for _, mapConfig in mapConfigs do
			mapVotes[mapConfig.id] = 0
		end
	end

	function service.get_hud_payload(userId: number, phase: string): { [string]: any }
		local mapsPayload: { [number]: { id: string, image: string, displayName: string, path: string } } = {}
		local votesPayload: { [string]: number } = {}

		for _, mapConfig in mapConfigs do
			table.insert(mapsPayload, {
				id = mapConfig.id,
				image = mapConfig.image,
				displayName = mapConfig.displayName,
				path = mapConfig.path,
			})
		end

		for mapId, voteCount in mapVotes do
			votesPayload[mapId] = voteCount
		end

		local isMapVotePhase = phase == "LoadingPlayers" or phase == "MapVote"

		return {
			maps = mapsPayload,
			mapVotes = votesPayload,
			mapVoteOpen = isMapVotePhase,
			myMapVote = mapVoteByUserId[userId],
			selectedMapId = selectedMapId,
			selectedMapName = selectedMapName,
		}
	end

	function service.register_vote(player: Player, mapId: string, phase: string): ()
		if not callbacks.isMatchRunning() then
			return
		end

		if phase ~= "MapVote" then
			return
		end

		local mapConfig = get_map_config(mapId)

		if not mapConfig then
			callbacks.debugLog(player.Name .. " tentou votar em mapa invalido: " .. tostring(mapId))
			return
		end

		if mapVoteByUserId[player.UserId] == mapId then
			return
		end

		local oldMapId = mapVoteByUserId[player.UserId]

		if oldMapId and mapVotes[oldMapId] then
			mapVotes[oldMapId] = math.max(0, mapVotes[oldMapId] - 1)
		end

		mapVoteByUserId[player.UserId] = mapId
		mapVotes[mapId] = (mapVotes[mapId] or 0) + 1
		callbacks.debugLog(player.Name .. " votou em " .. mapId .. ".")
		callbacks.broadcastHudState()
	end

	function service.remove_player_vote(userId: number): boolean
		local votedMapId = mapVoteByUserId[userId]

		if not votedMapId then
			return false
		end

		mapVoteByUserId[userId] = nil

		if mapVotes[votedMapId] then
			mapVotes[votedMapId] = math.max(0, mapVotes[votedMapId] - 1)
		end

		return true
	end

	function service.wait_players_loaded_for_vote(token: number): boolean
		callbacks.setPhase("LoadingPlayers", loadTimeout)

		local finishAt = os.clock() + loadTimeout

		while os.clock() < finishAt do
			if not is_runtime_valid(token) then
				return false
			end

			local participants = callbacks.getRoundParticipants()
			callbacks.setParticipantsAnchored(participants, true)
			callbacks.setFreezeForAll(participants, true)

			local loadedCount, totalPlayers = callbacks.getLoadedPlayersInCharacters()

			if totalPlayers > 0 and loadedCount >= totalPlayers then
				callbacks.debugLog("Todos os jogadores carregaram para votacao.")
				return true
			end

			task.wait(0.2)
		end

		local loadedCountAfterTimeout, _ = callbacks.getLoadedPlayersInCharacters()

		if loadedCountAfterTimeout <= 0 then
			callbacks.debugLog("Ninguem carregou em " .. tostring(loadTimeout) .. "s.")
			return false
		end

		callbacks.debugLog("Load parcial: " .. tostring(loadedCountAfterTimeout) .. " jogador(es) carregados. Votacao iniciada.")
		return true
	end

	function service.run_vote_and_load_map(token: number): boolean
		if not is_runtime_valid(token) then
			return false
		end

		service.reset_votes()

		local participants = callbacks.getRoundParticipants()
		callbacks.setParticipantsAnchored(participants, true)
		callbacks.setFreezeForAll(participants, true)

		callbacks.setPhase("MapVote", mapVoteTime)
		callbacks.waitPhaseTimer(mapVoteTime, token)

		if not is_runtime_valid(token) then
			return false
		end

		local winnerMap = get_vote_winner_map()

		if not winnerMap then
			callbacks.debugLog("Nenhum mapa disponivel para votacao.")
			return false
		end

		selectedMapId = winnerMap.id
		selectedMapName = winnerMap.displayName
		callbacks.broadcastHudState()

		if not load_workspace_map(winnerMap) then
			return false
		end

		return true
	end

	service.reset_votes()
	return service
end

------------------//INIT
return MapVoteService

------------------//SERVICES
local Players: Players = game:GetService("Players")
local DataStoreService: DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local LOBBY_FOLDER_NAME = "Lobby"
local LEADERBOARD_FOLDER_NAME = "Leaderboard"
local NAMES_FOLDER_NAME = "Names"
local PHOTOS_FOLDER_NAME = "Photos"
local SCORES_FOLDER_NAME = "Score"

local NAME_PREFIX = "Name"
local PHOTO_PREFIX = "Photo"
local SCORE_PREFIX = "Score"

local TOP_SIZE = 10
local REFRESH_INTERVAL_SECONDS = 600
local PROFILE_SYNC_RETRY_COUNT = 3
local PROFILE_SYNC_RETRY_DELAY = 2

local modulesFolder: Folder = ReplicatedStorage:WaitForChild("Modules") :: Folder
local utilityFolder: Folder = modulesFolder:WaitForChild("Utility") :: Folder
local DataUtility = require(utilityFolder:WaitForChild("DataUtility"))

------------------//VARIABLES
type BoardConfig = {
	modelName: string,
	dataKey: string,
	orderedStoreName: string,
}

type BoardSlots = {
	nameLabels: { [number]: GuiObject },
	photoLabels: { [number]: GuiObject },
	scoreLabels: { [number]: GuiObject },
}

type LeaderboardEntry = {
	userId: number,
	score: number,
	name: string,
	photo: string,
}

type BoardRuntime = {
	config: BoardConfig,
	orderedStore: OrderedDataStore,
	slots: BoardSlots?,
}

local BOARD_CONFIGS: { BoardConfig } = {
	{
		modelName = "Wins",
		dataKey = "Wins",
		orderedStoreName = "LobbyLeaderboard_Wins_v1",
	},
	{
		modelName = "Kills",
		dataKey = "Kills",
		orderedStoreName = "LobbyLeaderboard_Kills_v1",
	},
	{
		modelName = "Level",
		dataKey = "Level",
		orderedStoreName = "LobbyLeaderboard_Level_v1",
	},
}

local boardRuntimes: { BoardRuntime } = {}
local usernameCache: { [number]: string } = {}
local photoCache: { [number]: string } = {}
local warnedLeaderboardFolderMissing = false
local refreshQueued = false
local warnedStudioApiDisabled = false
local statConnectionsByUserId: { [number]: { any } } = {}

------------------//FUNCTIONS
local function debug_log(message: string): ()
	--print("[LobbyLeaderboard] " .. message)
end

local function handle_datastore_error(errorMessage: string): ()
	if warnedStudioApiDisabled then
		return
	end

	if string.find(errorMessage, "StudioAccessToApisNotAllowed", 1, true) then
		warnedStudioApiDisabled = true
		debug_log("DataStore API bloqueada no Studio. Ative Game Settings > Security > Enable Studio Access to API Services.")
	end
end

local function get_lobby_leaderboard_folder(): Instance?
	local lobbyFolder = workspace:FindFirstChild(LOBBY_FOLDER_NAME)

	if not lobbyFolder then
		return nil
	end

	local leaderboardFolder = lobbyFolder:FindFirstChild(LEADERBOARD_FOLDER_NAME)

	if leaderboardFolder then
		warnedLeaderboardFolderMissing = false
		return leaderboardFolder
	end

	if not warnedLeaderboardFolderMissing then
		warnedLeaderboardFolderMissing = true
		debug_log("workspace." .. LOBBY_FOLDER_NAME .. "." .. LEADERBOARD_FOLDER_NAME .. " nao encontrado.")
	end

	return nil
end

local function parse_index(name: string, prefix: string): number?
	local numberString = string.match(name, "^" .. prefix .. "(%d+)$")

	if not numberString then
		return nil
	end

	local index = tonumber(numberString)

	if not index then
		return nil
	end

	local rounded = math.floor(index)

	if rounded < 1 or rounded > TOP_SIZE then
		return nil
	end

	return rounded
end

local function find_child_case_insensitive(parent: Instance, childName: string): Instance?
	local targetLower = string.lower(childName)

	for _, child in parent:GetChildren() do
		if string.lower(child.Name) == targetLower then
			return child
		end
	end

	return nil
end

local function find_board_root(boardModel: Instance): Instance?
	local directNames = find_child_case_insensitive(boardModel, NAMES_FOLDER_NAME)
	local directPhotos = find_child_case_insensitive(boardModel, PHOTOS_FOLDER_NAME)
	local directScores = find_child_case_insensitive(boardModel, SCORES_FOLDER_NAME)

	if directNames and directPhotos and directScores then
		return boardModel
	end

	for _, descendant in boardModel:GetDescendants() do
		local namesFolder = find_child_case_insensitive(descendant, NAMES_FOLDER_NAME)
		local photosFolder = find_child_case_insensitive(descendant, PHOTOS_FOLDER_NAME)
		local scoresFolder = find_child_case_insensitive(descendant, SCORES_FOLDER_NAME)

		if namesFolder and photosFolder and scoresFolder then
			return descendant
		end
	end

	return nil
end

local function collect_text_labels(folder: Instance, prefix: string): { [number]: GuiObject }
	local labels: { [number]: GuiObject } = {}

	for _, child in folder:GetChildren() do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			local index = parse_index(child.Name, prefix)

			if index then
				labels[index] = child
			end
		end
	end

	return labels
end

local function collect_image_labels(folder: Instance, prefix: string): { [number]: GuiObject }
	local labels: { [number]: GuiObject } = {}

	for _, child in folder:GetChildren() do
		if child:IsA("ImageLabel") or child:IsA("ImageButton") then
			local index = parse_index(child.Name, prefix)

			if index then
				labels[index] = child
			end
		end
	end

	return labels
end

local function build_board_slots(boardModel: Instance): BoardSlots?
	local boardRoot = find_board_root(boardModel)

	if not boardRoot then
		return nil
	end

	local namesFolder = find_child_case_insensitive(boardRoot, NAMES_FOLDER_NAME)
	local photosFolder = find_child_case_insensitive(boardRoot, PHOTOS_FOLDER_NAME)
	local scoresFolder = find_child_case_insensitive(boardRoot, SCORES_FOLDER_NAME)

	if not namesFolder or not photosFolder or not scoresFolder then
		return nil
	end

	local nameLabels = collect_text_labels(namesFolder, NAME_PREFIX)
	local photoLabels = collect_image_labels(photosFolder, PHOTO_PREFIX)
	local scoreLabels = collect_text_labels(scoresFolder, SCORE_PREFIX)

	return {
		nameLabels = nameLabels,
		photoLabels = photoLabels,
		scoreLabels = scoreLabels,
	}
end

local function refresh_board_slots(): ()
	local leaderboardFolder = get_lobby_leaderboard_folder()

	if not leaderboardFolder then
		for _, runtime in boardRuntimes do
			runtime.slots = nil
		end

		return
	end

	for _, runtime in boardRuntimes do
		local boardModel = leaderboardFolder:FindFirstChild(runtime.config.modelName)

		if not boardModel then
			runtime.slots = nil
			debug_log("Board '" .. runtime.config.modelName .. "' nao encontrado em workspace.Lobby.Leaderboard.")
			continue
		end

		runtime.slots = build_board_slots(boardModel)

		if not runtime.slots then
			debug_log("Board '" .. runtime.config.modelName .. "' sem estrutura valida (Leaderboard/Names/Photos/Score).")
			continue
		end

		local namesCount = 0
		local photosCount = 0
		local scoresCount = 0

		for _ in runtime.slots.nameLabels do
			namesCount += 1
		end

		for _ in runtime.slots.photoLabels do
			photosCount += 1
		end

		for _ in runtime.slots.scoreLabels do
			scoresCount += 1
		end

		debug_log(
			"Board '" .. runtime.config.modelName .. "' pronto. Slots Names="
				.. tostring(namesCount)
				.. " Photos="
				.. tostring(photosCount)
				.. " Score="
				.. tostring(scoresCount)
		)
	end
end

local function get_player_number_stat(player: Player, dataKey: string): number
	local success, result = pcall(function()
		return DataUtility.server.get(player, dataKey)
	end)

	if not success then
		return 0
	end

	if typeof(result) ~= "number" then
		return 0
	end

	return math.max(0, math.floor(result))
end

local function set_ordered_value(store: OrderedDataStore, userId: number, value: number): ()
	local success, result = pcall(function()
		store:SetAsync(tostring(userId), value)
	end)

	if not success then
		local errorMessage = tostring(result)
		handle_datastore_error(errorMessage)
		debug_log("Falha ao salvar OrderedData para " .. tostring(userId) .. ": " .. errorMessage)
		return
	end

	debug_log("OrderedData atualizado: userId=" .. tostring(userId) .. " value=" .. tostring(value))
end

local function sync_player_ordered_data(player: Player): ()
	for attempt = 1, PROFILE_SYNC_RETRY_COUNT do
		if not player.Parent then
			return
		end

		for _, runtime in boardRuntimes do
			local statValue = get_player_number_stat(player, runtime.config.dataKey)
			set_ordered_value(runtime.orderedStore, player.UserId, statValue)
			debug_log("Sync(" .. tostring(attempt) .. "): " .. player.Name .. " " .. runtime.config.dataKey .. "=" .. tostring(statValue))
		end

		if attempt < PROFILE_SYNC_RETRY_COUNT then
			task.wait(PROFILE_SYNC_RETRY_DELAY)
		end
	end
end

local function get_username(userId: number): string
	local cached = usernameCache[userId]

	if cached then
		return cached
	end

	local success, result = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	if success and typeof(result) == "string" then
		usernameCache[userId] = result
		return result
	end

	return tostring(userId)
end

local function get_user_photo(userId: number): string
	local cached = photoCache[userId]

	if cached then
		return cached
	end

	local success, content = pcall(function()
		local image, _isReady = Players:GetUserThumbnailAsync(
			userId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100
		)

		return image
	end)

	if success and typeof(content) == "string" then
		photoCache[userId] = content
		return content
	end

	return ""
end

local function read_top_entries(store: OrderedDataStore): { LeaderboardEntry }
	local success, pages = pcall(function()
		return store:GetSortedAsync(false, TOP_SIZE)
	end)

	if not success then
		local errorMessage = tostring(pages)
		handle_datastore_error(errorMessage)
		debug_log("Falha ao ler OrderedData: " .. errorMessage)
		return {}
	end

	local entries: { LeaderboardEntry } = {}
	local page = pages:GetCurrentPage()

	for _, item in page do
		local userId = tonumber(item.key)
		local score = if typeof(item.value) == "number" then math.floor(item.value) else tonumber(item.value)

		if userId and score then
			table.insert(entries, {
				userId = userId,
				score = math.max(0, score),
				name = get_username(userId),
				photo = get_user_photo(userId),
			})
		end
	end

	debug_log("Top entries lidas: " .. tostring(#entries))
	return entries
end

local function apply_entries_to_slots(slots: BoardSlots, entries: { LeaderboardEntry }): ()
	for index = 1, TOP_SIZE do
		local entry = entries[index]
		local nameLabel = slots.nameLabels[index]
		local photoLabel = slots.photoLabels[index]
		local scoreLabel = slots.scoreLabels[index]

		if nameLabel then
			if nameLabel:IsA("TextLabel") or nameLabel:IsA("TextButton") then
				nameLabel.Text = if entry then entry.name else "-"
			end
		end

		if photoLabel then
			if photoLabel:IsA("ImageLabel") or photoLabel:IsA("ImageButton") then
				photoLabel.Image = if entry then entry.photo else ""
			end
		end

		if scoreLabel then
			if scoreLabel:IsA("TextLabel") or scoreLabel:IsA("TextButton") then
				scoreLabel.Text = if entry then tostring(entry.score) else "0"
			end
		end
	end
end

local function refresh_boards(): ()
	debug_log("Refresh de leaderboard iniciado.")
	refresh_board_slots()

	for _, runtime in boardRuntimes do
		if not runtime.slots then
			debug_log("Board '" .. runtime.config.modelName .. "' ignorado: slots nao encontrados.")
			continue
		end

		local entries = read_top_entries(runtime.orderedStore)
		apply_entries_to_slots(runtime.slots, entries)
		debug_log("Board '" .. runtime.config.modelName .. "' aplicada com " .. tostring(#entries) .. " entradas.")
	end
end

local function request_refresh_boards(): ()
	if refreshQueued then
		return
	end

	refreshQueued = true

	task.delay(2, function()
		refreshQueued = false
		refresh_boards()
	end)
end

local function on_player_added(player: Player): ()
	task.spawn(function()
		sync_player_ordered_data(player)
		request_refresh_boards()
	end)
end

local function bind_player_stat_updates(player: Player): ()
	local oldConnections = statConnectionsByUserId[player.UserId]

	if oldConnections then
		for _, connection in oldConnections do
			connection:Disconnect()
		end

		statConnectionsByUserId[player.UserId] = nil
	end

	local connections: { any } = {}

	for _, runtime in boardRuntimes do
		local connection = DataUtility.server.bind(player, runtime.config.dataKey, function(value: any)
			if typeof(value) ~= "number" then
				return
			end

			local safeValue = math.max(0, math.floor(value))
			set_ordered_value(runtime.orderedStore, player.UserId, safeValue)
			request_refresh_boards()
			debug_log("Bind update: " .. player.Name .. " " .. runtime.config.dataKey .. "=" .. tostring(safeValue))
		end)

		if connection then
			table.insert(connections, connection)
		end
	end

	statConnectionsByUserId[player.UserId] = connections
end

local function on_player_removing(player: Player): ()
	local connections = statConnectionsByUserId[player.UserId]

	if not connections then
		return
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	statConnectionsByUserId[player.UserId] = nil
end

local function setup_board_runtimes(): ()
	for _, config in BOARD_CONFIGS do
		local orderedStore = DataStoreService:GetOrderedDataStore(config.orderedStoreName)

		table.insert(boardRuntimes, {
			config = config,
			orderedStore = orderedStore,
			slots = nil,
		})
	end
end

------------------//MAIN FUNCTIONS
DataUtility.server.ensure_remotes()
setup_board_runtimes()
refresh_boards()

Players.PlayerAdded:Connect(on_player_added)
Players.PlayerAdded:Connect(bind_player_stat_updates)
Players.PlayerRemoving:Connect(on_player_removing)

for _, player in Players:GetPlayers() do
	on_player_added(player)
	bind_player_stat_updates(player)
end

task.spawn(function()
	while true do
		task.wait(REFRESH_INTERVAL_SECONDS)
		refresh_boards()
	end
end)

------------------//INIT

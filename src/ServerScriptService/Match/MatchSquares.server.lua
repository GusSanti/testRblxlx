------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")
local TeleportService: TeleportService = game:GetService("TeleportService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local MatchCreationService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("MatchCreationService"))

local MATCH_SQUARES_FOLDER_NAME = "MatchSquares"
local CHARACTERS_FOLDER_NAME = "Characters"
local SIDE1_NAME = "Side1"
local SIDE2_NAME = "Side2"
local HITBOX_NAME = "Hitbox"
local ROOM_SCREEN_PART_NAME = "screen for room"
local TEAM_RED_NAME = "Red"
local TEAM_BLUE_NAME = "Blue"
local PULL_TAG_ATTRIBUTE = "IsMatchSquarePulling"
local MATCH_WORKSPACE_ATTRIBUTE_NAME = "IsMatch"

local SCAN_INTERVAL = 0.3
local DISCOVERY_INTERVAL = 3
local SUCCESS_COOLDOWN = 2
local FAILURE_COOLDOWN = 1
local PLAYER_LOCK_TIME = 15

local SOURCE_JOB_ID = if game.JobId ~= "" then game.JobId else "Studio_" .. tostring(game.PlaceId)

------------------//VARIABLES
type ModeConfig = MatchmakingDictionary.ModeConfig

type MatchSquare = {
	id: string,
	modeConfig: ModeConfig,
	container: Instance,
	side1Hitbox: BasePart,
	side2Hitbox: BasePart,
	busy: boolean,
	cooldownUntil: number,
}

local trackedSquares: { MatchSquare } = {}
local playerLockUntil: { [number]: number } = {}
local lastDiscoveryAt = 0
local lastSquaresCount = -1
local warnedMissingFolder = false

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.RespectCanCollide = false
overlapParams.MaxParts = 200

------------------//FUNCTIONS
local function debug_log(message: string): ()
	print("[MatchSquares] " .. message)
end

local function get_characters_folder(): Folder?
	local folder = workspace:FindFirstChild(CHARACTERS_FOLDER_NAME)

	if folder and folder:IsA("Folder") then
		return folder
	end

	return nil
end

local function is_player_locked(userId: number): boolean
	local unlockAt = playerLockUntil[userId]

	if not unlockAt then
		return false
	end

	if os.clock() >= unlockAt then
		playerLockUntil[userId] = nil
		return false
	end

	return true
end

local function lock_players(players: { Player }): ()
	local unlockAt = os.clock() + PLAYER_LOCK_TIME

	for _, player in players do
		playerLockUntil[player.UserId] = unlockAt
		player:SetAttribute(PULL_TAG_ATTRIBUTE, true)
	end
end

local function unlock_players(players: { Player }): ()
	for _, player in players do
		playerLockUntil[player.UserId] = nil
		player:SetAttribute(PULL_TAG_ATTRIBUTE, false)
	end
end

local function cleanup_player_locks(): ()
	local now = os.clock()

	for userId, unlockAt in playerLockUntil do
		if now >= unlockAt then
			playerLockUntil[userId] = nil
			local player = Players:GetPlayerByUserId(userId)

			if player then
				player:SetAttribute(PULL_TAG_ATTRIBUTE, false)
			end
		end
	end
end

local function build_square_id(modeName: string, container: Instance): string
	return modeName .. "::" .. container:GetFullName()
end

local function try_add_square(
	modeConfig: ModeConfig,
	container: Instance,
	existingByContainer: { [Instance]: MatchSquare },
	seenContainers: { [Instance]: boolean },
	output: { MatchSquare }
): ()
	local side1 = container:FindFirstChild(SIDE1_NAME)
	local side2 = container:FindFirstChild(SIDE2_NAME)

	if not side1 or not side2 then
		return
	end

	local side1Hitbox = side1:FindFirstChild(HITBOX_NAME)
	local side2Hitbox = side2:FindFirstChild(HITBOX_NAME)

	if not side1Hitbox or not side1Hitbox:IsA("BasePart") then
		return
	end

	if not side2Hitbox or not side2Hitbox:IsA("BasePart") then
		return
	end

	if seenContainers[container] then
		return
	end

	seenContainers[container] = true
	local previous = existingByContainer[container]

	if previous then
		previous.container = container
		previous.side1Hitbox = side1Hitbox
		previous.side2Hitbox = side2Hitbox
		previous.modeConfig = modeConfig
		table.insert(output, previous)
		return
	end

	table.insert(output, {
		id = build_square_id(modeConfig.mode, container),
		modeConfig = modeConfig,
		container = container,
		side1Hitbox = side1Hitbox,
		side2Hitbox = side2Hitbox,
		busy = false,
		cooldownUntil = 0,
	})
end

local function refresh_squares(): ()
	local now = os.clock()

	if now - lastDiscoveryAt < DISCOVERY_INTERVAL then
		return
	end

	lastDiscoveryAt = now
	local matchSquaresFolder = workspace:FindFirstChild(MATCH_SQUARES_FOLDER_NAME)

	if not matchSquaresFolder or not matchSquaresFolder:IsA("Folder") then
		if not warnedMissingFolder then
			warnedMissingFolder = true
			debug_log("workspace." .. MATCH_SQUARES_FOLDER_NAME .. " nao encontrado.")
		end

		trackedSquares = {}
		return
	end

	warnedMissingFolder = false
	local existingByContainer: { [Instance]: MatchSquare } = {}

	for _, square in trackedSquares do
		existingByContainer[square.container] = square
	end

	local nextSquares: { MatchSquare } = {}
	local seenContainers: { [Instance]: boolean } = {}

	for _, modeFolder in matchSquaresFolder:GetChildren() do
		local modeConfig = MatchmakingDictionary.get_mode(modeFolder.Name)

		if not modeConfig then
			continue
		end

		try_add_square(modeConfig, modeFolder, existingByContainer, seenContainers, nextSquares)

		for _, descendant in modeFolder:GetDescendants() do
			try_add_square(modeConfig, descendant, existingByContainer, seenContainers, nextSquares)
		end
	end

	trackedSquares = nextSquares

	if #trackedSquares ~= lastSquaresCount then
		lastSquaresCount = #trackedSquares
		debug_log("Squares ativos: " .. tostring(#trackedSquares))
	end
end

local function get_players_in_hitbox(hitbox: BasePart): { Player }
	local charactersFolder = get_characters_folder()

	if not charactersFolder then
		return {}
	end

	overlapParams.FilterDescendantsInstances = { charactersFolder }

	local success, parts = pcall(function()
		return workspace:GetPartsInPart(hitbox, overlapParams)
	end)

	if not success then
		return {}
	end

	local playersByUserId: { [number]: Player } = {}

	for _, part in parts do
		local model = part:FindFirstAncestorOfClass("Model")

		if not model then
			continue
		end

		local player = Players:GetPlayerFromCharacter(model)

		if not player then
			continue
		end

		playersByUserId[player.UserId] = player
	end

	local playersList: { Player } = {}

	for _, player in playersByUserId do
		table.insert(playersList, player)
	end

	table.sort(playersList, function(a: Player, b: Player): boolean
		return a.UserId < b.UserId
	end)

	return playersList
end

local function get_available_players(playersList: { Player }): { Player }
	local available: { Player } = {}

	for _, player in playersList do
		if is_player_locked(player.UserId) then
			continue
		end

		if player:GetAttribute("IsMatchmakingQueued") == true then
			continue
		end

		table.insert(available, player)
	end

	return available
end

local function find_descendant_by_name_case_insensitive(root: Instance, expectedNameLower: string): Instance?
	for _, descendant in root:GetDescendants() do
		if string.lower(descendant.Name) == expectedNameLower then
			return descendant
		end
	end

	return nil
end

local function get_or_create_square_text_label(container: Instance): TextLabel?
	local roomScreenPart = find_descendant_by_name_case_insensitive(container, ROOM_SCREEN_PART_NAME)

	if not roomScreenPart or not roomScreenPart:IsA("BasePart") then
		return nil
	end

	local surfaceGui = roomScreenPart:FindFirstChildWhichIsA("SurfaceGui")

	if not surfaceGui then
		return nil
	end

	surfaceGui.Enabled = true

	local namedLabel = surfaceGui:FindFirstChild("Count", true)

	if namedLabel and namedLabel:IsA("TextLabel") then
		namedLabel.TextScaled = false
		namedLabel.TextSize = 72
		return namedLabel
	end

	local label = surfaceGui:FindFirstChildWhichIsA("TextLabel", true)

	if label then
		label.TextScaled = false
		label.TextSize = 72
		return label
	end

	local created = Instance.new("TextLabel")
	created.Name = "Count"
	created.BackgroundTransparency = 1
	created.BorderSizePixel = 0
	created.Size = UDim2.new(1, 0, 1, 0)
	created.Position = UDim2.new(0, 0, 0, 0)
	created.TextScaled = false
	created.TextSize = 72
	created.Font = Enum.Font.GothamBold
	created.TextColor3 = Color3.fromRGB(255, 255, 255)
	created.TextStrokeTransparency = 0
	created.Text = ""
	created.Parent = surfaceGui
	return created
end

local function update_square_text(square: MatchSquare, side1Count: number, side2Count: number): ()
	local label = get_or_create_square_text_label(square.container)

	if not label then
		return
	end

	local sideMax = square.modeConfig.teamSize
	label.Text = tostring(side2Count) .. "/" .. tostring(sideMax) .. " | " .. tostring(side1Count) .. "/" .. tostring(sideMax)
end

local function pick_players_for_side(playersOnSide: { Player }, required: number, blockedUsers: { [number]: boolean }): { Player }
	local selected: { Player } = {}

	for _, player in playersOnSide do
		if blockedUsers[player.UserId] then
			continue
		end

		table.insert(selected, player)
		blockedUsers[player.UserId] = true

		if #selected >= required then
			break
		end
	end

	return selected
end

local function process_square(square: MatchSquare): ()
	if not square.container.Parent then
		return
	end

	if not square.side1Hitbox.Parent or not square.side2Hitbox.Parent then
		return
	end

	local side1PlayersAll = get_players_in_hitbox(square.side1Hitbox)
	local side2PlayersAll = get_players_in_hitbox(square.side2Hitbox)
	update_square_text(square, #side1PlayersAll, #side2PlayersAll)

	if workspace:GetAttribute(MATCH_WORKSPACE_ATTRIBUTE_NAME) == true then
		return
	end

	if square.busy then
		return
	end

	if os.clock() < square.cooldownUntil then
		return
	end

	local teamSize = square.modeConfig.teamSize
	local side1Players = get_available_players(side1PlayersAll)
	local side2Players = get_available_players(side2PlayersAll)

	if #side1Players < teamSize or #side2Players < teamSize then
		return
	end

	local blockedUsers: { [number]: boolean } = {}
	local selectedSide1 = pick_players_for_side(side1Players, teamSize, blockedUsers)
	local selectedSide2 = pick_players_for_side(side2Players, teamSize, blockedUsers)

	if #selectedSide1 < teamSize or #selectedSide2 < teamSize then
		return
	end

	local playersToTeleport: { Player } = {}
	local users: { number } = {}
	local teamByUserId: { [number]: string } = {}

	for _, player in selectedSide1 do
		table.insert(playersToTeleport, player)
		table.insert(users, player.UserId)
		teamByUserId[player.UserId] = TEAM_RED_NAME
	end

	for _, player in selectedSide2 do
		table.insert(playersToTeleport, player)
		table.insert(users, player.UserId)
		teamByUserId[player.UserId] = TEAM_BLUE_NAME
	end

	square.busy = true
	lock_players(playersToTeleport)
	debug_log(
		"Puxando " .. square.modeConfig.mode .. " em " .. square.id .. " com " .. tostring(#playersToTeleport) .. " jogadores."
	)

	local successCreate, createResult = MatchCreationService.create_reserved_match(square.modeConfig, users, teamByUserId, nil)

	if not successCreate then
		square.busy = false
		square.cooldownUntil = os.clock() + FAILURE_COOLDOWN
		unlock_players(playersToTeleport)
		debug_log("Falha ao reservar servidor privado: " .. tostring(createResult))
		return
	end

	local matchPackage = createResult
	local successTeleport, teleportResult = MatchCreationService.teleport_players(playersToTeleport, matchPackage, {
		source = "MatchSquares",
		sourceJobId = SOURCE_JOB_ID,
		squareId = square.id,
	})

	square.busy = false

	if successTeleport then
		square.cooldownUntil = os.clock() + SUCCESS_COOLDOWN
		debug_log("Teleport iniciado para " .. square.modeConfig.mode .. " em " .. square.id .. ".")
		return
	end

	square.cooldownUntil = os.clock() + FAILURE_COOLDOWN
	unlock_players(playersToTeleport)
	debug_log("Falha no teleport para " .. square.modeConfig.mode .. ": " .. tostring(teleportResult))
end

local function on_player_removing(player: Player): ()
	playerLockUntil[player.UserId] = nil
	player:SetAttribute(PULL_TAG_ATTRIBUTE, false)
end

------------------//MAIN FUNCTIONS
Players.PlayerRemoving:Connect(on_player_removing)

TeleportService.TeleportInitFailed:Connect(function(player: Player)
	if player:GetAttribute(PULL_TAG_ATTRIBUTE) == true then
		player:SetAttribute(PULL_TAG_ATTRIBUTE, false)
		playerLockUntil[player.UserId] = nil
	end
end)

task.spawn(function()
	while true do
		refresh_squares()
		cleanup_player_locks()

		for _, square in trackedSquares do
			process_square(square)
		end

		task.wait(SCAN_INTERVAL)
	end
end)

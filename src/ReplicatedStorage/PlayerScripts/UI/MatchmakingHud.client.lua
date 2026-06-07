------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService: RunService = game:GetService("RunService")
local StarterGui: StarterGui = game:GetService("StarterGui")
local TextChatService: TextChatService = game:GetService("TextChatService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local MatchmakingClientService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("MatchmakingClientService"))

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Success = Color3.fromRGB(130, 255, 175),
	Warn = Color3.fromRGB(255, 218, 120),
	Error = Color3.fromRGB(255, 135, 135),
}

local SELECTED_COLOR = Color3.fromRGB(64, 170, 105)
local DISABLED_COLOR = Color3.fromRGB(72, 72, 72)
local TEAM_RED_NAME = "Red"
local TEAM_BLUE_NAME = "Blue"
local MATCH_ROOT_NAME = "RoundLoss/Win"

------------------//TYPES
type ButtonDefault = {
	backgroundColor: Color3,
	textColor: Color3,
	text: string,
}

type HudPlayerEntry = {
	userId: number,
	username: string,
	displayName: string,
	teamName: string,
	kills: number,
	level: number,
	isAlive: boolean,
}

type KillPresentationPayload = {
	killerUserId: number?,
	killerUsername: string,
	killerDisplayName: string,
	killerLevel: number,
	weaponName: string,
}

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local lobbyFrame: ScreenGui = playerGui:WaitForChild("Lobby") :: ScreenGui
local lobbyHolder: Frame = lobbyFrame:WaitForChild("Holder") :: Frame
local lobbyTimerLabel: TextLabel = lobbyHolder:WaitForChild("Timer") :: TextLabel

local matchFrame: ScreenGui = playerGui:WaitForChild("Match") :: ScreenGui
local matchRoot: GuiObject = matchFrame:WaitForChild(MATCH_ROOT_NAME) :: GuiObject
local matchEnemiesFrame: GuiObject = matchRoot:WaitForChild("Enemies") :: GuiObject
local matchEnemyTemplate: GuiObject = matchEnemiesFrame:WaitForChild("aliveEnemy") :: GuiObject
local matchAlliesFrame: GuiObject = matchRoot:WaitForChild("Allies") :: GuiObject
local matchAllyTemplate: GuiObject = matchAlliesFrame:WaitForChild("aliveAllies") :: GuiObject
local matchTopCenter: GuiObject = matchRoot:WaitForChild("TC") :: GuiObject
local matchAlliesPointLabel: TextLabel = matchTopCenter:WaitForChild("AlliesPoint") :: TextLabel
local matchEnemiesPointLabel: TextLabel = matchTopCenter:WaitForChild("EnemiesPoint") :: TextLabel
local matchInfoLabel: TextLabel = matchTopCenter:WaitForChild("info") :: TextLabel
local matchTimeLabel: TextLabel = matchTopCenter:WaitForChild("time") :: TextLabel
local matchResultFrame: GuiObject = matchRoot:WaitForChild("WL") :: GuiObject
local matchResultLoseLabel: GuiObject = matchResultFrame:WaitForChild("L") :: GuiObject
local matchResultRoundLabel: Instance = matchResultFrame:WaitForChild("Round")
local matchResultWinLabel: GuiObject = matchResultFrame:WaitForChild("W") :: GuiObject
local killPresentationFrame: GuiObject = matchRoot:WaitForChild("killApresentation") :: GuiObject
local killPresentationChar: Instance = killPresentationFrame:WaitForChild("char")
local killPresentationArr: TextLabel = killPresentationFrame:WaitForChild("arr") :: TextLabel
local killPresentationLevel: TextLabel = killPresentationFrame:WaitForChild("lvl") :: TextLabel
local killPresentationName: TextLabel = killPresentationFrame:WaitForChild("PlayerName") :: TextLabel
local killPresentationWeapon: TextLabel = killPresentationFrame:WaitForChild("Weapon") :: TextLabel

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local matchSessionRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.MATCH_SESSION_REMOTE_EVENT_NAME) :: RemoteEvent

local queuedMode: string? = nil
local queuedAt = 0
local queueCounts: MatchmakingClientService.QueueCounts = MatchmakingClientService.get_queue_counts()

local isMatchHud = false
local matchPhase = "Lobby"
local matchPhaseEndsAt = 0
local matchRedScore = 0
local matchBlueScore = 0
local matchRoundNumber = 0
local matchPlayerTeamName: string? = nil
local matchRoundWinnerTeamName: string? = nil
local matchRedPlayers: { HudPlayerEntry } = {}
local matchBluePlayers: { HudPlayerEntry } = {}
local matchKillPresentation: KillPresentationPayload? = nil

local modeButtons: { [string]: TextButton } = {}
local buttonDefaults: { [TextButton]: ButtonDefault } = {}

local removeStateListener: (() -> ())? = nil
local removeDebugListener: (() -> ())? = nil
local removeQueueCountsListener: (() -> ())? = nil
local timerConnection: RBXScriptConnection? = nil
local matchConnection: RBXScriptConnection? = nil

------------------//FUNCTIONS
local function get_chat_color(colorName: string?): Color3
	if colorName and CHAT_COLORS[colorName] then
		return CHAT_COLORS[colorName]
	end

	return CHAT_COLORS.Info
end

local function format_time(seconds: number): string
	local safeSeconds = math.max(0, math.floor(seconds))
	local minutes = math.floor(safeSeconds / 60)
	local remainingSeconds = safeSeconds % 60

	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function set_text(target: Instance?, text: string): ()
	if not target then
		return
	end

	if target:IsA("TextLabel") or target:IsA("TextButton") or target:IsA("TextBox") then
		target.Text = text
	end
end

local function set_visible(target: Instance?, visible: boolean): ()
	if not target then
		return
	end

	if target:IsA("GuiObject") then
		target.Visible = visible
	end
end

local function try_system_message(text: string, colorName: string?): boolean
	local textChannels = TextChatService:FindFirstChild("TextChannels")
	local generalChannel = textChannels and textChannels:FindFirstChild("RBXGeneral")

	if generalChannel and generalChannel:IsA("TextChannel") then
		generalChannel:DisplaySystemMessage(text)
		return true
	end

	local success = pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = text,
			Color = get_chat_color(colorName),
		})
	end)

	return success
end

local function send_system_message(message: string, colorName: string?): ()
	local text = MatchmakingDictionary.DEBUG_PREFIX .. " " .. message

	if try_system_message(text, colorName) then
		return
	end

	task.spawn(function()
		local attempts = 0

		while attempts < 10 do
			attempts += 1
			task.wait(0.5)

			if try_system_message(text, colorName) then
				return
			end
		end
	end)
end

local function set_lobby_timer_visible(visible: boolean): ()
	lobbyTimerLabel.Visible = visible

	if not visible then
		lobbyTimerLabel.Text = "00:00"
	end
end

local function clear_viewport(viewport: ViewportFrame): ()
	for _, child in viewport:GetChildren() do
		child:Destroy()
	end

	viewport.CurrentCamera = nil
end

local function build_character_clone_for_viewport(userId: number): Model?
	local targetPlayer = Players:GetPlayerByUserId(userId)

	if not targetPlayer then
		return nil
	end

	local character = targetPlayer.Character

	if not character or not character:IsA("Model") then
		return nil
	end

	local originalArchivable = character.Archivable
	character.Archivable = true

	local success, cloneResult = pcall(function()
		return character:Clone()
	end)

	character.Archivable = originalArchivable

	if not success or not cloneResult or not cloneResult:IsA("Model") then
		return nil
	end

	local clone = cloneResult
	local humanoid = clone:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	return clone
end

local function render_player_viewport(viewport: ViewportFrame, userId: number): boolean
	clear_viewport(viewport)

	local characterClone = build_character_clone_for_viewport(userId)

	if not characterClone then
		return false
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport
	characterClone.Parent = worldModel

	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local head = characterClone:FindFirstChild("Head")
	local humanoidRootPart = characterClone:FindFirstChild("HumanoidRootPart")

	if head and head:IsA("BasePart") then
		local faceFocus = head.Position + Vector3.new(0, 0.05, 0)
		local faceDirection = head.CFrame.LookVector

		if faceDirection.Magnitude < 0.001 then
			faceDirection = Vector3.new(0, 0, -1)
		end

		local cameraDistance = math.max(head.Size.Y * 3.2, 1.9)
		local cameraHeightOffset = head.Size.Y * 0.08
		local cameraPosition = faceFocus + faceDirection.Unit * cameraDistance + Vector3.new(0, cameraHeightOffset, 0)

		camera.FieldOfView = 23
		camera.CFrame = CFrame.lookAt(cameraPosition, faceFocus)
		return true
	end

	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		local focusPosition = humanoidRootPart.Position + Vector3.new(0, 1.45, 0)
		camera.FieldOfView = 28
		camera.CFrame = CFrame.lookAt(focusPosition + Vector3.new(0, 0.05, 2.4), focusPosition)
		return true
	end

	return true
end

local function find_viewport(root: Instance?): ViewportFrame?
	if not root then
		return nil
	end

	if root:IsA("ViewportFrame") then
		return root
	end

	local descendant = root:FindFirstChildWhichIsA("ViewportFrame", true)

	if descendant then
		return descendant
	end

	return nil
end

local function sanitize_player_entries(rawPlayers: any): { HudPlayerEntry }
	local playersList: { HudPlayerEntry } = {}

	if typeof(rawPlayers) ~= "table" then
		return playersList
	end

	for _, rawEntry in rawPlayers do
		if typeof(rawEntry) ~= "table" or typeof(rawEntry.userId) ~= "number" then
			continue
		end

		local username = if typeof(rawEntry.username) == "string" and rawEntry.username ~= "" then rawEntry.username else tostring(rawEntry.userId)
		local displayName = if typeof(rawEntry.displayName) == "string" and rawEntry.displayName ~= "" then rawEntry.displayName else username
		local teamName = if typeof(rawEntry.teamName) == "string" then rawEntry.teamName else ""
		local kills = if typeof(rawEntry.kills) == "number" then math.max(0, math.floor(rawEntry.kills)) else 0
		local level = if typeof(rawEntry.level) == "number" then math.max(1, math.floor(rawEntry.level)) else 1

		table.insert(playersList, {
			userId = math.floor(rawEntry.userId),
			username = username,
			displayName = displayName,
			teamName = teamName,
			kills = kills,
			level = level,
			isAlive = rawEntry.isAlive == true,
		})
	end

	return playersList
end

local function sanitize_kill_presentation(rawPayload: any): KillPresentationPayload?
	if typeof(rawPayload) ~= "table" then
		return nil
	end

	local killerUsername = if typeof(rawPayload.killerUsername) == "string" and rawPayload.killerUsername ~= "" then rawPayload.killerUsername else ""

	if killerUsername == "" then
		return nil
	end

	local killerDisplayName = if typeof(rawPayload.killerDisplayName) == "string" and rawPayload.killerDisplayName ~= "" then rawPayload.killerDisplayName else killerUsername
	local weaponName = if typeof(rawPayload.weaponName) == "string" and rawPayload.weaponName ~= "" then rawPayload.weaponName else "Unknown"
	local killerLevel = if typeof(rawPayload.killerLevel) == "number" then math.max(1, math.floor(rawPayload.killerLevel)) else 1
	local killerUserId = if typeof(rawPayload.killerUserId) == "number" then math.floor(rawPayload.killerUserId) else nil

	return {
		killerUserId = killerUserId,
		killerUsername = killerUsername,
		killerDisplayName = killerDisplayName,
		killerLevel = killerLevel,
		weaponName = weaponName,
	}
end

local function clear_player_cards(container: GuiObject, template: GuiObject): ()
	for _, child in container:GetChildren() do
		if child ~= template and child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	template.Visible = false
end

local function populate_player_card(card: GuiObject, playerEntry: HudPlayerEntry, layoutOrder: number): ()
	card.Name = string.format("%s_%d", card.Name, playerEntry.userId)
	card.LayoutOrder = layoutOrder
	card.Visible = true
	card:SetAttribute("IsAlive", playerEntry.isAlive)

	set_text(card:FindFirstChild("kc"), tostring(playerEntry.kills))

	local viewport = find_viewport(card:FindFirstChild("char"))

	if viewport then
		viewport.Visible = render_player_viewport(viewport, playerEntry.userId)
	end
end

local function render_player_cards(container: GuiObject, template: GuiObject, playerEntries: { HudPlayerEntry }): ()
	clear_player_cards(container, template)

	for index, playerEntry in playerEntries do
		local clone = template:Clone()
		clone.Parent = container
		populate_player_card(clone, playerEntry, index)
	end
end

local function get_active_team_name(): string?
	if matchPlayerTeamName == TEAM_RED_NAME or matchPlayerTeamName == TEAM_BLUE_NAME then
		return matchPlayerTeamName
	end

	for _, playerEntry in matchRedPlayers do
		if playerEntry.userId == player.UserId then
			return TEAM_RED_NAME
		end
	end

	for _, playerEntry in matchBluePlayers do
		if playerEntry.userId == player.UserId then
			return TEAM_BLUE_NAME
		end
	end

	if player.Team and (player.Team.Name == TEAM_RED_NAME or player.Team.Name == TEAM_BLUE_NAME) then
		return player.Team.Name
	end

	return nil
end

local function get_team_perspective(): ({ HudPlayerEntry }, { HudPlayerEntry }, number, number)
	local activeTeamName = get_active_team_name()

	if activeTeamName == TEAM_BLUE_NAME then
		return matchBluePlayers, matchRedPlayers, matchBlueScore, matchRedScore
	end

	return matchRedPlayers, matchBluePlayers, matchRedScore, matchBlueScore
end

local function build_info_text(): string
	if matchPhase == "LoadingPlayers" then
		return "Loading"
	end

	if matchPhase == "MapVote" then
		return "Map Vote"
	end

	if matchRoundNumber > 0 then
		return "Round " .. tostring(matchRoundNumber)
	end

	return "Match"
end

local function update_match_timer(): ()
	if not isMatchHud then
		matchTimeLabel.Text = "00:00"
		return
	end

	if matchPhaseEndsAt <= 0 then
		matchTimeLabel.Text = "00:00"
		return
	end

	matchTimeLabel.Text = format_time(math.max(0, matchPhaseEndsAt - os.time()))
end

local function refresh_match_summary(): ()
	local _, _, alliesScore, enemiesScore = get_team_perspective()

	matchAlliesPointLabel.Text = tostring(alliesScore)
	matchEnemiesPointLabel.Text = tostring(enemiesScore)
	matchInfoLabel.Text = build_info_text()
	set_text(matchResultRoundLabel, "ROUND " .. tostring(math.max(matchRoundNumber, 1)))
	update_match_timer()
end

local function refresh_round_result(): ()
	local activeTeamName = get_active_team_name()
	local hasWinner = matchRoundWinnerTeamName == TEAM_RED_NAME or matchRoundWinnerTeamName == TEAM_BLUE_NAME
	local shouldShow = isMatchHud and hasWinner and (matchPhase == "RoundBreak" or matchPhase == "MatchWin")
	local hasPerspective = activeTeamName == TEAM_RED_NAME or activeTeamName == TEAM_BLUE_NAME
	local didWin = shouldShow and hasPerspective and activeTeamName == matchRoundWinnerTeamName

	set_visible(matchResultFrame, shouldShow)
	set_visible(matchResultWinLabel, shouldShow and didWin)
	set_visible(matchResultLoseLabel, shouldShow and hasPerspective and not didWin)

	local showKillPresentation = shouldShow and matchKillPresentation ~= nil
	set_visible(killPresentationFrame, showKillPresentation)

	if not showKillPresentation or not matchKillPresentation then
		return
	end

	killPresentationName.Text = matchKillPresentation.killerDisplayName
	killPresentationArr.Text = "@" .. matchKillPresentation.killerUsername
	killPresentationLevel.Text = tostring(matchKillPresentation.killerLevel)
	killPresentationWeapon.Text = matchKillPresentation.weaponName

	local viewport = find_viewport(killPresentationChar)

	if viewport then
		local killerUserId = matchKillPresentation.killerUserId
		local rendered = killerUserId ~= nil and render_player_viewport(viewport, killerUserId) or false
		viewport.Visible = rendered
	end
end

local function clear_match_players(): ()
	render_player_cards(matchAlliesFrame, matchAllyTemplate, {})
	render_player_cards(matchEnemiesFrame, matchEnemyTemplate, {})
end

local function refresh_match_players(): ()
	local alliesPlayers, enemyPlayers = get_team_perspective()
	render_player_cards(matchAlliesFrame, matchAllyTemplate, alliesPlayers)
	render_player_cards(matchEnemiesFrame, matchEnemyTemplate, enemyPlayers)
end

local function refresh_match_ui(): ()
	if not isMatchHud then
		clear_match_players()
		set_visible(matchResultFrame, false)
		set_visible(killPresentationFrame, false)
		return
	end

	refresh_match_summary()
	refresh_match_players()
	refresh_round_result()
end

local function update_lobby_timer(): ()
	if not queuedMode then
		return
	end

	lobbyTimerLabel.Text = format_time(os.time() - queuedAt)
end

local function update_timers(): ()
	if isMatchHud then
		update_match_timer()
		return
	end

	update_lobby_timer()
end

local function set_hud_mode(matchMode: boolean): ()
	isMatchHud = matchMode
	matchRoot.Visible = matchMode

	if matchMode then
		set_lobby_timer_visible(false)
		return
	end

	set_visible(matchResultFrame, false)
	set_visible(killPresentationFrame, false)
end

local function refresh_buttons(): ()
	for mode: string, button: TextButton in modeButtons do
		local buttonDefault = buttonDefaults[button]
		local queueCount = queueCounts[mode] or 0
		local buttonText = buttonDefault.text .. " (" .. tostring(queueCount) .. ")"
		local isQueuedMode = queuedMode == mode
		local isAvailable = not queuedMode or isQueuedMode

		if isMatchHud then
			button.Active = false
			button.AutoButtonColor = false
			button.Text = buttonText
			button.BackgroundColor3 = DISABLED_COLOR
			continue
		end

		button.Active = isAvailable
		button.AutoButtonColor = isAvailable

		if isQueuedMode then
			button.Text = "Sair (" .. tostring(queueCount) .. ")"
			button.BackgroundColor3 = SELECTED_COLOR
			continue
		end

		if queuedMode then
			button.Text = buttonText
			button.BackgroundColor3 = DISABLED_COLOR
			continue
		end

		button.Text = buttonText
		button.BackgroundColor3 = buttonDefault.backgroundColor
		button.TextColor3 = buttonDefault.textColor
	end
end

local function apply_queue_state(state: MatchmakingClientService.QueueState): ()
	if state.isQueued and state.mode then
		queuedMode = state.mode
		queuedAt = state.queuedAt or os.time()
		set_lobby_timer_visible(true)
		update_lobby_timer()
	else
		queuedMode = nil
		queuedAt = 0
		set_lobby_timer_visible(false)
	end

	refresh_buttons()
end

local function bind_button(mode: string, button: TextButton): ()
	button.MouseButton1Click:Connect(function()
		if isMatchHud then
			return
		end

		if queuedMode == mode then
			MatchmakingClientService.request_leave()
			return
		end

		if queuedMode then
			return
		end

		MatchmakingClientService.request_join(mode)
	end)
end

local function find_mode_button_template(): TextButton?
	for _, child in lobbyHolder:GetChildren() do
		if child:IsA("TextButton") then
			return child
		end
	end

	return nil
end

local function get_or_create_mode_button(modeConfig: MatchmakingDictionary.ModeConfig): TextButton?
	local existingButton = lobbyHolder:FindFirstChild(modeConfig.buttonName)

	if existingButton and existingButton:IsA("TextButton") then
		return existingButton
	end

	if modeConfig.mode ~= MatchmakingDictionary.DEATHMATCH_MODE then
		warn("Botao de matchmaking nao encontrado: " .. modeConfig.buttonName)
		return nil
	end

	local template = lobbyHolder:FindFirstChild("4v4")
	if not template or not template:IsA("TextButton") then
		template = find_mode_button_template()
	end

	if not template then
		warn("Nao foi possivel criar botao Deathmatch: nenhum TextButton de template encontrado.")
		return nil
	end

	local button = template:Clone()
	button.Name = modeConfig.buttonName
	button.Text = modeConfig.buttonName
	button.LayoutOrder = template.LayoutOrder + 1
	button.Parent = lobbyHolder
	return button
end

local function apply_queue_counts(counts: MatchmakingClientService.QueueCounts): ()
	queueCounts = counts
	refresh_buttons()
end

local function apply_match_payload(payload: any): ()
	if typeof(payload) ~= "table" then
		return
	end

	local isMatch = payload.isMatch == true
	set_hud_mode(isMatch)

	if not isMatch then
		matchPhase = "Lobby"
		matchPhaseEndsAt = 0
		matchRedScore = 0
		matchBlueScore = 0
		matchRoundNumber = 0
		matchPlayerTeamName = nil
		matchRoundWinnerTeamName = nil
		matchRedPlayers = {}
		matchBluePlayers = {}
		matchKillPresentation = nil
		refresh_match_ui()
		refresh_buttons()
		return
	end

	if typeof(payload.redScore) == "number" then
		matchRedScore = math.max(0, math.floor(payload.redScore))
	end

	if typeof(payload.blueScore) == "number" then
		matchBlueScore = math.max(0, math.floor(payload.blueScore))
	end

	if typeof(payload.phase) == "string" then
		matchPhase = payload.phase
	end

	if typeof(payload.round) == "number" then
		matchRoundNumber = math.max(0, math.floor(payload.round))
	end

	if typeof(payload.phaseEndsAt) == "number" then
		matchPhaseEndsAt = payload.phaseEndsAt
	else
		matchPhaseEndsAt = 0
	end

	if typeof(payload.playerTeamName) == "string" then
		matchPlayerTeamName = payload.playerTeamName
	elseif typeof(payload.myTeamName) == "string" then
		matchPlayerTeamName = payload.myTeamName
	else
		matchPlayerTeamName = nil
	end

	if typeof(payload.roundWinnerTeam) == "string" then
		matchRoundWinnerTeamName = payload.roundWinnerTeam
	else
		matchRoundWinnerTeamName = nil
	end

	matchRedPlayers = sanitize_player_entries(payload.redPlayers)
	matchBluePlayers = sanitize_player_entries(payload.bluePlayers)
	matchKillPresentation = sanitize_kill_presentation(payload.killPresentation)

	refresh_match_ui()
	refresh_buttons()
end

------------------//INIT
matchAllyTemplate.Visible = false
matchEnemyTemplate.Visible = false
set_visible(matchResultFrame, false)
set_visible(killPresentationFrame, false)
set_hud_mode(false)
set_lobby_timer_visible(false)
refresh_match_ui()

for _, modeConfig in MatchmakingDictionary.get_modes() do
	if modeConfig.isDeathmatch then
		continue
	end

	local button = get_or_create_mode_button(modeConfig)

	if not button then
		continue
	end

	modeButtons[modeConfig.mode] = button
	buttonDefaults[button] = {
		backgroundColor = button.BackgroundColor3,
		textColor = button.TextColor3,
		text = button.Text,
	}

	bind_button(modeConfig.mode, button)
end

removeStateListener = MatchmakingClientService.on_state_changed(function(state: MatchmakingClientService.QueueState)
	apply_queue_state(state)
end)

removeDebugListener = MatchmakingClientService.on_debug(function(payload: MatchmakingClientService.DebugPayload)
	send_system_message(payload.message, payload.colorName)
end)

removeQueueCountsListener = MatchmakingClientService.on_queue_counts_changed(function(counts: MatchmakingClientService.QueueCounts)
	apply_queue_counts(counts)
end)

matchConnection = matchSessionRemote.OnClientEvent:Connect(function(action: string, payload: any)
	if action == "State" then
		apply_match_payload(payload)
	end
end)

timerConnection = RunService.RenderStepped:Connect(update_timers)

MatchmakingClientService.start()
apply_queue_state(MatchmakingClientService.get_state())
apply_queue_counts(MatchmakingClientService.get_queue_counts())
MatchmakingClientService.request_sync()
send_system_message("HUD conectado.", "Info")

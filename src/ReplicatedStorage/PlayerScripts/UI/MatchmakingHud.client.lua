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

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local lobbyFrame: ScreenGui = playerGui:WaitForChild("Lobby") :: ScreenGui
local lobbyHolder: Frame = lobbyFrame:WaitForChild("Holder") :: Frame
local lobbyTimerLabel: TextLabel = lobbyHolder:WaitForChild("Timer") :: TextLabel

local matchFrame: ScreenGui = playerGui:WaitForChild("Match") :: ScreenGui
local matchHolder: Frame = matchFrame:WaitForChild("Holder") :: Frame
local matchWinFrame: Frame = matchFrame:WaitForChild("WinFrame") :: Frame
local matchTimerLabel: TextLabel = matchHolder:WaitForChild("Timer") :: TextLabel
local matchRedLabel: TextLabel = matchHolder:WaitForChild("Red") :: TextLabel
local matchBlueLabel: TextLabel = matchHolder:WaitForChild("Blue") :: TextLabel
local matchWinNameLabel: TextLabel = matchWinFrame:WaitForChild("WinName") :: TextLabel
local matchWinRedLabel: TextLabel = matchWinFrame:WaitForChild("Red") :: TextLabel
local matchWinBlueLabel: TextLabel = matchWinFrame:WaitForChild("Blue") :: TextLabel

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
local matchWinnerName = ""

local modeButtons: { [string]: TextButton } = {}
local buttonDefaults: { [TextButton]: { backgroundColor: Color3, textColor: Color3, text: string } } = {}

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

local function refresh_match_labels(): ()
	local redText = "Red : " .. tostring(matchRedScore)
	local blueText = "Blue : " .. tostring(matchBlueScore)

	matchRedLabel.Text = redText
	matchBlueLabel.Text = blueText
	matchWinRedLabel.Text = redText
	matchWinBlueLabel.Text = blueText
end

local function refresh_win_frame(): ()
	local showWinFrame = matchPhase == "MatchWin"
	matchWinFrame.Visible = showWinFrame

	if not showWinFrame then
		return
	end

	local displayName = matchWinnerName

	if displayName == "" then
		displayName = "Winner"
	end

	matchWinNameLabel.Text = displayName .. " win!"
end

local function update_lobby_timer(): ()
	if not queuedMode then
		return
	end

	lobbyTimerLabel.Text = format_time(os.time() - queuedAt)
end

local function update_match_timer(): ()
	if matchPhase == "LoadingPlayers" then
		matchTimerLabel.Text = "Waiting for players to load"
		return
	end

	if matchPhaseEndsAt <= 0 then
		matchTimerLabel.Text = "00:00"
		return
	end

	local remaining = math.max(0, matchPhaseEndsAt - os.time())
	matchTimerLabel.Text = format_time(remaining)
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

	if matchMode then
		set_lobby_timer_visible(false)
		return
	end

	matchWinFrame.Visible = false
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

	if typeof(payload.winnerName) == "string" then
		matchWinnerName = payload.winnerName
	else
		matchWinnerName = ""
	end

	if typeof(payload.phaseEndsAt) == "number" then
		matchPhaseEndsAt = payload.phaseEndsAt
	else
		matchPhaseEndsAt = 0
	end

	refresh_match_labels()
	refresh_win_frame()
	update_match_timer()
	refresh_buttons()
end

------------------//INIT
set_hud_mode(false)
set_lobby_timer_visible(false)
refresh_match_labels()
refresh_win_frame()
update_match_timer()

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

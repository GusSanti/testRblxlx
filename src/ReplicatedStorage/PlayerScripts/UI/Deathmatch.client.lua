------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local MatchmakingClientService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("MatchmakingClientService"))

local DEATHMATCH_MODE = MatchmakingDictionary.DEATHMATCH_MODE
local BACK_TO_LOBBY_ACTION = "DeathmatchBackToLobby"
local CLICK_COOLDOWN_SECONDS = 2

local SELECTED_COLOR = Color3.fromRGB(64, 170, 105)
local DISABLED_COLOR = Color3.fromRGB(72, 72, 72)

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local lobbyGui: ScreenGui = playerGui:WaitForChild("Lobby") :: ScreenGui
local lobbyHolder: GuiObject = lobbyGui:WaitForChild("Holder") :: GuiObject
local matchGui: ScreenGui = playerGui:WaitForChild("Match") :: ScreenGui
local matchHolder: GuiObject = matchGui:WaitForChild("Holder") :: GuiObject

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local matchSessionRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.MATCH_SESSION_REMOTE_EVENT_NAME) :: RemoteEvent

local deathmatchButton: TextButton? = nil
local deathmatchButtonDefaults: { backgroundColor: Color3, textColor: Color3, text: string }? = nil

local backButtonInstance: Instance = matchHolder:WaitForChild("Back")
local backButton: GuiButton? = if backButtonInstance:IsA("GuiButton") then (backButtonInstance :: GuiButton) else nil

local queuedMode: string? = nil
local queueTeleporting = false
local queueCount = 0
local isMatchHud = false
local isDeathmatchHud = false
local backRequestCooldown = false

------------------//FUNCTIONS
local function find_mode_button_template(): TextButton?
	local direct = lobbyHolder:FindFirstChild("4v4")

	if direct and direct:IsA("TextButton") then
		return direct
	end

	for _, child in lobbyHolder:GetChildren() do
		if child:IsA("TextButton") then
			return child
		end
	end

	return nil
end

local function get_or_create_deathmatch_button(): TextButton?
	local existing = lobbyHolder:FindFirstChild(DEATHMATCH_MODE)

	if existing and existing:IsA("TextButton") then
		return existing
	end

	local template = find_mode_button_template()

	if not template then
		warn("[DeathmatchMode] Nao foi possivel criar botao Deathmatch: template nao encontrado.")
		return nil
	end

	local button = template:Clone()
	button.Name = DEATHMATCH_MODE
	button.Text = DEATHMATCH_MODE
	button.LayoutOrder = template.LayoutOrder + 1
	button.Parent = lobbyHolder
	return button
end

local function refresh_deathmatch_button(): ()
	if not deathmatchButton or not deathmatchButtonDefaults then
		return
	end

	local buttonText = deathmatchButtonDefaults.text .. " (" .. tostring(queueCount) .. ")"
	local queuedDeathmatch = queuedMode == DEATHMATCH_MODE
	local queuedOtherMode = queuedMode ~= nil and not queuedDeathmatch

	if isMatchHud then
		deathmatchButton.Active = false
		deathmatchButton.AutoButtonColor = false
		deathmatchButton.Text = buttonText
		deathmatchButton.BackgroundColor3 = DISABLED_COLOR
		return
	end

	if queuedDeathmatch then
		if queueTeleporting then
			deathmatchButton.Active = false
			deathmatchButton.AutoButtonColor = false
			deathmatchButton.Text = "Entrando..."
			deathmatchButton.BackgroundColor3 = DISABLED_COLOR
		else
			deathmatchButton.Active = true
			deathmatchButton.AutoButtonColor = true
			deathmatchButton.Text = "Sair (" .. tostring(queueCount) .. ")"
			deathmatchButton.BackgroundColor3 = SELECTED_COLOR
		end

		return
	end

	if queuedOtherMode then
		deathmatchButton.Active = false
		deathmatchButton.AutoButtonColor = false
		deathmatchButton.Text = buttonText
		deathmatchButton.BackgroundColor3 = DISABLED_COLOR
		return
	end

	deathmatchButton.Active = true
	deathmatchButton.AutoButtonColor = true
	deathmatchButton.Text = buttonText
	deathmatchButton.BackgroundColor3 = deathmatchButtonDefaults.backgroundColor
	deathmatchButton.TextColor3 = deathmatchButtonDefaults.textColor
end

local function refresh_back_button(): ()
	if not backButton then
		return
	end

	local show = isDeathmatchHud
	local canUse = show and not backRequestCooldown

	backButton.Visible = show
	backButton.Active = canUse
	backButton.AutoButtonColor = canUse
end

local function apply_queue_state(state: MatchmakingClientService.QueueState): ()
	if state.isQueued and state.mode then
		queuedMode = state.mode
		queueTeleporting = state.teleporting == true
	else
		queuedMode = nil
		queueTeleporting = false
	end

	refresh_deathmatch_button()
end

local function apply_queue_counts(counts: MatchmakingClientService.QueueCounts): ()
	local nextValue = counts[DEATHMATCH_MODE]

	if typeof(nextValue) == "number" then
		queueCount = math.max(0, math.floor(nextValue))
	else
		queueCount = 0
	end

	refresh_deathmatch_button()
end

local function apply_match_state(payload: any): ()
	if typeof(payload) ~= "table" then
		return
	end

	local mode = if typeof(payload.mode) == "string" then payload.mode else nil
	isMatchHud = payload.isMatch == true
	isDeathmatchHud = isMatchHud and mode == DEATHMATCH_MODE

	if not isDeathmatchHud then
		backRequestCooldown = false
	end

	refresh_deathmatch_button()
	refresh_back_button()
end

------------------//MAIN FUNCTIONS
deathmatchButton = get_or_create_deathmatch_button()

if deathmatchButton then
	deathmatchButtonDefaults = {
		backgroundColor = deathmatchButton.BackgroundColor3,
		textColor = deathmatchButton.TextColor3,
		text = deathmatchButton.Text,
	}

	deathmatchButton.MouseButton1Click:Connect(function()
		if isMatchHud then
			return
		end

		local queuedDeathmatch = queuedMode == DEATHMATCH_MODE

		if queuedDeathmatch and not queueTeleporting then
			MatchmakingClientService.request_leave()
			return
		end

		if queuedMode then
			return
		end

		MatchmakingClientService.request_join(DEATHMATCH_MODE)
	end)
end

if backButton then
	backButton.Activated:Connect(function()
		if not isDeathmatchHud or backRequestCooldown then
			return
		end

		backRequestCooldown = true
		refresh_back_button()
		matchSessionRemote:FireServer(BACK_TO_LOBBY_ACTION)

		task.delay(CLICK_COOLDOWN_SECONDS, function()
			if not backButton or not backButton.Parent then
				return
			end

			backRequestCooldown = false
			refresh_back_button()
		end)
	end)
else
	warn("[DeathmatchMode] Match.Holder.Back existe, mas nao e um GuiButton.")
end

MatchmakingClientService.start()

MatchmakingClientService.on_state_changed(function(state: MatchmakingClientService.QueueState)
	apply_queue_state(state)
end)

MatchmakingClientService.on_queue_counts_changed(function(counts: MatchmakingClientService.QueueCounts)
	apply_queue_counts(counts)
end)

matchSessionRemote.OnClientEvent:Connect(function(action: string, payload: any)
	if action ~= "State" then
		return
	end

	apply_match_state(payload)
end)

------------------//INIT
if backButton then
	backButton.Visible = false
	backButton.Active = false
	backButton.AutoButtonColor = false
end

refresh_deathmatch_button()
apply_queue_state(MatchmakingClientService.get_state())
apply_queue_counts(MatchmakingClientService.get_queue_counts())
MatchmakingClientService.request_sync()

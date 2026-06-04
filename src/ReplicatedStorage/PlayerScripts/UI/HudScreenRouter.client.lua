------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui: StarterGui = game:GetService("StarterGui")
local TextChatService: TextChatService = game:GetService("TextChatService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))

local FORCE_MATCH_VALUE_NAME = "ForceMatch"
local CLOSE_PARENT_BUTTON_NAME = "CloseParent"
local DEBUG_PREFIX = MatchmakingDictionary.DEBUG_PREFIX .. " [HudRouter]"

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Warn = Color3.fromRGB(255, 218, 120),
}

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local lobbyFrame: ScreenGui = playerGui:WaitForChild("Lobby") :: ScreenGui
local matchFrame: ScreenGui = playerGui:WaitForChild("Match") :: ScreenGui

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local matchSessionRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.MATCH_SESSION_REMOTE_EVENT_NAME) :: RemoteEvent

local lastDebugSignature = ""
local closeButtonConnections: { [GuiButton]: RBXScriptConnection } = {}

------------------//FUNCTIONS
local function get_chat_color(colorName: string?): Color3
	if colorName and CHAT_COLORS[colorName] then
		return CHAT_COLORS[colorName]
	end

	return CHAT_COLORS.Info
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

local function send_debug(message: string, colorName: string?): ()
	local text = DEBUG_PREFIX .. " " .. message

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

local function get_local_force_match_value(): boolean?
	local value = workspace:FindFirstChild(FORCE_MATCH_VALUE_NAME)

	if value and value:IsA("BoolValue") then
		return value.Value
	end

	return nil
end

local function set_hud_visibility(isMatch: boolean): ()
	matchFrame.Enabled = isMatch
	lobbyFrame.Enabled = not isMatch
end

local function disconnect_close_button(button: GuiButton): ()
	local connection = closeButtonConnections[button]

	if not connection then
		return
	end

	connection:Disconnect()
	closeButtonConnections[button] = nil
end

local function close_parent_from_button(button: GuiButton): ()
	local parentObject = button.Parent

	if not parentObject then
		return
	end

	if parentObject:IsA("GuiObject") then
		parentObject.Visible = false
		return
	end

	if parentObject:IsA("ScreenGui") then
		parentObject.Enabled = false
	end
end

local function bind_close_parent_button(instance: Instance): ()
	if not instance:IsA("GuiButton") or instance.Name ~= CLOSE_PARENT_BUTTON_NAME then
		return
	end

	if closeButtonConnections[instance] then
		return
	end

	closeButtonConnections[instance] = instance.Activated:Connect(function()
		close_parent_from_button(instance)
	end)

	instance.Destroying:Connect(function()
		disconnect_close_button(instance)
	end)
end

local function build_debug_signature(isMatch: boolean, source: string, forceServer: boolean, forceLocal: string, mode: string, phase: string): string
	local matchToken = if isMatch then "1" else "0"
	local forceServerToken = if forceServer then "1" else "0"
	return table.concat({ matchToken, source, forceServerToken, forceLocal, mode, phase }, "|")
end

local function apply_match_state(payload: any): ()
	if typeof(payload) ~= "table" then
		return
	end

	local isMatch = payload.isMatch == true
	local source = if typeof(payload.source) == "string" then payload.source else "Unknown"
	local mode = if typeof(payload.mode) == "string" then payload.mode else "nil"
	local phase = if typeof(payload.phase) == "string" then payload.phase else "nil"
	local forceServer = payload.forceMatchEnabled == true
	local forceLocalValue = get_local_force_match_value()
	local forceLocalText = if forceLocalValue == nil then "nil" elseif forceLocalValue then "true" else "false"

	set_hud_visibility(isMatch)

	local signature = build_debug_signature(isMatch, source, forceServer, forceLocalText, mode, phase)

	if signature == lastDebugSignature then
		return
	end

	lastDebugSignature = signature

	local stateName = if isMatch then "MATCH" else "LOBBY"
	local colorName = if isMatch then "Warn" else "Info"

	send_debug(
		"HUD=" .. stateName .. " source=" .. source .. " mode=" .. mode .. " phase=" .. phase .. " forceServer=" .. tostring(forceServer) .. " forceLocal=" .. forceLocalText,
		colorName
	)
end

------------------//MAIN FUNCTIONS
matchSessionRemote.OnClientEvent:Connect(function(action: string, payload: any)
	if action ~= "State" then
		return
	end

	apply_match_state(payload)
end)

for _, descendant in playerGui:GetDescendants() do
	bind_close_parent_button(descendant)
end

playerGui.DescendantAdded:Connect(function(descendant: Instance)
	bind_close_parent_button(descendant)
end)

------------------//INIT
set_hud_visibility(false)
send_debug("Iniciado. Aguardando estado do servidor.", "Info")

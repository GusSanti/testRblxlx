------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))

------------------//VARIABLES
local MatchmakingClientService = {}

export type QueueState = {
	isQueued: boolean,
	mode: string?,
	queuedAt: number?,
	teleporting: boolean,
}

export type DebugPayload = {
	message: string,
	colorName: string?,
}

export type QueueCounts = {
	[string]: number,
}

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local remoteEvent: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.REMOTE_EVENT_NAME) :: RemoteEvent

local started = false
local remoteConnection: RBXScriptConnection? = nil

local currentState: QueueState = {
	isQueued = false,
	mode = nil,
	queuedAt = nil,
	teleporting = false,
}

local currentQueueCounts: QueueCounts = {}

for _, modeConfig in MatchmakingDictionary.get_modes() do
	currentQueueCounts[modeConfig.mode] = 0
end

local stateListeners: { (QueueState) -> () } = {}
local debugListeners: { (DebugPayload) -> () } = {}
local queueCountListeners: { (QueueCounts) -> () } = {}

------------------//FUNCTIONS
local function clone_state(state: QueueState): QueueState
	return {
		isQueued = state.isQueued,
		mode = state.mode,
		queuedAt = state.queuedAt,
		teleporting = state.teleporting,
	}
end

local function normalize_state(payload: any): QueueState
	if typeof(payload) ~= "table" then
		return {
			isQueued = false,
			mode = nil,
			queuedAt = nil,
			teleporting = false,
		}
	end

	local mode = if typeof(payload.mode) == "string" then payload.mode else nil
	local queuedAt = if typeof(payload.queuedAt) == "number" then payload.queuedAt else nil

	return {
		isQueued = payload.isQueued == true and mode ~= nil,
		mode = mode,
		queuedAt = queuedAt,
		teleporting = payload.teleporting == true,
	}
end

local function emit_state(state: QueueState): ()
	for _, callback in stateListeners do
		callback(clone_state(state))
	end
end

local function emit_debug(payload: DebugPayload): ()
	for _, callback in debugListeners do
		callback(payload)
	end
end

local function clone_queue_counts(queueCounts: QueueCounts): QueueCounts
	local copy: QueueCounts = {}

	for mode, countValue in queueCounts do
		copy[mode] = countValue
	end

	return copy
end

local function normalize_queue_counts(payload: any): QueueCounts
	local normalized = clone_queue_counts(currentQueueCounts)

	if typeof(payload) ~= "table" then
		return normalized
	end

	for _, modeConfig in MatchmakingDictionary.get_modes() do
		local value = payload[modeConfig.mode]

		if typeof(value) == "number" then
			normalized[modeConfig.mode] = math.max(0, math.floor(value))
		end
	end

	return normalized
end

local function emit_queue_counts(queueCounts: QueueCounts): ()
	local cloned = clone_queue_counts(queueCounts)

	for _, callback in queueCountListeners do
		callback(cloned)
	end
end

local function on_remote_event(action: string, payload: any): ()
	if action == "State" then
		currentState = normalize_state(payload)
		emit_state(currentState)
		return
	end

	if action == "QueueCounts" then
		currentQueueCounts = normalize_queue_counts(payload)
		emit_queue_counts(currentQueueCounts)
		return
	end

	if action == "Debug" then
		local message = if typeof(payload) == "table" and payload.message ~= nil then tostring(payload.message) else ""
		local colorName = if typeof(payload) == "table" and typeof(payload.colorName) == "string" then payload.colorName else nil

		emit_debug({
			message = message,
			colorName = colorName,
		})
	end
end

local function remove_state_listener(callback: (QueueState) -> ()): ()
	for index, listener in stateListeners do
		if listener == callback then
			table.remove(stateListeners, index)
			return
		end
	end
end

local function remove_debug_listener(callback: (DebugPayload) -> ()): ()
	for index, listener in debugListeners do
		if listener == callback then
			table.remove(debugListeners, index)
			return
		end
	end
end

local function remove_queue_count_listener(callback: (QueueCounts) -> ()): ()
	for index, listener in queueCountListeners do
		if listener == callback then
			table.remove(queueCountListeners, index)
			return
		end
	end
end

------------------//MAIN FUNCTIONS
function MatchmakingClientService.start(): ()
	if started then
		return
	end

	started = true
	remoteConnection = remoteEvent.OnClientEvent:Connect(on_remote_event)
	remoteEvent:FireServer("Sync")
end

function MatchmakingClientService.stop(): ()
	if remoteConnection then
		remoteConnection:Disconnect()
		remoteConnection = nil
	end

	started = false
end

function MatchmakingClientService.request_join(mode: string): ()
	remoteEvent:FireServer("Join", mode)
end

function MatchmakingClientService.request_leave(): ()
	remoteEvent:FireServer("Leave")
end

function MatchmakingClientService.request_sync(): ()
	remoteEvent:FireServer("Sync")
end

function MatchmakingClientService.get_state(): QueueState
	return clone_state(currentState)
end

function MatchmakingClientService.get_queue_counts(): QueueCounts
	return clone_queue_counts(currentQueueCounts)
end

function MatchmakingClientService.on_state_changed(callback: (QueueState) -> ()): (() -> ())
	table.insert(stateListeners, callback)

	return function()
		remove_state_listener(callback)
	end
end

function MatchmakingClientService.on_debug(callback: (DebugPayload) -> ()): (() -> ())
	table.insert(debugListeners, callback)

	return function()
		remove_debug_listener(callback)
	end
end

function MatchmakingClientService.on_queue_counts_changed(callback: (QueueCounts) -> ()): (() -> ())
	table.insert(queueCountListeners, callback)

	return function()
		remove_queue_count_listener(callback)
	end
end

return MatchmakingClientService

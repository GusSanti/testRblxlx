------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local MapVoteBridge = require(ServerStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("MapVoteBridge"))

------------------//VARIABLES
local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local matchSessionRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.MATCH_SESSION_REMOTE_EVENT_NAME) :: RemoteEvent

------------------//FUNCTIONS
local function debug_log(message: string): ()
	print("[MapVoteRemote] " .. message)
end

local function get_vote_handler(): ((Player, string) -> ())?
	local handler = MapVoteBridge.get_handler()

	if typeof(handler) == "function" then
		return handler :: (Player, string) -> ()
	end

	return nil
end

local function on_remote_event(player: Player, action: string, payload: any): ()
	if action ~= "VoteMap" then
		return
	end

	if typeof(payload) ~= "table" or typeof(payload.mapId) ~= "string" then
		return
	end

	local handler = get_vote_handler()

	if not handler then
		debug_log("Handler de voto ainda nao disponivel para " .. player.Name .. ".")
		return
	end

	local success, result = pcall(function()
		handler(player, payload.mapId)
	end)

	if not success then
		debug_log("Falha ao processar voto de " .. player.Name .. ": " .. tostring(result))
	end
end

------------------//INIT
matchSessionRemote.OnServerEvent:Connect(on_remote_event)
debug_log("Inicializado.")

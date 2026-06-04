------------------//CONSTANTS
local MatchmakingDictionary = {}

export type ModeConfig = {
	mode: string,
	teamSize: number,
	playersRequired: number,
	buttonName: string,
	isDeathmatch: boolean?,
	maxPlayers: number?,
}

MatchmakingDictionary.DESTINATION_PLACE_ID = 3093859530

MatchmakingDictionary.REMOTE_FOLDER_NAME = "Remotes"
MatchmakingDictionary.REMOTE_EVENT_NAME = "MatchmakingRemote"
MatchmakingDictionary.MATCH_SESSION_REMOTE_EVENT_NAME = "MatchSessionRemote"
MatchmakingDictionary.PARTY_REMOTE_EVENT_NAME = "PartyRemote"
MatchmakingDictionary.INVENTORY_REMOTE_EVENT_NAME = "InventoryRemote"
MatchmakingDictionary.SHOP_REMOTE_EVENT_NAME = "ShopRemote"
MatchmakingDictionary.DAILY_REWARD_REMOTE_EVENT_NAME = "DailyRewardRemote"

MatchmakingDictionary.PLAYER_STATE_MAP_NAME = "MatchmakingPlayerState_v1"
MatchmakingDictionary.MATCH_QUEUE_PREFIX = "MatchmakingQueue_v1_"
MatchmakingDictionary.ASSIGNMENT_QUEUE_PREFIX = "MatchmakingAssignment_v1_"
MatchmakingDictionary.DEATHMATCH_MODE = "Deathmatch"
MatchmakingDictionary.DEATHMATCH_SERVER_MAP_NAME = "DeathmatchServers_v1"
MatchmakingDictionary.DEATHMATCH_SERVER_TTL = 180
MatchmakingDictionary.DEATHMATCH_SERVER_STALE_SECONDS = 150
MatchmakingDictionary.DEATHMATCH_MAX_PLAYERS = 8

MatchmakingDictionary.MATCH_QUEUE_INVISIBILITY_TIMEOUT = 30
MatchmakingDictionary.ASSIGNMENT_QUEUE_INVISIBILITY_TIMEOUT = 20

MatchmakingDictionary.DEBUG_PREFIX = "[Matchmaking]"
MatchmakingDictionary.PARTY_MAX_MEMBERS = 6
MatchmakingDictionary.PARTY_INVITE_DURATION = 10

MatchmakingDictionary.MODE_ORDER = {
	"1v1",
	"2v2",
	"3v3",
	"4v4",
	"Deathmatch",
}

MatchmakingDictionary.MODES = {
	["1v1"] = {
		mode = "1v1",
		teamSize = 1,
		playersRequired = 2,
		buttonName = "1v1",
	},
	["2v2"] = {
		mode = "2v2",
		teamSize = 2,
		playersRequired = 4,
		buttonName = "2v2",
	},
	["3v3"] = {
		mode = "3v3",
		teamSize = 3,
		playersRequired = 6,
		buttonName = "3v3",
	},
	["4v4"] = {
		mode = "4v4",
		teamSize = 4,
		playersRequired = 8,
		buttonName = "4v4",
	},
	["Deathmatch"] = {
		mode = "Deathmatch",
		teamSize = 8,
		playersRequired = 8,
		buttonName = "Deathmatch",
		isDeathmatch = true,
		maxPlayers = 8,
	},
}

------------------//FUNCTIONS
function MatchmakingDictionary.get_mode(mode: string): ModeConfig?
	return MatchmakingDictionary.MODES[mode]
end

function MatchmakingDictionary.get_modes(): { ModeConfig }
	local modes: { ModeConfig } = {}

	for _, modeName: string in MatchmakingDictionary.MODE_ORDER do
		local modeConfig = MatchmakingDictionary.MODES[modeName]

		if modeConfig then
			table.insert(modes, modeConfig)
		end
	end

	return modes
end

function MatchmakingDictionary.get_player_key(userId: number): string
	return "player_" .. tostring(userId)
end

function MatchmakingDictionary.get_match_queue_name(mode: string): string
	return MatchmakingDictionary.MATCH_QUEUE_PREFIX .. mode
end

function MatchmakingDictionary.get_assignment_queue_name(sourceJobId: string): string
	return MatchmakingDictionary.ASSIGNMENT_QUEUE_PREFIX .. sourceJobId
end

return MatchmakingDictionary

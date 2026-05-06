------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//VARIABLES
local replicatedModules: Folder = ReplicatedStorage:WaitForChild("Modules") :: Folder
local gameModules: Folder = replicatedModules:WaitForChild("Game") :: Folder
local GameConfig = require(gameModules:WaitForChild("GameConfig") :: ModuleScript)

local PlayerDataTemplate = {}

export type PlayerData = {
	world: string,
	level: number,
	exp: number,
	dataVersion: number,
	stats: {hp: number, atk: number, def: number, spd: number, luck: number},
	abilitiesUnlocked: {string},
	abilitiesEquipped: {string},
	moralPath: string?,
	storyQuests: {string},
	loreLogs: {string}, 
	rivalStage: number,
	titles: {string},
	activeTitle: string,
	pinnedTitles: {string},
	jjk: {curseEnergy: number}?,
	naruto: {affinity: string, clan: string}?,
	rebirthCount: number,
	peakImmortalityPct: number,
	lastLogin: number,
	loginStreak: number,
	dailyQuestsDone: {string},
	rebirthShards: number,
	worldSouls: number,
	divineTokens: number,
	training: {focus: number, totalTaps: number, burstEndsAt: number},
	resources: {stamina: number, food: number, knowledge: number},
	progress: {battleWins: number, pvpWins: number, questsCompleted: number, playtimeSeconds: number},
	inventory: {items: {string}, equipped: {[string]: string}},
	settings: {abbreviations: boolean, hardMode: boolean, autoBreakthrough: boolean},
}

local TEMPLATE: PlayerData = {
	world = "",
	level = 1,
	exp = 0,
	dataVersion = GameConfig.DATA_VERSION,
	stats = {
		hp = 100,
		atk = 10,
		def = 5,
		spd = 5,
		luck = 1,
	},
	abilitiesUnlocked = {},
	abilitiesEquipped = {},
	moralPath = nil,
	storyQuests = {},
	loreLogs = {},
	rivalStage = 0,
	titles = {
		"Chosen",
	},
	activeTitle = "Chosen",
	pinnedTitles = {},
	jjk = nil,
	naruto = nil,
	rebirthCount = 0,
	peakImmortalityPct = 0,
	lastLogin = 0,
	loginStreak = 0,
	dailyQuestsDone = {},
	rebirthShards = 0,
	worldSouls = 0,
	divineTokens = 0,
	training = {
		focus = 0,
		totalTaps = 0,
		burstEndsAt = 0,
	},
	resources = {
		stamina = 4,
		food = 3,
		knowledge = 10,
	},
	progress = {
		battleWins = 0,
		pvpWins = 0,
		questsCompleted = 0,
		playtimeSeconds = 0,
		questProgress = {},
		claimedQuests = {},
	},
	inventory = {
		items = {
			"Training Wraps",
			"Plain Uniform",
		},
		equipped = {
			head = "",
			neck = "",
			shirt = "Plain Uniform",
			pants = "",
			weapon = "Training Wraps",
		},
	},
	settings = {
		abbreviations = false,
		hardMode = false,
		autoBreakthrough = false,
	},
}

------------------//FUNCTIONS
local function copy_table(source: any): any
	if typeof(source) ~= "table" then
		return source
	end

	local copy = {}
	for key, value in source do
		copy[key] = copy_table(value)
	end
	return copy
end

local function merge_defaults(source: any, defaults: any): any
	if typeof(defaults) ~= "table" then
		if source == nil then
			return defaults
		end
		return source
	end

	local merged = copy_table(defaults)
	if typeof(source) ~= "table" then
		return merged
	end

	for key, value in source do
		if typeof(value) == "table" and typeof(merged[key]) == "table" then
			merged[key] = merge_defaults(value, merged[key])
		else
			merged[key] = value
		end
	end

	return merged
end

function PlayerDataTemplate.create(): PlayerData
	return copy_table(TEMPLATE)
end

function PlayerDataTemplate.merge(data: any): PlayerData
	local merged = merge_defaults(data, TEMPLATE)
	merged.dataVersion = GameConfig.DATA_VERSION
	return merged
end

function PlayerDataTemplate.copy(data: PlayerData): PlayerData
	return copy_table(data)
end

------------------//INIT
return PlayerDataTemplate

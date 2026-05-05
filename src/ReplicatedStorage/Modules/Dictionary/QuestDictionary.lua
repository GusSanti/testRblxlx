------------------//VARIABLES
local QuestDictionary = {}

export type QuestDefinition = {
	id: string,
	displayName: string,
	questType: string,
	rewardExp: number,
	rewardSouls: number,
	staminaChange: number,
	foodChange: number,
	knowledgeChange: number,
	repeatable: boolean,
}

QuestDictionary.items = {
	LookAround = {
		id = "LookAround",
		displayName = "Look Around",
		questType = "Story",
		rewardExp = 25,
		rewardSouls = 0,
		staminaChange = 0,
		foodChange = 0,
		knowledgeChange = 1,
		repeatable = false,
	},
	CryLoudly = {
		id = "CryLoudly",
		displayName = "Cry Loudly",
		questType = "Repeatable",
		rewardExp = 8,
		rewardSouls = 1,
		staminaChange = -1,
		foodChange = 0,
		knowledgeChange = 0,
		repeatable = true,
	},
	Sleep = {
		id = "Sleep",
		displayName = "Sleep",
		questType = "Repeatable",
		rewardExp = 4,
		rewardSouls = 0,
		staminaChange = 3,
		foodChange = 1,
		knowledgeChange = 0,
		repeatable = true,
	},
	WiggleAround = {
		id = "WiggleAround",
		displayName = "Wiggle Around",
		questType = "Repeatable",
		rewardExp = 12,
		rewardSouls = 1,
		staminaChange = -1,
		foodChange = -1,
		knowledgeChange = 1,
		repeatable = true,
	},
}

QuestDictionary.order = {
	"LookAround",
	"CryLoudly",
	"Sleep",
	"WiggleAround",
}

------------------//FUNCTIONS
function QuestDictionary.get_quest(questId: string): QuestDefinition?
	return QuestDictionary.items[questId]
end

------------------//INIT
return QuestDictionary

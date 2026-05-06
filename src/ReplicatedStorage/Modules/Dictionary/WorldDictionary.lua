------------------//VARIABLES
local WorldDictionary = {}

export type WorldDefinition = {
	id: string,
	displayName: string,
	shortName: string,
	active: boolean,
	difficulty: string,
	startingClass: string,
	powerSystem: string,
	vibe: string,
	statusText: string,
	themeColor: Color3,
	darkColor: Color3,
	trainingObject: string,
	mechanicName: string,
}

WorldDictionary.order = {
	"JJK",
	"Naruto",
}

WorldDictionary.items = {
	JJK = {
		id = "JJK",
		displayName = "Jujutsu",
		shortName = "JJK",
		active = true,
		difficulty = "Hard",
		startingClass = "Sorcerer Trainee",
		powerSystem = "Cursed Energy + Techniques",
		vibe = "Dark cursed spirit grind",
		statusText = "Playable Foundation",
		themeColor = Color3.fromRGB(124, 72, 214),
		darkColor = Color3.fromRGB(34, 25, 50),
		trainingObject = "Cursed Dummy",
		mechanicName = "Cursed Energy",
	},
	Naruto = {
		id = "Naruto",
		displayName = "Naruto",
		shortName = "Naruto",
		active = false,
		difficulty = "Normal",
		startingClass = "Academy Genin",
		powerSystem = "Chakra + Jutsu + Clans",
		vibe = "Ninja village progression",
		statusText = "Foundation Slot",
		themeColor = Color3.fromRGB(42, 132, 230),
		darkColor = Color3.fromRGB(18, 42, 74),
		trainingObject = "Wooden Post",
		mechanicName = "Chakra",
	},
}

------------------//FUNCTIONS
function WorldDictionary.get_world(worldId: string): WorldDefinition?
	return WorldDictionary.items[worldId]
end

function WorldDictionary.is_world_active(worldId: string): boolean
	local world = WorldDictionary.get_world(worldId)
	return world ~= nil and world.active == true
end

function WorldDictionary.get_ordered_worlds(): {WorldDefinition}
	local worlds = {}
	for _, worldId in WorldDictionary.order do
		local world = WorldDictionary.get_world(worldId)
		if world then
			table.insert(worlds, world)
		end
	end
	return worlds
end

------------------//INIT
return WorldDictionary

------------------//VARIABLES
local AbilityDictionary = {}

export type AbilityDefinition = {
	id: string,
	displayName: string,
	worldId: string,
	unlockLevel: number,
	cooldown: number,
	cost: number,
	multiplier: number,
	abilityType: string,
	startingAbility: boolean,
}

AbilityDictionary.items = {
	JJK = {
		{
			id = "CursedStrike",
			displayName = "Cursed Strike",
			worldId = "JJK",
			unlockLevel = 1,
			cooldown = 2,
			cost = 0,
			multiplier = 1.1,
			abilityType = "Active",
			startingAbility = true,
		},
		{
			id = "CursedEnergySurge",
			displayName = "Cursed Energy Surge",
			worldId = "JJK",
			unlockLevel = 10,
			cooldown = 15,
			cost = 25,
			multiplier = 1.35,
			abilityType = "Active",
			startingAbility = false,
		},
	},
	Naruto = {
		{
			id = "BasicKunai",
			displayName = "Basic Kunai",
			worldId = "Naruto",
			unlockLevel = 1,
			cooldown = 2,
			cost = 0,
			multiplier = 1,
			abilityType = "Active",
			startingAbility = true,
		},
	},
}

------------------//FUNCTIONS
function AbilityDictionary.get_world_abilities(worldId: string): {AbilityDefinition}
	return AbilityDictionary.items[worldId] or {}
end

function AbilityDictionary.get_starting_abilities(worldId: string): {string}
	local abilities = AbilityDictionary.get_world_abilities(worldId)
	local startingAbilities = {}

	for _, ability in abilities do
		if ability.startingAbility then
			table.insert(startingAbilities, ability.id)
		end
	end

	return startingAbilities
end

function AbilityDictionary.get_default_equipped(worldId: string): {string}
	local startingAbilities = AbilityDictionary.get_starting_abilities(worldId)
	local equippedAbilities = {}

	for _, abilityId in startingAbilities do
		if #equippedAbilities < 3 then
			table.insert(equippedAbilities, abilityId)
		end
	end

	return equippedAbilities
end

------------------//INIT
return AbilityDictionary

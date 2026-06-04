------------------//CONSTANTS
local ItemsDataDictionary = {}

export type WeaponRarity = "Common" | "Rare" | "Epic" | "Legendary"

export type WeaponConfig = {
	name: string,
	displayName: string,
	price: number,
	rarity: WeaponRarity,
}

local WEAPON_LIST: { WeaponConfig } = {
	{
		name = "OldPistol",
		displayName = "Old Pistol",
		price = 0,
		rarity = "Common",
	},
	{
		name = "Luger",
		displayName = "Luger",
		price = 280,
		rarity = "Common",
	},
	{
		name = "GlockEXT",
		displayName = "Glock EXT",
		price = 420,
		rarity = "Common",
	},
	{
		name = "SMG",
		displayName = "SMG",
		price = 700,
		rarity = "Rare",
	},
	{
		name = "MAC-10",
		displayName = "MAC-10",
		price = 820,
		rarity = "Rare",
	},
	{
		name = "MAC-11",
		displayName = "MAC-11",
		price = 900,
		rarity = "Rare",
	},
	{
		name = "Uzi",
		displayName = "Uzi",
		price = 980,
		rarity = "Rare",
	},
	{
		name = "Tommy",
		displayName = "Tommy Gun",
		price = 1300,
		rarity = "Epic",
	},
	{
		name = "P90",
		displayName = "P90",
		price = 1550,
		rarity = "Epic",
	},
	{
		name = "DRACO",
		displayName = "Draco",
		price = 1750,
		rarity = "Epic",
	},
	{
		name = "Ak47",
		displayName = "AK-47",
		price = 1950,
		rarity = "Epic",
	},
	{
		name = "M4A1",
		displayName = "M4A1",
		price = 2400,
		rarity = "Legendary",
	},
	{
		name = "GoldenDeagle",
		displayName = "Golden Deagle",
		price = 3200,
		rarity = "Legendary",
	},
}

local WEAPON_MAP: { [string]: WeaponConfig } = {}
local RARITY_ORDER: { WeaponRarity } = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
}

local RARITY_RANK: { [WeaponRarity]: number } = {
	Common = 1,
	Rare = 2,
	Epic = 3,
	Legendary = 4,
}

for _, weaponConfig in WEAPON_LIST do
	WEAPON_MAP[weaponConfig.name] = weaponConfig
end

ItemsDataDictionary.DEFAULT_WEAPON = "OldPistol"

------------------//FUNCTIONS
function ItemsDataDictionary.get_weapon_list(): { WeaponConfig }
	return table.clone(WEAPON_LIST)
end

function ItemsDataDictionary.get_weapon_names(): { string }
	local names: { string } = {}

	for _, weaponConfig in WEAPON_LIST do
		table.insert(names, weaponConfig.name)
	end

	return names
end

function ItemsDataDictionary.get_rarity_order(): { WeaponRarity }
	return table.clone(RARITY_ORDER)
end

function ItemsDataDictionary.get_weapon_config(weaponName: string): WeaponConfig?
	return WEAPON_MAP[weaponName]
end

function ItemsDataDictionary.get_weapon_price(weaponName: string): number
	local weaponConfig = WEAPON_MAP[weaponName]

	if not weaponConfig then
		return 0
	end

	return math.max(0, math.floor(weaponConfig.price))
end

function ItemsDataDictionary.get_weapon_rarity(weaponName: string): WeaponRarity
	local weaponConfig = WEAPON_MAP[weaponName]

	if not weaponConfig then
		return "Common"
	end

	return weaponConfig.rarity
end

function ItemsDataDictionary.get_weapon_rarity_rank(weaponName: string): number
	local rarity = ItemsDataDictionary.get_weapon_rarity(weaponName)
	local rank = RARITY_RANK[rarity]

	if not rank then
		return 1
	end

	return rank
end

function ItemsDataDictionary.get_weapons_sorted_by_rarity(): { WeaponConfig }
	local sorted = table.clone(WEAPON_LIST)

	table.sort(sorted, function(a: WeaponConfig, b: WeaponConfig): boolean
		local rankA = RARITY_RANK[a.rarity] or 1
		local rankB = RARITY_RANK[b.rarity] or 1

		if rankA ~= rankB then
			return rankA < rankB
		end

		if a.price ~= b.price then
			return a.price < b.price
		end

		return a.name < b.name
	end)

	return sorted
end

function ItemsDataDictionary.is_valid_weapon(weaponName: string): boolean
	return WEAPON_MAP[weaponName] ~= nil
end

return ItemsDataDictionary

------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local ItemsDataDictionary = {}

local assetsFolder: Folder = ReplicatedStorage:WaitForChild("Assets") :: Folder

export type WeaponRarity = "Common" | "Rare" | "Epic" | "Legendary"

export type WeaponConfig = {
	name: string,
	displayName: string,
	model: string,
	price: number,
	rarity: WeaponRarity,
	description: string,
}

local WEAPON_LIST: { WeaponConfig } = {
	{
		name = "G17",
		displayName = "G17",
		model = "Weapons.G17",
		price = 0,
		rarity = "Common",
		description = "A reliable starter pistol with balanced recoil and clean all-round handling.",
	},
	{
		name = "G19ST",
		displayName = "G19ST",
		model = "Weapons.G19ST",
		price = 260,
		rarity = "Common",
		description = "A lightweight striker-fired sidearm that stays composed in fast close-range duels.",
	},
	{
		name = "P7K3",
		displayName = "P7K3",
		model = "Weapons.P7K3",
		price = 320,
		rarity = "Common",
		description = "A low-profile pistol built for quick reactions and tight indoor fights.",
	},
	{
		name = "Hellcat",
		displayName = "Hellcat",
		model = "Weapons.Hellcat",
		price = 380,
		rarity = "Common",
		description = "A slim carry pistol that rewards speed, confidence, and smart positioning.",
	},
	{
		name = "HKUSP",
		displayName = "HK USP",
		model = "Weapons.HKUSP",
		price = 450,
		rarity = "Common",
		description = "A tactical sidearm with dependable control and crisp follow-up shots.",
	},
	{
		name = "KTP11",
		displayName = "KTP-11",
		model = "Weapons.KTP11",
		price = 520,
		rarity = "Common",
		description = "A straightforward service pistol with predictable recoil and steady performance.",
	},
	{
		name = "LCP",
		displayName = "LCP",
		model = "Weapons.LCP",
		price = 580,
		rarity = "Common",
		description = "An ultra-compact backup pistol made for panic moments and fast draws.",
	},
	{
		name = "19XSwitch",
		displayName = "19X Switch",
		model = "Weapons.19XSwitch",
		price = 680,
		rarity = "Rare",
		description = "A modern hybrid sidearm with smooth recoil and confident repeat accuracy.",
	},
	{
		name = "22",
		displayName = ".22",
		model = "Weapons.22",
		price = 730,
		rarity = "Rare",
		description = "A low-recoil pocket pistol that favors precision and patient shot placement.",
	},
	{
		name = "38SP",
		displayName = ".38 Special",
		model = "Weapons.38SP",
		price = 790,
		rarity = "Rare",
		description = "A classic revolver with simple handling and a dependable close-range punch.",
	},
	{
		name = "Cougar",
		displayName = "Cougar",
		model = "Weapons.Cougar",
		price = 860,
		rarity = "Rare",
		description = "A balanced sidearm with a solid feel, calm recoil, and versatile pacing.",
	},
	{
		name = "PD19x",
		displayName = "PD19X",
		model = "Weapons.PD19x",
		price = 920,
		rarity = "Rare",
		description = "A tactical crossover pistol that feels stable when fights get fast and messy.",
	},
	{
		name = "STAR45",
		displayName = "STAR .45",
		model = "Weapons.STAR45",
		price = 980,
		rarity = "Rare",
		description = "A heavier .45 sidearm with a grounded feel and stronger per-shot impact.",
	},
	{
		name = "G20",
		displayName = "G20",
		model = "Weapons.G20",
		price = 1040,
		rarity = "Rare",
		description = "A powerful full-size pistol that trades comfort for extra stopping force.",
	},
	{
		name = "G29",
		displayName = "G29",
		model = "Weapons.G29",
		price = 1110,
		rarity = "Rare",
		description = "A compact heavy-caliber pistol that delivers sharp damage in a smaller frame.",
	},
	{
		name = "LCR",
		displayName = "LCR",
		model = "Weapons.LCR",
		price = 1180,
		rarity = "Rare",
		description = "A light carry revolver built for fast presentation and snap decision shots.",
	},
	{
		name = "357Magnum",
		displayName = ".357 Magnum",
		model = "Weapons.357Magnum",
		price = 1320,
		rarity = "Epic",
		description = "A high-impact revolver with punishing shots and a fearsome presence.",
	},
	{
		name = "DFR",
		displayName = "DFR",
		model = "Weapons.DFR",
		price = 1480,
		rarity = "Epic",
		description = "A compact automatic weapon tuned for quick pushes and relentless pressure.",
	},
	{
		name = "MK422",
		displayName = "MK422",
		model = "Weapons.MK422",
		price = 1660,
		rarity = "Epic",
		description = "A fast-firing compact SMG that tracks moving targets with constant pressure.",
	},
	{
		name = "M1900",
		displayName = "M1900",
		model = "Weapons.M1900",
		price = 1820,
		rarity = "Epic",
		description = "An old-school sidearm with elegant lines and a deliberate, rewarding tempo.",
	},
	{
		name = "ARP",
		displayName = "ARP",
		model = "Weapons.ARP",
		price = 1980,
		rarity = "Epic",
		description = "A fast-handling rifle platform that thrives in aggressive mid-range engagements.",
	},
	{
		name = "Mossberg590",
		displayName = "Mossberg 590",
		model = "Weapons.Mossberg590",
		price = 2140,
		rarity = "Epic",
		description = "A pump shotgun with brutal stopping power and dominant close-quarters control.",
	},
	{
		name = "Taser",
		displayName = "Taser",
		model = "Weapons.Taser",
		price = 2260,
		rarity = "Epic",
		description = "A utility weapon for surprise control plays and close-range disruption.",
	},
	{
		name = "AA12",
		displayName = "AA-12",
		model = "Weapons.AA12",
		price = 2380,
		rarity = "Epic",
		description = "A full-auto shotgun that floods tight spaces with overwhelming force.",
	},
	{
		name = "DE",
		displayName = "Desert Eagle",
		model = "Weapons.DE",
		price = 2620,
		rarity = "Legendary",
		description = "A massive hand cannon that rewards discipline with brutal single-shot power.",
	},
	{
		name = "G34",
		displayName = "G34",
		model = "Weapons.G34",
		price = 2860,
		rarity = "Legendary",
		description = "A long-slide competition pistol built for premium precision and cleaner recoil control.",
	},
	{
		name = "Draco",
		displayName = "Draco",
		model = "Weapons.Draco",
		price = 3340,
		rarity = "Legendary",
		description = "A compact rifle-caliber monster with explosive pressure at close to mid range.",
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

ItemsDataDictionary.DEFAULT_WEAPON = "G17"

------------------//FUNCTIONS
local function split_path(path: string): { string }
	local pieces: { string } = {}

	for token in string.gmatch(path, "[^%.]+") do
		table.insert(pieces, token)
	end

	return pieces
end

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

function ItemsDataDictionary.get_weapon_model_path(weaponName: string): string?
	local weaponConfig = WEAPON_MAP[weaponName]

	if not weaponConfig then
		return nil
	end

	return weaponConfig.model
end

function ItemsDataDictionary.get_weapon_model(weaponName: string): Instance?
	local modelPath = ItemsDataDictionary.get_weapon_model_path(weaponName)

	if not modelPath or modelPath == "" then
		return nil
	end

	local current: Instance? = assetsFolder

	for _, token in split_path(modelPath) do
		if not current then
			return nil
		end

		current = current:FindFirstChild(token)
	end

	return current
end

function ItemsDataDictionary.get_weapon_price(weaponName: string): number
	local weaponConfig = WEAPON_MAP[weaponName]

	if not weaponConfig then
		return 0
	end

	return math.max(0, math.floor(weaponConfig.price))
end

function ItemsDataDictionary.get_weapon_description(weaponName: string): string
	local weaponConfig = WEAPON_MAP[weaponName]

	if not weaponConfig then
		return "Description coming soon."
	end

	return weaponConfig.description
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

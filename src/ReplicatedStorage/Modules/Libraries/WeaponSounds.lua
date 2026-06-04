local WeaponSettings = require(script.Parent:WaitForChild("WeaponSettings"))

local WeaponSounds = {}

WeaponSounds.Default = {
	-- Preencha os Ids abaixo com os seus assets.
	-- Enquanto Id for 0, o sistema tenta usar sons legados dentro da Tool (se existirem).
	Equip = {
		Id = 0,
		Volume = 0.8,
		PlaybackSpeed = 1,
		MaxDistance = 70,
	},
	Fire = {
		Id = 0,
		Volume = 1,
		PlaybackSpeed = 1,
		MaxDistance = 120,
	},
	Reload = {
		Id = 0,
		Volume = 0.9,
		PlaybackSpeed = 1,
		MaxDistance = 90,
	},
	Empty = {
		Id = 0,
		Volume = 0.9,
		PlaybackSpeed = 1,
		MaxDistance = 75,
	},
}

WeaponSounds.Weapons = {
	v_19XSwitch = {},
	v_22 = {},
	v_357Magnum = {},
	v_38SP = {},
	v_AA12 = {},
	v_ARP = {},
	v_CDracoModel = {},
	v_Cougar = {},
	v_DE = {},
	v_DFR = {},
	v_G17 = {},
	v_G19ST = {},
	v_G20 = {},
	v_G29 = {},
	v_G34 = {},
	v_HKUSP = {},
	v_Hellcat = {},
	v_Judge = {},
	v_KTP11 = {},
	v_LCP = {},
	v_LCR = {},
	v_M1900 = {},
	v_MK422 = {},
	v_Mossberg590 = {},
	v_P7K3 = {},
	v_PD19x = {},
	v_STAR45 = {},
	v_Taser = {},
}

local mergedProfiles = {}

local function deepClone(value)
	if type(value) ~= "table" then
		return value
	end

	local out = {}
	for k, v in pairs(value) do
		out[k] = deepClone(v)
	end
	return out
end

local function deepMerge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then
			deepMerge(dst[k], v)
		else
			dst[k] = deepClone(v)
		end
	end
end

local function getMergedProfile(weaponKey)
	if not mergedProfiles[weaponKey] then
		local profile = deepClone(WeaponSounds.Default)
		local overrides = WeaponSounds.Weapons[weaponKey]
		if type(overrides) == "table" then
			deepMerge(profile, overrides)
		end
		mergedProfiles[weaponKey] = profile
	end

	return mergedProfiles[weaponKey]
end

function WeaponSounds.GetProfile(identifier)
	local weaponKey = WeaponSettings.ResolveWeaponKey(identifier)
	if not weaponKey then
		return WeaponSounds.Default, nil
	end

	return getMergedProfile(weaponKey), weaponKey
end

return WeaponSounds

local WeaponSettings = {}

WeaponSettings.Global = {
	-- Camera agora fica global porque todas as armas usam os mesmos valores.
	AimWalkSpeedMultiplier = 0.72,
	Camera = {
		LockedOffset = Vector3.new(2.1, 0.85, 0),
		AimedOffset = Vector3.new(1.25, 0.72, 0),
		DefaultFov = 70,
		AimedFov = 56,
		OffsetTweenTime = 0.12,
		FovTweenTime = 0.1,
		ShoulderSwapLerpSpeed = 18,
		BodyTurnLerpSpeed = 30,
	},
}

WeaponSettings.Default = {
	FireMode = "Semi",
	RoundsPerMinute = 420,
	Range = 550,
	MagSize = 18,
	ReserveAmmo = 90,
	ReloadTime = 1.55,
	ShotCooldown = nil,
	PerfectAccuracy = true,
	AnimationProfile = "2hand",
	Spread = {
		Default = 1.2,
		Free = 1.2,
		Locked = 0.55,
		Aimed = 0.35,
	},
	Damage = {
		Base = 24,
		Head = 2.2,
		Torso = 1.0,
		Arm = 0.75,
		Leg = 0.65,
	},
	Recoil = {
		Pitch = 1.1,
		Yaw = 0.35,
	},
	Attachments = {
		Muzzle = "Muzzle",
	},
}

WeaponSettings.Aliases = {
	["19XSwitch"] = "v_19XSwitch",
	["22"] = "v_22",
	["357Magnum"] = "v_357Magnum",
	["38SP"] = "v_38SP",
	["AA12"] = "v_AA12",
	["ARP"] = "v_ARP",
	["CDracoModel"] = "v_CDracoModel",
	["DRACO"] = "v_CDracoModel",
	["Draco"] = "v_CDracoModel",
	["Cougar"] = "v_Cougar",
	["DE"] = "v_DE",
	["DFR"] = "v_DFR",
	["G17"] = "v_G17",
	["G19ST"] = "v_G19ST",
	["G20"] = "v_G20",
	["G29"] = "v_G29",
	["G34"] = "v_G34",
	["HKUSP"] = "v_HKUSP",
	["Hellcat"] = "v_Hellcat",
	["Judge"] = "v_Judge",
	["KTP11"] = "v_KTP11",
	["LCP"] = "v_LCP",
	["LCR"] = "v_LCR",
	["M1900"] = "v_M1900",
	["MK422"] = "v_MK422",
	["Mossberg590"] = "v_Mossberg590",
	["P7K3"] = "v_P7K3",
	["PD19x"] = "v_PD19x",
	["STAR45"] = "v_STAR45",
	["Taser"] = "v_Taser",
}

WeaponSettings.Weapons = {
	-- Coloque overrides por arma aqui (Damage, Recoil, Range, etc).
	-- Exemplo:
	-- v_38SP = { Damage = { Base = 28 }, Recoil = { Pitch = 1.2, Yaw = 0.4 } },
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

local mergedCache = {}
local normalizedToKey = {}

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

local function normalizeKey(value)
	if value == nil then
		return nil
	end

	local s = string.lower(tostring(value))
	s = string.gsub(s, "[^%w]", "")
	if s == "" then
		return nil
	end
	return s
end

local function registerNormalized(rawKey, canonicalKey)
	local normalized = normalizeKey(rawKey)
	if normalized then
		normalizedToKey[normalized] = canonicalKey
	end
end

for weaponKey in pairs(WeaponSettings.Weapons) do
	registerNormalized(weaponKey, weaponKey)
end

for alias, target in pairs(WeaponSettings.Aliases) do
	local directTarget = WeaponSettings.Weapons[target] and target or nil
	local normalizedTarget = normalizedToKey[normalizeKey(target)]
	local canonicalTarget = directTarget or normalizedTarget
	if canonicalTarget then
		registerNormalized(alias, canonicalTarget)
	end
end

local function pushCandidate(candidates, seen, rawCandidate)
	local normalized = normalizeKey(rawCandidate)
	if not normalized or seen[normalized] then
		return
	end
	seen[normalized] = true
	table.insert(candidates, normalized)
end

local function buildCandidates(identifier)
	local raw = tostring(identifier)
	local normalized = normalizeKey(raw)
	if not normalized then
		return {}
	end

	local candidates = {}
	local seen = {}

	pushCandidate(candidates, seen, raw)
	pushCandidate(candidates, seen, "v_" .. raw)

	if string.sub(normalized, 1, 1) == "v" then
		pushCandidate(candidates, seen, string.sub(normalized, 2))
	end

	if string.sub(normalized, 1, 6) == "weapon" then
		pushCandidate(candidates, seen, string.sub(normalized, 7))
	end

	return candidates
end

local function uniqueSubstringMatch(candidates)
	for _, candidate in ipairs(candidates) do
		local foundKey = nil
		for weaponKey in pairs(WeaponSettings.Weapons) do
			local normalizedWeaponKey = normalizeKey(weaponKey)
			if normalizedWeaponKey and string.find(normalizedWeaponKey, candidate, 1, true) then
				if foundKey and foundKey ~= weaponKey then
					foundKey = nil
					break
				end
				foundKey = weaponKey
			end
		end

		if foundKey then
			return foundKey
		end
	end

	return nil
end

function WeaponSettings.ResolveWeaponKey(identifier)
	if identifier == nil then
		return nil
	end

	if WeaponSettings.Weapons[identifier] then
		return identifier
	end

	local candidates = buildCandidates(identifier)
	for _, candidate in ipairs(candidates) do
		local mapped = normalizedToKey[candidate]
		if mapped then
			return mapped
		end
	end

	return uniqueSubstringMatch(candidates)
end

function WeaponSettings.ResolveTool(tool)
	if not tool or not tool:IsA("Tool") then
		return nil
	end

	local attrWeaponId = tool:GetAttribute("WeaponId")
	local attrWeaponKey = tool:GetAttribute("WeaponKey")
	local stringValueWeaponId = tool:FindFirstChild("WeaponId")
	local stringValueWeaponKey = tool:FindFirstChild("WeaponKey")

	local candidates = {
		attrWeaponKey,
		attrWeaponId,
		(stringValueWeaponKey and stringValueWeaponKey:IsA("StringValue") and stringValueWeaponKey.Value) or nil,
		(stringValueWeaponId and stringValueWeaponId:IsA("StringValue") and stringValueWeaponId.Value) or nil,
		tool.Name,
	}

	for _, candidate in ipairs(candidates) do
		local resolved = WeaponSettings.ResolveWeaponKey(candidate)
		if resolved then
			return resolved
		end
	end

	return nil
end

local function buildMergedConfig(weaponKey)
	local cfg = deepClone(WeaponSettings.Default)
	local weaponCfg = WeaponSettings.Weapons[weaponKey]

	if type(weaponCfg) == "table" then
		deepMerge(cfg, weaponCfg)
	end

	return cfg
end

function WeaponSettings.GetResolvedConfig(identifier)
	local weaponKey = WeaponSettings.ResolveWeaponKey(identifier)
	if not weaponKey then
		return nil, nil
	end

	if not mergedCache[weaponKey] then
		mergedCache[weaponKey] = buildMergedConfig(weaponKey)
	end

	return mergedCache[weaponKey], weaponKey
end

function WeaponSettings.GetConfigForTool(tool)
	local weaponKey = WeaponSettings.ResolveTool(tool)
	if not weaponKey then
		return nil, nil
	end

	return WeaponSettings.GetResolvedConfig(weaponKey)
end

function WeaponSettings.IsWeaponConfigured(identifier)
	return WeaponSettings.ResolveWeaponKey(identifier) ~= nil
end

return WeaponSettings

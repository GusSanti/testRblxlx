local BodyDamage = {}

local PART_GROUP = {
	Head = "Head",
	Torso = "Torso",
	UpperTorso = "Torso",
	LowerTorso = "Torso",

	["Left Arm"] = "Arm",
	["Right Arm"] = "Arm",
	LeftUpperArm = "Arm",
	LeftLowerArm = "Arm",
	LeftHand = "Arm",
	RightUpperArm = "Arm",
	RightLowerArm = "Arm",
	RightHand = "Arm",

	["Left Leg"] = "Leg",
	["Right Leg"] = "Leg",
	LeftUpperLeg = "Leg",
	LeftLowerLeg = "Leg",
	LeftFoot = "Leg",
	RightUpperLeg = "Leg",
	RightLowerLeg = "Leg",
	RightFoot = "Leg",
}

local DEFAULT_MULTIPLIER = {
	Head = 2.0,
	Torso = 1.0,
	Arm = 0.75,
	Leg = 0.65,
}

function BodyDamage.GetGroup(hitPart, humanoid)
	if not hitPart then
		return "Torso"
	end

	local group = PART_GROUP[hitPart.Name]
	if group then
		return group
	end

	if humanoid then
		local ok, limb = pcall(function()
			return humanoid:GetLimb(hitPart)
		end)

		if ok then
			if limb == Enum.Limb.Head then
				return "Head"
			elseif limb == Enum.Limb.Torso then
				return "Torso"
			elseif limb == Enum.Limb.LeftArm or limb == Enum.Limb.RightArm then
				return "Arm"
			elseif limb == Enum.Limb.LeftLeg or limb == Enum.Limb.RightLeg then
				return "Leg"
			end
		end
	end

	return "Torso"
end

function BodyDamage.GetMultiplier(group, damageConfig)
	if damageConfig and typeof(damageConfig[group]) == "number" then
		return damageConfig[group]
	end
	return DEFAULT_MULTIPLIER[group] or 1
end

return BodyDamage
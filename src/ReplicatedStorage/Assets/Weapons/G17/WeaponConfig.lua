-- WeaponConfig.lua
return {
	WeaponId = "G17",
	FireMode = "Semi",
	RoundsPerMinute = 420,
	Range = 550,
	MagSize = 18,
	ReserveAmmo = 90,
	ReloadTime = 1.55,
	Spread = {
		Default = 1.2,
		Free = 1.2,
		Locked = 0.55,
		Aimed = 0.35
	},
	Damage = {
		Base = 24,
		Head = 2.2,
		Torso = 1.0,
		Arm = 0.75,
		Leg = 0.65
	},
	Recoil = {
		Pitch = 1.1,
		Yaw = 0.35
	},
	Camera = {
		DefaultMode = "LOCKED",
		FreeOffset = Vector3.new(0, 0, 0),
		LockedOffset = Vector3.new(2.1, 0.85, 0),
		AimedOffset = Vector3.new(1.25, 0.72, 0),
		DefaultFov = 70,
		AimedFov = 56,
		AimWalkSpeedMultiplier = 0.72,
		OffsetTweenTime = 0.12,
		FovTweenTime = 0.1,
		ShoulderSwapLerpSpeed = 18,
		MaxFreeYawDeg = 70,
		NeckYawDeg = 24,
		WaistYawDeg = 16,
		NeckPitchDeg = 12,
		WaistPitchDeg = 8,
		FollowLerpSpeed = 10,
		ReturnLerpSpeed = 6
	},
	Attachments = {
		Muzzle = "Slider.Attachment"
	},
	Animations = {
		Equip = "Equip",
		Hold = "HoldDown",
		Recoil = "Recoil",
		Reload = "Reload"
	},
	UseEquipReverseAsUnequip = true
}
local ProfileTemplate = {
	------------------//CORE
	Coins = 0,
	Kills = 0,
	Deaths = 0,
	Wins = 0,
	Loses = 0,
	TimePlayed = 0,
	Level = 1,
	XP = 0,
	EquippedWeapon = "G17",
	WeaponsOwned = { "G17" },
	CurrentItems = {},
	DailyRewards = {
		StartDayStamp = 0,
		ClaimedDays = 0,
		LastClaimedAt = 0,
		AvailableDays = 0,
		ClaimableDays = 0,
		CurrentDayStamp = 0,
	},
}
return ProfileTemplate

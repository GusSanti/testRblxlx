------------------//CONSTANTS
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsDataDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("ItemsDataDictionary"))

local DailyRewardDictionary = {}

DailyRewardDictionary.REWARD_TYPES = {
	Coins = "Coins",
	Weapon = "Weapon",
}

export type RewardType = "Coins" | "Weapon"

export type DailyReward = {
	day: number,
	rewardType: RewardType,
	rewardName: string,
	amount: number,
	iconImage: string,
	weaponName: string?,
}

DailyRewardDictionary.TOTAL_DAYS = 7

local FINAL_WEAPON_NAME = "DFR"
local finalWeaponConfig = ItemsDataDictionary.get_weapon_config(FINAL_WEAPON_NAME)
local finalWeaponDisplayName = if finalWeaponConfig then finalWeaponConfig.displayName else FINAL_WEAPON_NAME

-- Cole o rbxassetid://... de cada recompensa no campo iconImage.
local REWARDS: { DailyReward } = {
	{
		day = 1,
		rewardType = DailyRewardDictionary.REWARD_TYPES.Coins,
		rewardName = "Coins",
		amount = 150,
		iconImage = "",
	},
	{
		day = 2,
		rewardType = DailyRewardDictionary.REWARD_TYPES.Coins,
		rewardName = "Coins",
		amount = 250,
		iconImage = "",
	},
	{
		day = 3,
		rewardType = DailyRewardDictionary.REWARD_TYPES.Coins,
		rewardName = "Coins",
		amount = 400,
		iconImage = "",
	},
	{
		day = 4,
		rewardType = DailyRewardDictionary.REWARD_TYPES.Coins,
		rewardName = "Coins",
		amount = 550,
		iconImage = "",
	},
	{
		day = 5,
		rewardType = DailyRewardDictionary.REWARD_TYPES.Coins,
		rewardName = "Coins",
		amount = 700,
		iconImage = "",
	},
	{
		day = 6,
		rewardType = DailyRewardDictionary.REWARD_TYPES.Coins,
		rewardName = "Coins",
		amount = 900,
		iconImage = "",
	},
	{
		day = 7,
		rewardType = DailyRewardDictionary.REWARD_TYPES.Weapon,
		rewardName = finalWeaponDisplayName,
		amount = 1,
		iconImage = "",
		weaponName = FINAL_WEAPON_NAME,
	},
}

local REWARD_BY_DAY: { [number]: DailyReward } = {}

for _, reward in REWARDS do
	REWARD_BY_DAY[reward.day] = reward
end

------------------//FUNCTIONS
local function normalize_image_id(value: any): string
	if type(value) == "number" then
		if value <= 0 then
			return ""
		end

		return "rbxassetid://" .. tostring(math.floor(value))
	end

	if type(value) ~= "string" then
		return ""
	end

	if value == "" then
		return ""
	end

	if string.match(value, "^rbxassetid://%d+$") then
		return value
	end

	local numeric = tonumber(value)
	if numeric and numeric > 0 then
		return "rbxassetid://" .. tostring(math.floor(numeric))
	end

	return value
end

local function clone_reward(reward: DailyReward): DailyReward
	return {
		day = reward.day,
		rewardType = reward.rewardType,
		rewardName = reward.rewardName,
		amount = reward.amount,
		iconImage = normalize_image_id(reward.iconImage),
		weaponName = reward.weaponName,
	}
end

function DailyRewardDictionary.get_rewards(): { DailyReward }
	local rewards: { DailyReward } = {}

	for _, reward in REWARDS do
		table.insert(rewards, clone_reward(reward))
	end

	return rewards
end

function DailyRewardDictionary.get_reward(day: number): DailyReward?
	local reward = REWARD_BY_DAY[day]

	if not reward then
		return nil
	end

	return clone_reward(reward)
end

function DailyRewardDictionary.get_amount_text(reward: DailyReward): string
	if reward.rewardType == DailyRewardDictionary.REWARD_TYPES.Weapon then
		if reward.amount == 1 then
			return "1 weapon"
		end

		return tostring(reward.amount) .. " weapons"
	end

	return tostring(reward.amount) .. " coins"
end

return DailyRewardDictionary

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BalanceConfig = require(ReplicatedStorage.BalanceConfig)
local FriendRewardsConfig = BalanceConfig.FriendRewards or {
	BonusMultiplier = 0.10,
	RequiredDamage = 1,
}

local module = {}

local function getContributionDamage(player)
	local rawDamage = player:GetAttribute("RawDamage")
	if typeof(rawDamage) == "number" then
		return rawDamage
	end

	local damageValue = player:FindFirstChild("Damage")
	if damageValue and typeof(damageValue.Value) == "number" then
		return damageValue.Value
	end

	return 0
end

local function hasFriendInServer(player)
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			local success, isFriend = pcall(function()
				return player:IsFriendsWith(otherPlayer.UserId)
			end)

			if success and isFriend then
				return true
			end
		end
	end

	return false
end

local function addNumericReward(rewards, rewardName, multiplier)
	local baseAmount = rewards[rewardName]
	if typeof(baseAmount) ~= "number" or baseAmount <= 0 then
		return 0
	end

	local bonusAmount = math.round(baseAmount * multiplier)
	if bonusAmount <= 0 then
		return 0
	end

	rewards[rewardName] = baseAmount + bonusAmount
	return bonusAmount
end

function module.Apply(player, rewards, rewardsAlreadyGranted)
	if type(rewards) ~= "table" then
		return false
	end

	local config = FriendRewardsConfig
	if getContributionDamage(player) < config.RequiredDamage then
		return false
	end

	if not hasFriendInServer(player) then
		return false
	end

	local bonus = {
		Multiplier = config.BonusMultiplier,
	}

	bonus.Gems = addNumericReward(rewards, "Gems", config.BonusMultiplier)
	bonus.PlayerXP = addNumericReward(rewards, "PlayerXP", config.BonusMultiplier)

	local playerExpBonus = addNumericReward(rewards, "PlayerExp", config.BonusMultiplier)
	if playerExpBonus > 0 then
		bonus.PlayerXP = (bonus.PlayerXP or 0) + playerExpBonus
	end

	if (bonus.Gems or 0) <= 0 and (bonus.PlayerXP or 0) <= 0 then
		return false
	end

	rewards.FriendBonus = bonus

	if rewardsAlreadyGranted then
		if bonus.Gems and bonus.Gems > 0 then
			player.Gems.Value += bonus.Gems
		end
		if bonus.PlayerXP and bonus.PlayerXP > 0 then
			player.PlayerExp.Value += bonus.PlayerXP
		end
	end

	return true
end

return module

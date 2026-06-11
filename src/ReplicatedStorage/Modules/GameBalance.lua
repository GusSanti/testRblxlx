local GameBalance = {}

-- Global playtest knobs for the main in-match balance loop.
GameBalance.TowerDamageMultiplier = 0.95
GameBalance.EnemyHealthMultiplier = 1.08
GameBalance.WaveRewardMultiplier = 1.12
GameBalance.EnemyKillMoneyMultiplier = 1
GameBalance.StartingMoneyMultiplier = 1

local function scaleNumber(value, multiplier, minimum)
	if typeof(value) ~= "number" then
		return minimum
	end

	return math.max(minimum, math.round(value * multiplier))
end

function GameBalance.ApplyTowerDamage(damage)
	return scaleNumber(damage, GameBalance.TowerDamageMultiplier, 0)
end

function GameBalance.ApplyEnemyHealth(health)
	return scaleNumber(health, GameBalance.EnemyHealthMultiplier, 1)
end

function GameBalance.ApplyWaveReward(reward)
	return scaleNumber(reward, GameBalance.WaveRewardMultiplier, 0)
end

function GameBalance.ApplyEnemyKillMoney(reward)
	return scaleNumber(reward, GameBalance.EnemyKillMoneyMultiplier, 0)
end

function GameBalance.ApplyStartingMoney(money)
	return scaleNumber(money, GameBalance.StartingMoneyMultiplier, 0)
end

return GameBalance

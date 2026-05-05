------------------//VARIABLES
local ExpFormula = {}

------------------//FUNCTIONS
function ExpFormula.get_required_exp(level: number): number
	return math.floor(100 + level * 25 + level ^ 1.5 * 8)
end

function ExpFormula.add_exp(level: number, exp: number, addedExp: number, levelCap: number): {level: number, exp: number, levelsGained: number}
	local nextLevel = level
	local nextExp = exp + addedExp
	local levelsGained = 0

	while nextLevel < levelCap do
		local requiredExp = ExpFormula.get_required_exp(nextLevel)
		if nextExp < requiredExp then
			break
		end

		nextExp -= requiredExp
		nextLevel += 1
		levelsGained += 1
	end

	if nextLevel >= levelCap then
		nextExp = 0
	end

	return {
		level = nextLevel,
		exp = nextExp,
		levelsGained = levelsGained,
	}
end

------------------//INIT
return ExpFormula

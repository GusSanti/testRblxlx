local WorldConfig = {}

local BASE_GRAVITY = 196.2

WorldConfig.WORLDS = {
	{
		id = 1,
		name = "Core World",
		theme = "Plains",
		gravityMult = 1.5,
		entryCFrame = CFrame.new(-28.017, 20.406, -499.372),
		requiredPogoPower = 0,
		requiredRebirths = 0,
		layers = {
			{ name = "Grass", coinMultiplier = 1.0, minBreakForce = 0, color = Color3.fromRGB(106, 189, 94), maxHeight = 415, minHeight = 0 },
			{ name = "Dirt", coinMultiplier = 1.2, minBreakForce = 150, color = Color3.fromRGB(129, 98, 62), maxHeight = 928, minHeight = 415 },
			{ name = "Stone", coinMultiplier = 1.5, minBreakForce = 250, color = Color3.fromRGB(163, 162, 165), maxHeight = 1587, minHeight = 928 },
			{ name = "Obsidian", coinMultiplier = 2.5, minBreakForce = 300, color = Color3.fromRGB(27, 42, 53), maxHeight = 99999, minHeight = 1587 },
		}
	},
	{
		id = 2,
		name = "Cloud Paradise",
		theme = "Sky",
		gravityMult = 3.00, 
		entryCFrame = CFrame.new(98095.406, 37.179, -212.693),
		requiredPogoPower = 450, 
		requiredRebirths = 0,
		layers = {
			{ name = "Cloud", coinMultiplier = 4.0, minBreakForce = 300, color = Color3.fromRGB(255, 255, 255), maxHeight = 1000, minHeight = 20 },
			{ name = "Glass", coinMultiplier = 5.5, minBreakForce = 450, color = Color3.fromRGB(205, 240, 255), maxHeight = 20, minHeight = -30 },
			{ name = "Ice", coinMultiplier = 7.0, minBreakForce = 600, color = Color3.fromRGB(159, 218, 255), maxHeight = -30, minHeight = -100 },
			{ name = "Diamond", coinMultiplier = 10.0, minBreakForce = 800, color = Color3.fromRGB(46, 204, 255), maxHeight = -100, minHeight = -99999 },
		}
	},
	{
		id = 3,
		name = "Frost Peaks",
		theme = "Snow",
		gravityMult = 7.50, 
		entryCFrame = CFrame.new(350280.125, 62.421, 1545.258),
		requiredPogoPower = 1200,
		requiredRebirths = 1,
		layers = {
			{ name = "Snow", coinMultiplier = 15.0, minBreakForce = 1200, color = Color3.fromRGB(230, 230, 230), maxHeight = 1000, minHeight = 40 },
			{ name = "Ice", coinMultiplier = 7.0, minBreakForce = 600, color = Color3.fromRGB(159, 218, 255), maxHeight = 40, minHeight = 0 },
			{ name = "Slate", coinMultiplier = 22.0, minBreakForce = 1600, color = Color3.fromRGB(60, 60, 60), maxHeight = 0, minHeight = -80 },
			{ name = "Neon", coinMultiplier = 35.0, minBreakForce = 2200, color = Color3.fromRGB(0, 255, 180), maxHeight = -80, minHeight = -99999 },
		}
	},
	{
		id = 4,
		name = "Jungle Rise",
		theme = "Jungle",
		gravityMult = 15.00,
		entryCFrame = CFrame.new(-119376.766, 7.532, -51.993),
		requiredPogoPower = 3500,
		requiredRebirths = 2,
		layers = {
			{ name = "Grass", coinMultiplier = 1.0, minBreakForce = 0, color = Color3.fromRGB(106, 189, 94), maxHeight = 1000, minHeight = 0 },
			{ name = "Mud", coinMultiplier = 50.0, minBreakForce = 3500, color = Color3.fromRGB(86, 66, 54), maxHeight = 0, minHeight = -50 },
			{ name = "Wood", coinMultiplier = 75.0, minBreakForce = 4500, color = Color3.fromRGB(105, 64, 40), maxHeight = -50, minHeight = -120 },
			{ name = "Gold", coinMultiplier = 120.0, minBreakForce = 6000, color = Color3.fromRGB(239, 184, 56), maxHeight = -120, minHeight = -99999 },
		}
	},
	{
		id = 5,
		name = "Volcanic Rift",
		theme = "Volcano",
		gravityMult = 30.00, 
		entryCFrame = CFrame.new(-224830.047, 37.364, 78.576),
		requiredPogoPower = 8500,
		requiredRebirths = 3,
		layers = {
			{ name = "Basalt", coinMultiplier = 200.0, minBreakForce = 8500, color = Color3.fromRGB(30, 30, 35), maxHeight = 1000, minHeight = 20 },
			{ name = "CrackedLava", coinMultiplier = 350.0, minBreakForce = 12000, color = Color3.fromRGB(255, 100, 0), maxHeight = 20, minHeight = -40 },
			{ name = "Magma", coinMultiplier = 600.0, minBreakForce = 18000, color = Color3.fromRGB(255, 50, 0), maxHeight = -40, minHeight = -100 },
			{ name = "Bedrock", coinMultiplier = 1000.0, minBreakForce = 30000, color = Color3.fromRGB(10, 10, 10), maxHeight = -100, minHeight = -99999 },
		}
	},
}

function WorldConfig.GetWorld(id: number)
	for _, w in WorldConfig.WORLDS do
		if w.id == id then return w end
	end
	return WorldConfig.WORLDS[1]
end

function WorldConfig.GetNextWorld(currentId: number)
	return WorldConfig.GetWorld(currentId + 1)
end

return WorldConfig
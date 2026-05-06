------------------//SERVICES
local Players: Players = game:GetService("Players")

------------------//CONSTANTS
local ROOT_PART_NAME: string = "HumanoidRootPart"

------------------//VARIABLES
local removableClasses: {[string]: boolean} = {
	Accessory = true,
	Shirt = true,
	Pants = true,
	ShirtGraphic = true,
	Decal = true,
	Texture = true,
	CharacterMesh = true,
	SurfaceAppearance = true,
}

------------------//FUNCTIONS
local function should_remove_instance(instance: Instance): boolean
	return removableClasses[instance.ClassName] == true
end

local function apply_transparency(instance: Instance): ()
	if instance:IsA("BasePart") then
		instance.Transparency = 1
		instance.CanCollide = false
		instance.CanTouch = false
		instance.CanQuery = false
	end
end

local function clean_instance(instance: Instance): ()
	if should_remove_instance(instance) then
		instance:Destroy()
		return
	end

	apply_transparency(instance)
end

local function setup_humanoid(humanoid: Humanoid): ()
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
end

local function anchor_root_part(character: Model): ()
	local rootPart = character:WaitForChild(ROOT_PART_NAME, 10)
	if rootPart and rootPart:IsA("BasePart") then
		rootPart.Anchored = true
		rootPart.Transparency = 1
		rootPart.CanCollide = false
		rootPart.CanTouch = false
		rootPart.CanQuery = false
	end
end

------------------//MAIN FUNCTIONS
local function setup_character(character: Model): ()
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		setup_humanoid(humanoid)
	end

	anchor_root_part(character)

	local descendants = character:GetDescendants()
	for _, descendant in descendants do
		clean_instance(descendant)
	end

	character.DescendantAdded:Connect(function(descendant: Instance)
		task.defer(function()
			if descendant.Parent then
				clean_instance(descendant)
			end
		end)
	end)
end

local function on_player_added(player: Player): ()
	player.CharacterAdded:Connect(setup_character)

	local character = player.Character
	if character then
		setup_character(character)
	end
end

------------------//INIT
for _, player in Players:GetPlayers() do
	on_player_added(player)
end

Players.PlayerAdded:Connect(on_player_added)

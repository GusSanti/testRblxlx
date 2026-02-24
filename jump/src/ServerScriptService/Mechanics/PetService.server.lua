local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DATA_UTILITY = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utility"):WaitForChild("DataUtility"))
local DATA_PETS = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Datas"):WaitForChild("PetsData"))

local PET_DISTANCE = 6      
local PET_SIDE_OFFSET = 4   
local FLY_HEIGHT = 3
local BOBBING_SPEED = 4
local BOBBING_AMPLITUDE = 0.5
local FLY_BOBBING_AMPLITUDE = 0.5
local ALIGN_RESPONSIVENESS = 25
local ALIGN_MAX_FORCE = 25000
local ALIGN_MAX_VELOCITY = 40
local ROTATION_RESPONSIVENESS = 80
local ROTATION_MAX_TORQUE = 15000
local ROTATION_MAX_ANGULAR_VELOCITY = 20
local TELEPORT_DISTANCE = 60

local activePets = {}

local function create_pet_holder(character)
	local hrp = character:WaitForChild("HumanoidRootPart")

	local holder = Instance.new("Part")
	holder.Name = "PetHolder"
	holder.Transparency = 1
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Massless = true
	holder.Size = Vector3.new(1, 1, 1)
	holder.CFrame = hrp.CFrame
	holder.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = holder
	weld.Parent = holder

	return holder
end

local function create_pet_physics(petPart, character, isFlying, slotIndex)
	local hrp = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")

	local holder = character:FindFirstChild("PetHolder") or create_pet_holder(character)

	local charAttachment = Instance.new("Attachment")
	charAttachment.Name = "PetTargetAttachment"
	charAttachment.Parent = holder

	local petAttachment = Instance.new("Attachment")
	petAttachment.Name = "PetBaseAttachment"
	petAttachment.Parent = petPart

	local alignPos = Instance.new("AlignPosition")
	alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
	alignPos.Attachment0 = petAttachment
	alignPos.Attachment1 = charAttachment
	alignPos.Responsiveness = ALIGN_RESPONSIVENESS
	alignPos.MaxForce = ALIGN_MAX_FORCE
	alignPos.MaxVelocity = ALIGN_MAX_VELOCITY
	alignPos.Parent = petPart

	local alignRot = Instance.new("AlignOrientation")
	alignRot.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignRot.Attachment0 = petAttachment
	alignRot.Responsiveness = ROTATION_RESPONSIVENESS
	alignRot.MaxTorque = ROTATION_MAX_TORQUE
	alignRot.MaxAngularVelocity = ROTATION_MAX_ANGULAR_VELOCITY
	alignRot.Parent = petPart

	local petSize = petPart.Size
	local petHalfHeight = petSize.Y / 2

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {petPart, character}

	task.spawn(function()
		local t = 0
		while petPart.Parent and character.Parent do
			local dt = task.wait()
			t = t + dt * BOBBING_SPEED

			local bobbingX = math.cos(t) * BOBBING_AMPLITUDE
			local offsetX, offsetZ

			if slotIndex == 1 then
				offsetX = (PET_SIDE_OFFSET) + (bobbingX * 0.2)
				offsetZ = PET_DISTANCE 
			elseif slotIndex == 2 then
				offsetX = -(PET_SIDE_OFFSET) - (bobbingX * 0.2)
				offsetZ = PET_DISTANCE
			else
				offsetX = (PET_SIDE_OFFSET * (slotIndex % 2 == 0 and -1 or 1))
				offsetZ = PET_DISTANCE + (math.floor(slotIndex/3) * 3) 
			end

			local targetY

			if isFlying then
				targetY = FLY_HEIGHT + (math.sin(t) * FLY_BOBBING_AMPLITUDE)
			else
				local holderCFrame = holder.CFrame
				local targetWorldPos = holderCFrame:ToWorldSpace(CFrame.new(offsetX, 0, offsetZ)).Position

				local rayOrigin = targetWorldPos + Vector3.new(0, 10, 0)
				local rayDirection = Vector3.new(0, -20, 0)

				local rayResult = Workspace:Raycast(rayOrigin, rayDirection, rayParams)

				if rayResult then
					local groundY = rayResult.Position.Y
					local playerY = hrp.Position.Y
					targetY = (groundY - playerY) + petHalfHeight
				else
					local currentHipHeight = humanoid.HipHeight
					if currentHipHeight == 0 then currentHipHeight = 2 end
					targetY = -currentHipHeight + petHalfHeight
				end
			end

			charAttachment.Position = Vector3.new(offsetX, targetY, offsetZ)

			local playerLookVector = hrp.CFrame.LookVector
			local petPos = petPart.Position
			local forwardPoint = petPos + (playerLookVector * 10)
			local targetRotation = CFrame.lookAt(petPos, Vector3.new(forwardPoint.X, petPos.Y, forwardPoint.Z))

			alignRot.CFrame = targetRotation * CFrame.Angles(0, math.rad(-90), 0)

			if (petPart.Position - hrp.Position).Magnitude > TELEPORT_DISTANCE then
				petPart.CFrame = hrp.CFrame
			end
		end
	end)
end

local function update_pet_multiplier(player)
	local equippedPetsRaw = DATA_UTILITY.server.get(player, "EquippedPets")
	local equippedPets = {}

	if type(equippedPetsRaw) == "string" then
		if equippedPetsRaw ~= "" then
			equippedPets = {[1] = equippedPetsRaw}
		end
	elseif type(equippedPetsRaw) == "table" then
		equippedPets = equippedPetsRaw
	end

	local totalMultiplier = 1

	for _, petName in pairs(equippedPets) do
		if petName and petName ~= "" then
			local petData = DATA_PETS.GetPetData(petName)
			if petData and petData.Multiplier then
				totalMultiplier = totalMultiplier + petData.Multiplier
			end
		end
	end

	player:SetAttribute("Multiplier", totalMultiplier)
end

local function spawn_pets(player)
	if activePets[player] then
		for _, petObj in pairs(activePets[player]) do
			petObj:Destroy()
		end
		activePets[player] = {}
	end

	local equippedPetsRaw = DATA_UTILITY.server.get(player, "EquippedPets")
	local equippedPets = {}

	if type(equippedPetsRaw) == "string" then
		if equippedPetsRaw ~= "" then
			equippedPets = {[1] = equippedPetsRaw}
			DATA_UTILITY.server.set(player, "EquippedPets", equippedPets)
		end
	elseif type(equippedPetsRaw) == "table" then
		equippedPets = equippedPetsRaw
	end

	update_pet_multiplier(player)

	local character = player.Character
	if not character then return end
	local hrp = character:WaitForChild("HumanoidRootPart")

	for slotIndex, petName in pairs(equippedPets) do
		if petName and petName ~= "" then
			local petData = DATA_PETS.GetPetData(petName)
			if petData and petData.MeshPart then
				local newPet = petData.MeshPart:Clone()
				newPet.Name = player.Name .. "_Pet_" .. slotIndex
				newPet.CanCollide = false
				newPet.Massless = true
				newPet.CFrame = hrp.CFrame * CFrame.new(0, 5, 5)
				newPet.Parent = character

				create_pet_physics(
					newPet,
					character,
					petData.IsFlying or false,
					tonumber(slotIndex)
				)

				newPet:SetNetworkOwner(player)

				if not activePets[player] then
					activePets[player] = {}
				end
				activePets[player][slotIndex] = newPet
			end
		end
	end
end

local function on_character_added(player, character)
	task.wait(1)
	spawn_pets(player)
end

local function on_player_added(player)
	if not player:GetAttribute("Multiplier") then
		player:SetAttribute("Multiplier", 1)
	end

	player.CharacterAdded:Connect(function(character)
		on_character_added(player, character)
	end)

	task.spawn(function()
		local connection = nil
		local attempts = 0

		while attempts < 20 and not connection do
			connection = DATA_UTILITY.server.bind(player, "EquippedPets", function(newVal)
				spawn_pets(player)
			end)

			if connection then
				break
			end

			attempts += 1
			task.wait(0.5)
		end

		if not connection then
			warn("[PetService] Falha ao conectar listener de pets para:", player.Name)
		end
	end)
end

local function on_player_removing(player)
	if activePets[player] then
		for _, petObj in pairs(activePets[player]) do
			petObj:Destroy()
		end
		activePets[player] = nil
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	on_player_added(player)
	if player.Character then
		on_character_added(player, player.Character)
	end
end

Players.PlayerAdded:Connect(on_player_added)
Players.PlayerRemoving:Connect(on_player_removing)
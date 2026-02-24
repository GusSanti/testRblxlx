local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ASSETS_FOLDER = ReplicatedStorage:WaitForChild("Assets")
local PETS_FOLDER = ASSETS_FOLDER:WaitForChild("Pets")

export type PetData = {
	MeshPart: MeshPart?,
	DisplayName: string,
	Raritys: string,
	Weight: number,
	Multiplier: number,
	IsFlying: boolean,
	World: number
}

local PetsConfig: {[string]: PetData} = {

	["Kitty"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Kitty"),
		DisplayName = "Kitty",
		Weight = 35,
		World = 1,
		IsFlying = false,
		Raritys = "Common",
		Multiplier = 0.1
	},
	["Doggy"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Doggy"),
		DisplayName = "Doggy",
		Weight = 30,
		World = 1,
		IsFlying = false,
		Raritys = "Common",
		Multiplier = 0.1
	},
	["Fish"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Fish"),
		DisplayName = "Fish",
		Weight = 30,
		World = 1,
		IsFlying = true, 
		Raritys = "Common",
		Multiplier = 0.12
	},

	["Shark"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Shark"),
		DisplayName = "Shark",
		Weight = 25,
		World = 1,
		IsFlying = true,
		Raritys = "Uncommon",
		Multiplier = 0.15
	},

	["Bunny"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Bunny"),
		DisplayName = "Bunny",
		Weight = 20,
		World = 1,
		IsFlying = false,
		Raritys = "Rare",
		Multiplier = 0.2
	},
	["Turtle"] = { 
		MeshPart = PETS_FOLDER:FindFirstChild("Turtle"),
		DisplayName = "Turtle",
		Weight = 20,
		World = 1,
		IsFlying = false,
		Raritys = "Rare",
		Multiplier = 0.2
	},

	["Axolotl"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Axolotl"),
		DisplayName = "Axolotl",
		Weight = 10,
		World = 1,
		IsFlying = false,
		Raritys = "Legendary",
		Multiplier = 0.3
	},
	["Bear"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Bear"),
		DisplayName = "Bear",
		Weight = 10,
		World = 1,
		IsFlying = false,
		Raritys = "Legendary",
		Multiplier = 0.3
	},

	["Dragon"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Dragon"),
		DisplayName = "Dragon",
		Weight = 5,
		World = 1,
		IsFlying = true,
		Raritys = "Mythic",
		Multiplier = 0.5
	},

	["Golden Kitty"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Kitty"), DisplayName = "Golden Kitty", Weight = 35, World = 1, IsFlying = false, Raritys = "Golden Common", Multiplier = 0.3 },
	["Golden Doggy"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Doggy"), DisplayName = "Golden Doggy", Weight = 30, World = 1, IsFlying = false, Raritys = "Golden Common", Multiplier = 0.3 },
	["Golden Fish"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Fish"), DisplayName = "Golden Fish", Weight = 25, World = 1, IsFlying = true, Raritys = "Golden Common", Multiplier = 0.35 },
	["Golden Shark"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Shark"), DisplayName = "Golden Shark", Weight = 25, World = 1, IsFlying = true, Raritys = "Golden Uncommon", Multiplier = 0.45 },
	["Golden Bunny"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Bunny"), DisplayName = "Golden Bunny", Weight = 20, World = 1, IsFlying = false, Raritys = "Golden Rare", Multiplier = 0.6 },
	["Golden Turtle"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Turtle"), DisplayName = "Golden Turtle", Weight = 15, World = 1, IsFlying = false, Raritys = "Golden Rare", Multiplier = 0.6 },
	["Golden Axolotl"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Axolotl"), DisplayName = "Golden Axolotl", Weight = 20, World = 1, IsFlying = false, Raritys = "Golden Legendary", Multiplier = 0.9 },
	["Golden Bear"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Bear"), DisplayName = "Golden Bear", Weight = 10, World = 1, IsFlying = false, Raritys = "Golden Legendary", Multiplier = 0.9 },
	["Golden Dragon"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Dragon"), DisplayName = "Golden Dragon", Weight = 5, World = 1, IsFlying = true, Raritys = "Golden Mythic", Multiplier = 1.5 },


	["Penguin"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Penguin"),
		DisplayName = "Penguin",
		Weight = 30,
		World = 2,
		IsFlying = false,
		Raritys = "Common",
		Multiplier = 0.15
	},
	["Walrus"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Walrus"),
		DisplayName = "Walrus",
		Weight = 25,
		World = 2,
		IsFlying = false,
		Raritys = "Uncommon",
		Multiplier = 0.2
	},
	["Snow Ram"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Snow Ram"),
		DisplayName = "Snow Ram",
		Weight = 20,
		World = 2,
		IsFlying = false,
		Raritys = "Rare",
		Multiplier = 0.25
	},
	["Deer"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Deer"),
		DisplayName = "Deer",
		Weight = 15,
		World = 2,
		IsFlying = false,
		Raritys = "Epic",
		Multiplier = 0.35
	},
	["Yeti"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Yeti"),
		DisplayName = "Yeti",
		Weight = 10,
		World = 2,
		IsFlying = false,
		Raritys = "Legendary",
		Multiplier = 0.5
	},

	["Golden Penguin"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Penguin"), DisplayName = "Golden Penguin", Weight = 30, World = 2, IsFlying = false, Raritys = "Golden Common", Multiplier = 0.45 },
	["Golden Walrus"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Walrus"), DisplayName = "Golden Walrus", Weight = 25, World = 2, IsFlying = false, Raritys = "Golden Uncommon", Multiplier = 0.6 },
	["Golden Snow Ram"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Snow Ram"), DisplayName = "Golden Snow Ram", Weight = 20, World = 2, IsFlying = false, Raritys = "Golden Rare", Multiplier = 0.75 },
	["Golden Deer"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Deer"), DisplayName = "Golden Deer", Weight = 15, World = 2, IsFlying = false, Raritys = "Golden Epic", Multiplier = 1.0 },
	["Golden Yeti"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Yeti"), DisplayName = "Golden Yeti", Weight = 10, World = 2, IsFlying = false, Raritys = "Golden Legendary", Multiplier = 1.5 },


	["Parrot"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Parrot"),
		DisplayName = "Parrot",
		Weight = 30,
		World = 3,
		IsFlying = true,
		Raritys = "Common",
		Multiplier = 0.2
	},
	["Monkey"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Monkey"),
		DisplayName = "Monkey",
		Weight = 25,
		World = 3,
		IsFlying = false,
		Raritys = "Uncommon",
		Multiplier = 0.3
	},
	["Tiger"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Tiger"),
		DisplayName = "Tiger",
		Weight = 20,
		World = 3,
		IsFlying = false,
		Raritys = "Rare",
		Multiplier = 0.4
	},
	["Elephant"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Elephant"),
		DisplayName = "Elephant",
		Weight = 15,
		World = 3,
		IsFlying = false,
		Raritys = "Epic",
		Multiplier = 0.6
	},
	["Crocodile"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Crocodile"),
		DisplayName = "Crocodile",
		Weight = 10,
		World = 3,
		IsFlying = false,
		Raritys = "Legendary",
		Multiplier = 0.8
	},

	["Golden Parrot"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Parrot"), DisplayName = "Golden Parrot", Weight = 30, World = 3, IsFlying = true, Raritys = "Golden Common", Multiplier = 0.6 },
	["Golden Monkey"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Monkey"), DisplayName = "Golden Monkey", Weight = 25, World = 3, IsFlying = false, Raritys = "Golden Uncommon", Multiplier = 0.9 },
	["Golden Tiger"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Tiger"), DisplayName = "Golden Tiger", Weight = 20, World = 3, IsFlying = false, Raritys = "Golden Rare", Multiplier = 1.2 },
	["Golden Elephant"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Elephant"), DisplayName = "Golden Elephant", Weight = 15, World = 3, IsFlying = false, Raritys = "Golden Epic", Multiplier = 1.8 },
	["Golden Crocodile"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Crocodile"), DisplayName = "Golden Crocodile", Weight = 10, World = 3, IsFlying = false, Raritys = "Golden Legendary", Multiplier = 2.4 },


	["Nutcracker Squirrel"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Nutcracker Squirrel"),
		DisplayName = "Nutcracker Squirrel",
		Weight = 30,
		World = 4,
		IsFlying = false,
		Raritys = "Common",
		Multiplier = 0.5
	},
	["Santa Hat Seal"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Santa Hat Seal"),
		DisplayName = "Santa Hat Seal",
		Weight = 25,
		World = 4,
		IsFlying = false,
		Raritys = "Uncommon",
		Multiplier = 0.7
	},
	["Santa Hat Polar Bear"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Santa Hat Polar Bear"),
		DisplayName = "Santa Hat Polar Bear",
		Weight = 20,
		World = 4,
		IsFlying = false,
		Raritys = "Rare",
		Multiplier = 1.0
	},
	["Rudolph"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Rudolph"),
		DisplayName = "Rudolph",
		Weight = 15,
		World = 4,
		IsFlying = false, 
		Raritys = "Epic",
		Multiplier = 1.5
	},
	["Santa Paws"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Santa Paws"),
		DisplayName = "Santa Paws",
		Weight = 10,
		World = 4,
		IsFlying = false,
		Raritys = "Legendary",
		Multiplier = 2.5
	},

	["Golden Nutcracker Squirrel"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Nutcracker Squirrel"), DisplayName = "Golden Nutcracker Squirrel", Weight = 30, World = 4, IsFlying = false, Raritys = "Golden Common", Multiplier = 1.5 },
	["Golden Santa Hat Seal"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Santa Hat Seal"), DisplayName = "Golden Santa Hat Seal", Weight = 25, World = 4, IsFlying = false, Raritys = "Golden Uncommon", Multiplier = 2.1 },
	["Golden Santa Hat Polar Bear"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Santa Hat Polar Bear"), DisplayName = "Golden Santa Hat Polar Bear", Weight = 20, World = 4, IsFlying = false, Raritys = "Golden Rare", Multiplier = 3.0 },
	["Golden Rudolph"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Rudolph"), DisplayName = "Golden Rudolph", Weight = 15, World = 4, IsFlying = false, Raritys = "Golden Epic", Multiplier = 4.5 },
	["Golden Santa Paws"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Santa Paws"), DisplayName = "Golden Santa Paws", Weight = 10, World = 4, IsFlying = false, Raritys = "Golden Legendary", Multiplier = 7.5 },


	["Cotton Candy Lamb"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Cotton Candy Lamb"),
		DisplayName = "Cotton Candy Lamb",
		Weight = 30,
		World = 5,
		IsFlying = false,
		Raritys = "Common",
		Multiplier = 1.0
	},
	["Cotton Candy Cow"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Cotton Candy Cow"),
		DisplayName = "Cotton Candy Cow",
		Weight = 25,
		World = 5,
		IsFlying = false,
		Raritys = "Uncommon",
		Multiplier = 1.5
	},
	["Pony"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Pony"),
		DisplayName = "Pony",
		Weight = 20,
		World = 5,
		IsFlying = false,
		Raritys = "Rare",
		Multiplier = 2.0
	},
	["Cupcake"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Cupcake"),
		DisplayName = "Cupcake",
		Weight = 15,
		World = 5,
		IsFlying = true,
		Raritys = "Epic",
		Multiplier = 3.5
	},
	["Unicorn"] = {
		MeshPart = PETS_FOLDER:FindFirstChild("Unicorn"),
		DisplayName = "Unicorn",
		Weight = 10,
		World = 5,
		IsFlying = true,
		Raritys = "Legendary",
		Multiplier = 5.0
	},

	["Golden Cotton Candy Lamb"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Cotton Candy Lamb"), DisplayName = "Golden Cotton Candy Lamb", Weight = 30, World = 5, IsFlying = false, Raritys = "Golden Common", Multiplier = 3.0 },
	["Golden Cotton Candy Cow"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Cotton Candy Cow"), DisplayName = "Golden Cotton Candy Cow", Weight = 25, World = 5, IsFlying = false, Raritys = "Golden Uncommon", Multiplier = 4.5 },
	["Golden Pony"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Pony"), DisplayName = "Golden Pony", Weight = 20, World = 5, IsFlying = false, Raritys = "Golden Rare", Multiplier = 6.0 },
	["Golden Cupcake"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Cupcake"), DisplayName = "Golden Cupcake", Weight = 15, World = 5, IsFlying = true, Raritys = "Golden Epic", Multiplier = 10.5 },
	["Golden Unicorn"] = { MeshPart = PETS_FOLDER:FindFirstChild("Golden Unicorn"), DisplayName = "Golden Unicorn", Weight = 10, World = 5, IsFlying = true, Raritys = "Golden Legendary", Multiplier = 15.0 },
}

local DataPets = {}

function DataPets.GetPetData(petName: string): PetData?
	return PetsConfig[petName]
end

function DataPets.GetAllPets()
	return PetsConfig
end

function DataPets.GetPetsByWorld(world: number)
	local result = {}
	for name, pet in pairs(PetsConfig) do
		if pet.World == world then
			result[name] = pet
		end
	end
	return result
end

function DataPets.GetPetViewport(petName)
	local petData = PetsConfig[petName]
	if not petData or not petData.MeshPart then
		return nil
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Name = "PetView_" .. petName

	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local partClone = petData.MeshPart:Clone()
	partClone.CFrame = CFrame.new()
	partClone.Anchored = true
	partClone.Parent = viewport
	local cf = partClone.CFrame
	local size = partClone.Size

	local maxDimension = math.max(size.X, size.Y, size.Z)
	local safetyMargin = 1.7
	local viewAngle = math.rad(90)

	local fov = camera.FieldOfView
	local fitDistance = (maxDimension / 2) / math.tan(math.rad(fov / 2))
	local finalDistance = (size.Z / 2) + (fitDistance * safetyMargin)

	local rotatedDirection = (cf * CFrame.Angles(0, viewAngle, 0)).LookVector
	local cameraPosition = cf.Position + (rotatedDirection * finalDistance)
	cameraPosition += Vector3.new(0, size.Y * 0.1, 0)

	camera.CFrame = CFrame.lookAt(cameraPosition, cf.Position)

	return viewport
end


return DataPets
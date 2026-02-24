------------------//SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//TYPES
export type EggData = {
	Price: number,
	Currency: string,
	Model: Model,
	Weights: {[string]: number}
}

------------------//DATA
local DataEggs: {[string]: EggData} = {

	-- WORLD 1 ----------------------------------------------------

	["Common Egg"] = {
		Price = 200,
		Currency = "Coins",
		Model = ReplicatedStorage.Assets.Egg["Common Egg"],
		Weights = {
			["Kitty"] = 35,
			["Doggy"] = 30,
			["Bunny"] = 20,
			["Bear"] = 10,
			["Dragon"] = 5
		}
	},

	["Golden Common Egg"] = {
		Price = 1,
		Currency = "RebirthTokens",
		Model = ReplicatedStorage.Assets.Egg["Golden Common Egg"],
		Weights = {
			["Golden Kitty"] = 35,
			["Golden Doggy"] = 30,
			["Golden Bunny"] = 20,
			["Golden Bear"] = 10,
			["Golden Dragon"] = 5
		}
	},

	["Aqua Egg"] = {
		Price = 300,
		Currency = "Coins",
		Model = ReplicatedStorage.Assets.Egg["Aqua Egg"],
		Weights = {
			["Fish"] = 30,
			["Shark"] = 25,
			["Turtle"] = 20,
			["Penguin"] = 15,
			["Axolotl"] = 10
		}
	},

	["Golden Aqua Egg"] = {
		Price = 500,
		Currency = "RebirthTokens",
		Model = ReplicatedStorage.Assets.Egg["Golden Aqua Egg"],
		Weights = {
			["Golden Fish"] = 25,
			["Golden Shark"] = 25,
			["Golden Axolotl"] = 20,
			["Golden Penguin"] = 15,
			["Golden Turtle"] = 15
		}
	},

	-- WORLD 2 ----------------------------------------------------

	["Frost Egg"] = {
		Price = 750,
		Currency = "Coins",
		Model = ReplicatedStorage.Assets.Egg["Frost Egg"],
		Weights = {
			["Penguin"] = 30,
			["Walrus"] = 25,
			["Snow Ram"] = 20,
			["Deer"] = 15,
			["Yeti"] = 10
		}
	},

	["Golden Frost Egg"] = {
		Price = 3,
		Currency = "RebirthTokens",
		Model = ReplicatedStorage.Assets.Egg["Golden Frost Egg"],
		Weights = {
			["Golden Penguin"] = 30,
			["Golden Walrus"] = 25,
			["Golden Snow Ram"] = 20,
			["Golden Deer"] = 15,
			["Golden Yeti"] = 10
		}
	},

	-- WORLD 3 ----------------------------------------------------

	["Jungle Egg"] = {
		Price = 3000,
		Currency = "Coins",
		Model = ReplicatedStorage.Assets.Egg["Jungle Egg"],
		Weights = {
			["Parrot"] = 30,
			["Monkey"] = 25,
			["Tiger"] = 20,
			["Elephant"] = 15,
			["Crocodile"] = 10
		}
	},

	["Golden Jungle Egg"] = {
		Price = 7,
		Currency = "RebirthTokens",
		Model = ReplicatedStorage.Assets.Egg["Golden Jungle Egg"],
		Weights = {
			["Golden Parrot"] = 30,
			["Golden Monkey"] = 25,
			["Golden Tiger"] = 20,
			["Golden Elephant"] = 15,
			["Golden Crocodile"] = 10
		}
	},

	-- WORLD 4 ----------------------------------------------------

	["Christmas Egg"] = {
		Price = 5000,
		Currency = "Coins",
		Model = ReplicatedStorage.Assets.Egg["Christmas Egg"],
		Weights = {
			["Nutcracker Squirrel"] = 30,
			["Santa Hat Seal"] = 25,
			["Santa Hat Polar Bear"] = 20,
			["Rudolph"] = 15,
			["Santa Paws"] = 10
		}
	},

	["Golden Christmas Egg"] = {
		Price = 10,
		Currency = "RebirthTokens",
		Model = ReplicatedStorage.Assets.Egg["Christmas Egg"],
		Weights = {
			["Golden Nutcracker Squirrel"] = 30,
			["Golden Santa Hat Seal"] = 25,
			["Golden Santa Hat Polar Bear"] = 20,
			["Golden Rudolph"] = 15,
			["Golden Santa Paws"] = 10
		}
	},

	-- WORLD 5 ----------------------------------------------------

	["Cupcake Egg"] = {
		Price = 10000,
		Currency = "Coins",
		Model = ReplicatedStorage.Assets.Egg["Cupcake Egg"],
		Weights = {
			["Cotton Candy Lamb"] = 30,
			["Cotton Candy Cow"] = 25,
			["Pony"] = 20,
			["Cupcake"] = 15,
			["Unicorn"] = 10
		}
	},

	["Golden Mythic Egg"] = {
		Price = 20,
		Currency = "RebirthTokens",
		Model = ReplicatedStorage.Assets.Egg["Cupcake Egg"],
		Weights = {
			["Golden Cotton Candy Lamb"] = 30,
			["Golden Cotton Candy Cow"] = 25,
			["Golden Pony"] = 20,
			["Golden Cupcake"] = 15,
			["Golden Unicorn"] = 10
		}
	}
}

------------------//INIT
return DataEggs

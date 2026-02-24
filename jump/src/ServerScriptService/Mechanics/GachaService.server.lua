------------------//SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

------------------//CONSTANTS
local DATA_UTILITY = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utility"):WaitForChild("DataUtility"))
local PETS_DATA_MODULE = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Datas"):WaitForChild("PetsData"))
local EGGS_DATA_MODULE = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Datas"):WaitForChild("EggData"))
local RARITYS_DATA_MODULE = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Datas"):WaitForChild("RaritysData"))

local REMOTE_NAME = "EggGachaRemote"
local CHECK_FUNDS_REMOTE_NAME = "CheckEggFundsRemote"

------------------//VARIABLES
local gachaRemote = nil
local checkFundsRemote = nil
local playerDebounce = {}

------------------//FUNCTIONS
local function setupRemotes()
	local remotesFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes")

	gachaRemote = remotesFolder:FindFirstChild(REMOTE_NAME)
	if not gachaRemote then
		gachaRemote = Instance.new("RemoteFunction")
		gachaRemote.Name = REMOTE_NAME
		gachaRemote.Parent = remotesFolder
	end

	checkFundsRemote = remotesFolder:FindFirstChild(CHECK_FUNDS_REMOTE_NAME)
	if not checkFundsRemote then
		checkFundsRemote = Instance.new("RemoteFunction")
		checkFundsRemote.Name = CHECK_FUNDS_REMOTE_NAME
		checkFundsRemote.Parent = remotesFolder
	end
end

local function getRarityTier(rarityName)
	local rarityData = RARITYS_DATA_MODULE[rarityName]
	return rarityData and rarityData.Tier or 0
end

local function applyLuckyBoost(weights, luckyMultiplier)
	if luckyMultiplier <= 1 then
		return weights
	end

	local boostedWeights = {}
	local allPets = PETS_DATA_MODULE.GetAllPets()

	for petName, baseWeight in pairs(weights) do
		local petData = allPets[petName]
		if petData then
			local rarityTier = getRarityTier(petData.Raritys)
			local boostFactor = 1 + (rarityTier * 0.2 * (luckyMultiplier - 1))
			boostedWeights[petName] = baseWeight * boostFactor
		else
			boostedWeights[petName] = baseWeight
		end
	end

	return boostedWeights
end

local function pickWeightedRandomPet(eggSpecificWeights, luckyMultiplier)
	local weightsToUse = applyLuckyBoost(eggSpecificWeights or {}, luckyMultiplier or 1)

	local totalWeight = 0
	local weightedTable = {}

	for petName, weight in pairs(weightsToUse) do
		totalWeight = totalWeight + weight
		table.insert(weightedTable, {
			Name = petName,
			Weight = weight,
			CumulativeWeight = totalWeight
		})
	end

	if totalWeight == 0 then 
		warn("Total weight is 0, returning default pet")
		return "Cat" 
	end

	local randomValue = math.random() * totalWeight

	for _, entry in ipairs(weightedTable) do
		if randomValue <= entry.CumulativeWeight then
			return entry.Name
		end
	end

	return weightedTable[1].Name
end

local function checkCanOpenEgg(player, eggName)
	if not player or not player:IsDescendantOf(game.Players) then
		return {success = false, reason = "Invalid player"}
	end

	if playerDebounce[player.UserId] then
		return {success = false, reason = "AlreadyOpening"}
	end

	if not eggName or type(eggName) ~= "string" then
		return {success = false, reason = "Invalid egg name"}
	end

	local eggInfo = EGGS_DATA_MODULE[eggName]
	if not eggInfo then 
		return {success = false, reason = "Egg not found"}
	end

	local currencyKey = eggInfo.Currency 
	local price = eggInfo.Price
	local currentBalance = DATA_UTILITY.server.get(player, currencyKey)

	if not currentBalance or currentBalance < price then
		return {
			success = false, 
			reason = "InsufficientFunds",
			details = {
				required = price,
				current = currentBalance or 0,
				currency = currencyKey
			}
		}
	end

	return {success = true}
end

local function handleEggOpen(player, eggName)
	if not player or not player:IsDescendantOf(game.Players) then
		warn("Invalid player")
		return nil
	end

	if playerDebounce[player.UserId] then
		warn(player.Name .. " tentou abrir ovo enquanto já estava abrindo outro")
		return nil
	end

	if not eggName or type(eggName) ~= "string" then
		warn("Invalid egg name received")
		return nil
	end

	local eggInfo = EGGS_DATA_MODULE[eggName]
	if not eggInfo then 
		warn("Ovo não encontrado no DataEggs: " .. tostring(eggName))
		return nil 
	end

	playerDebounce[player.UserId] = true

	local currencyKey = eggInfo.Currency 
	local price = eggInfo.Price

	print("[GACHA] Iniciando compra para " .. player.Name .. " - Ovo: " .. eggName .. " - Preço: " .. price .. " " .. currencyKey)

	local currentBalance = DATA_UTILITY.server.get(player, currencyKey)

	if not currentBalance or currentBalance < price then
		warn("[GACHA] " .. player.Name .. " não tem " .. currencyKey .. " suficiente. Saldo: " .. tostring(currentBalance) .. ", Preço: " .. price)
		playerDebounce[player.UserId] = nil
		return nil 
	end

	print("[GACHA] Saldo atual de " .. player.Name .. ": " .. currentBalance .. " " .. currencyKey)

	local newBalance = currentBalance - price
	print("[GACHA] Novo saldo será: " .. newBalance)

	DATA_UTILITY.server.set(player, currencyKey, newBalance)

	task.wait(0.1)

	local verifyBalance = DATA_UTILITY.server.get(player, currencyKey)
	if verifyBalance ~= newBalance then
		warn("[GACHA] Falha ao verificar desconto. Esperado: " .. newBalance .. ", Atual: " .. tostring(verifyBalance))
		DATA_UTILITY.server.set(player, currencyKey, currentBalance)
		playerDebounce[player.UserId] = nil
		return nil
	end

	print("[GACHA] Saldo atualizado com sucesso para " .. player.Name)

	local luckyMultiplier = player:GetAttribute("Lucky") or 1

	local ownedUpgrades = DATA_UTILITY.server.get(player, "OwnedRebirthUpgrades") or {}
	if table.find(ownedUpgrades, "EggLuck") then
		luckyMultiplier = luckyMultiplier + 0.5 
	end

	print("[GACHA] Lucky multiplier de " .. player.Name .. ": " .. luckyMultiplier)

	local pickedPetName = pickWeightedRandomPet(eggInfo.Weights, luckyMultiplier)

	if not pickedPetName then
		warn("[GACHA] Falha ao escolher pet do ovo " .. eggName)
		DATA_UTILITY.server.set(player, currencyKey, currentBalance)
		playerDebounce[player.UserId] = nil
		return nil
	end

	print("[GACHA] Pet escolhido: " .. pickedPetName)

	local ownedPets = DATA_UTILITY.server.get(player, "OwnedPets") or {}
	ownedPets[pickedPetName] = true
	DATA_UTILITY.server.set(player, "OwnedPets", ownedPets)

	print("[GACHA] " .. player.Name .. " abriu " .. eggName .. " e ganhou um " .. pickedPetName)
	
	local currentHatched = DATA_UTILITY.server.get(player, "Stats.TotalHatched") or 0
	DATA_UTILITY.server.set(player, "Stats.TotalHatched", currentHatched + 1)
	
	task.wait(0.3)

	playerDebounce[player.UserId] = nil

	return pickedPetName
end

------------------//INIT
setupRemotes()

checkFundsRemote.OnServerInvoke = function(player, eggName)
	local result = checkCanOpenEgg(player, eggName)
	return result
end

gachaRemote.OnServerInvoke = handleEggOpen

game.Players.PlayerAdded:Connect(function(player)
	if not player:GetAttribute("Lucky") then
		player:SetAttribute("Lucky", 1)
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	if playerDebounce[player.UserId] then
		playerDebounce[player.UserId] = nil
	end
end)
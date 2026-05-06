------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")
local DataStoreService: DataStoreService = game:GetService("DataStoreService")

------------------//CONSTANTS
local DATA_STORE_NAME: string = "ChosenByGod_PlayerData_V1"
local MODULES_FOLDER_NAME: string = "Modules"

------------------//VARIABLES
local replicatedModules: Folder = ReplicatedStorage:WaitForChild(MODULES_FOLDER_NAME) :: Folder
local serverModules: Folder = ServerStorage:WaitForChild(MODULES_FOLDER_NAME) :: Folder
local utilityModules: Folder = replicatedModules:WaitForChild("Utility") :: Folder
local dictionaryModules: Folder = replicatedModules:WaitForChild("Dictionary") :: Folder
local gameModules: Folder = replicatedModules:WaitForChild("Game") :: Folder
local serverGameModules: Folder = serverModules:WaitForChild("Game") :: Folder

local ModuleCache = require(utilityModules:WaitForChild("ModuleCache") :: ModuleScript)
local RemoteNames = ModuleCache.require(utilityModules:WaitForChild("RemoteNames") :: ModuleScript)
local RemoteController = ModuleCache.require(utilityModules:WaitForChild("RemoteController") :: ModuleScript)
local GameConfig = ModuleCache.require(gameModules:WaitForChild("GameConfig") :: ModuleScript)
local ExpFormula = ModuleCache.require(gameModules:WaitForChild("ExpFormula") :: ModuleScript)
local WorldDictionary = ModuleCache.require(dictionaryModules:WaitForChild("WorldDictionary") :: ModuleScript)
local AbilityDictionary = ModuleCache.require(dictionaryModules:WaitForChild("AbilityDictionary") :: ModuleScript)
local QuestDictionary = ModuleCache.require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
local PlayerDataTemplate = ModuleCache.require(serverGameModules:WaitForChild("PlayerDataTemplate") :: ModuleScript)

local playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
local playerData: {[Player]: PlayerDataTemplate.PlayerData} = {}
local lastTrainAt: {[Player]: number} = {}
local remoteFolder: Folder? = nil
local getPlayerDataRemote: RemoteFunction? = nil
local selectWorldRemote: RemoteFunction? = nil
local trainRemote: RemoteFunction? = nil
local battleActionRemote: RemoteFunction? = nil
local questActionRemote: RemoteFunction? = nil
local updateSettingRemote: RemoteFunction? = nil
local dataChangedRemote: RemoteEvent? = nil
local notifyRemote: RemoteEvent? = nil

------------------//FUNCTIONS
local function get_day_number(timestamp: number): number
	return math.floor(timestamp / 86400)
end

local function apply_daily_login(data: PlayerDataTemplate.PlayerData): ()
	local currentTime = os.time()
	local lastLoginDay = get_day_number(data.lastLogin)
	local currentDay = get_day_number(currentTime)

	if lastLoginDay ~= currentDay then
		data.dailyQuestsDone = {}
		if currentDay - lastLoginDay == 1 then
			data.loginStreak += 1
		else
			data.loginStreak = 1
		end
	end

	data.lastLogin = currentTime
end

local function get_data_key(player: Player): string
	return tostring(player.UserId)
end

local function load_saved_data(player: Player): any?
	local success, savedData = pcall(function()
		return playerDataStore:GetAsync(get_data_key(player))
	end)

	if success and typeof(savedData) == "table" then
		return savedData
	end

	if not success then
		warn("Data load failed for " .. player.Name)
	end

	return nil
end

local function apply_player_attributes(player: Player, data: PlayerDataTemplate.PlayerData): ()
	local world = WorldDictionary.get_world(data.world)

	player:SetAttribute("World", data.world)
	player:SetAttribute("WorldName", world and world.displayName or "")
	player:SetAttribute("Level", data.level)
	player:SetAttribute("Exp", data.exp)
	player:SetAttribute("RebirthCount", data.rebirthCount)
	player:SetAttribute("WorldSouls", data.worldSouls)
end

local function get_client_data(data: PlayerDataTemplate.PlayerData): PlayerDataTemplate.PlayerData
	return PlayerDataTemplate.copy(data)
end

local function fire_data_changed(player: Player): ()
	local data = playerData[player]
	if not data or not dataChangedRemote then
		return
	end

	dataChangedRemote:FireClient(player, get_client_data(data))
end

local function send_notice(player: Player, message: string): ()
	if notifyRemote then
		notifyRemote:FireClient(player, {
			message = message,
		})
	end
end

local function save_player_data(player: Player): boolean
	local data = playerData[player]
	if not data then
		return false
	end

	local success = pcall(function()
		playerDataStore:SetAsync(get_data_key(player), data)
	end)

	if not success then
		warn("Data save failed for " .. player.Name)
	end

	return success
end

local function change_resource(data: PlayerDataTemplate.PlayerData, resourceName: string, amount: number): ()
	local currentValue = data.resources[resourceName] or 0
	data.resources[resourceName] = math.clamp(currentValue + amount, 0, GameConfig.RESOURCE_MAX)
end

local function can_pay_resource(data: PlayerDataTemplate.PlayerData, resourceName: string, amount: number): boolean
	if amount >= 0 then
		return true
	end

	local currentValue = data.resources[resourceName] or 0
	return currentValue + amount >= 0
end

local function add_player_exp(player: Player, data: PlayerDataTemplate.PlayerData, expGain: number): number
	local expResult = ExpFormula.add_exp(data.level, data.exp, expGain, GameConfig.LEVEL_CAP)

	data.level = expResult.level
	data.exp = expResult.exp

	if expResult.levelsGained > 0 then
		save_player_data(player)
	end

	return expResult.levelsGained
end

local function load_player_data(player: Player): PlayerDataTemplate.PlayerData
	local savedData = load_saved_data(player)
	local data = PlayerDataTemplate.merge(savedData)

	apply_daily_login(data)
	playerData[player] = data
	lastTrainAt[player] = 0
	apply_player_attributes(player, data)
	return data
end

local function get_player_data(player: Player): PlayerDataTemplate.PlayerData
	local data = playerData[player]
	if data then
		return data
	end

	return load_player_data(player)
end

local function set_world_data(data: PlayerDataTemplate.PlayerData, worldId: string): ()
	if worldId == "JJK" then
		data.jjk = {
			curseEnergy = 0,
		}
		data.naruto = nil
	elseif worldId == "Naruto" then
		data.naruto = {
			affinity = "",
			clan = "",
		}
		data.jjk = nil
	end
end

local function select_world(player: Player, worldId: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	local world = WorldDictionary.get_world(worldId)

	if data.world ~= "" then
		return {
			ok = false,
			message = "World already selected.",
			data = get_client_data(data),
		}
	end

	if not world then
		return {
			ok = false,
			message = "Unknown world.",
			data = get_client_data(data),
		}
	end

	if not world.active then
		return {
			ok = false,
			message = world.displayName .. " is prepared as a foundation slot.",
			data = get_client_data(data),
		}
	end

	data.world = world.id
	data.abilitiesUnlocked = AbilityDictionary.get_starting_abilities(world.id)
	data.abilitiesEquipped = AbilityDictionary.get_default_equipped(world.id)
	set_world_data(data, world.id)
	apply_player_attributes(player, data)
	fire_data_changed(player)
	save_player_data(player)

	return {
		ok = true,
		message = world.displayName .. " selected.",
		data = get_client_data(data),
	}
end

local function get_training_multiplier(data: PlayerDataTemplate.PlayerData): number
	local multiplier = 1
	if os.time() <= data.training.burstEndsAt then
		multiplier *= GameConfig.FOCUS_BURST_MULTIPLIER
	end

	if data.world == "JJK" and data.jjk and data.jjk.curseEnergy >= GameConfig.JJK_OVERFLOW_MIN then
		multiplier += GameConfig.JJK_OVERFLOW_EXP_BONUS
	end

	return multiplier
end

local function train_player(player: Player): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	local currentClock = os.clock()
	local currentTime = os.time()
	local lastTap = lastTrainAt[player] or 0

	if data.world == "" then
		return {
			ok = false,
			message = "Choose a world first.",
			data = get_client_data(data),
		}
	end

	if not can_pay_resource(data, "stamina", -GameConfig.CULTIVATE_STAMINA_COST) then
		return {
			ok = false,
			message = "Not enough stamina. Use Sleep.",
			data = get_client_data(data),
		}
	end

	if currentClock - lastTap < GameConfig.MIN_TRAIN_INTERVAL then
		return {
			ok = false,
			message = "Training too fast.",
			data = get_client_data(data),
		}
	end

	lastTrainAt[player] = currentClock
	data.training.totalTaps += 1
	data.training.focus += GameConfig.FOCUS_PER_TAP
	change_resource(data, "stamina", -GameConfig.CULTIVATE_STAMINA_COST)
	change_resource(data, "knowledge", GameConfig.CULTIVATE_KNOWLEDGE_GAIN)

	local burstTriggered = false
	if data.training.focus >= GameConfig.FOCUS_MAX then
		data.training.focus = 0
		data.training.burstEndsAt = currentTime + GameConfig.FOCUS_BURST_SECONDS
		burstTriggered = true
	end

	if data.world == "JJK" and data.jjk then
		data.jjk.curseEnergy = math.clamp(data.jjk.curseEnergy + GameConfig.JJK_CURSE_ENERGY_PER_TAP, 0, 100)
	end

	local expGain = math.floor(GameConfig.TRAIN_EXP_PER_TAP * get_training_multiplier(data))
	local levelsGained = add_player_exp(player, data, expGain)
	data.stats.atk += GameConfig.TRAIN_ATK_PER_TAP
	data.stats.def += GameConfig.TRAIN_DEF_PER_TAP

	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = burstTriggered and "Focus Burst!" or levelsGained > 0 and "Level up!" or "Cultivation gained.",
		data = get_client_data(data),
	}
end

local function battle_action(player: Player, actionName: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	if data.world == "" then
		return {
			ok = false,
			message = "Choose a world first.",
			data = get_client_data(data),
		}
	end

	if actionName == "Punch" and not can_pay_resource(data, "food", -1) then
		return {
			ok = false,
			message = "Not enough food.",
			data = get_client_data(data),
		}
	end

	if actionName == "Whack" and not can_pay_resource(data, "stamina", -1) then
		return {
			ok = false,
			message = "Not enough stamina.",
			data = get_client_data(data),
		}
	end

	local expGain = GameConfig.BATTLE_EXP_GAIN
	if actionName == "Punch" then
		change_resource(data, "food", -1)
		data.stats.atk += 0.5
	elseif actionName == "Whack" then
		change_resource(data, "stamina", -1)
		data.stats.atk += 0.25
		expGain += 4
	elseif actionName == "Block" then
		change_resource(data, "stamina", 1)
		data.stats.def += 0.4
		expGain -= 4
	else
		return {
			ok = false,
			message = "Unknown action.",
			data = get_client_data(data),
		}
	end

	if data.world == "JJK" and data.jjk then
		data.jjk.curseEnergy = math.clamp(data.jjk.curseEnergy + 1, 0, 100)
	end

	data.worldSouls += GameConfig.BATTLE_SOULS_GAIN
	data.progress.battleWins += 1
	add_player_exp(player, data, expGain)
	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = actionName .. " resolved.",
		data = get_client_data(data),
	}
end

local function quest_action(player: Player, questId: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	local quest = QuestDictionary.get_quest(questId)

	if data.world == "" then
		return {
			ok = false,
			message = "Choose a world first.",
			data = get_client_data(data),
		}
	end

	if not quest then
		return {
			ok = false,
			message = "Unknown quest.",
			data = get_client_data(data),
		}
	end

	if not quest.repeatable and table.find(data.storyQuests, quest.id) then
		return {
			ok = false,
			message = quest.displayName .. " already completed.",
			data = get_client_data(data),
		}
	end

	if not can_pay_resource(data, "stamina", quest.staminaChange) or not can_pay_resource(data, "food", quest.foodChange) then
		return {
			ok = false,
			message = "Not enough resources.",
			data = get_client_data(data),
		}
	end

	change_resource(data, "stamina", quest.staminaChange)
	change_resource(data, "food", quest.foodChange)
	change_resource(data, "knowledge", quest.knowledgeChange)

	data.worldSouls += quest.rewardSouls
	data.progress.questsCompleted += 1
	add_player_exp(player, data, quest.rewardExp)

	if not quest.repeatable then
		table.insert(data.storyQuests, quest.id)
		save_player_data(player)
	end

	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = quest.displayName .. " completed.",
		data = get_client_data(data),
	}
end

local function update_setting(player: Player, settingName: string, enabled: boolean): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	if typeof(data.settings[settingName]) ~= "boolean" then
		return {
			ok = false,
			message = "Unknown setting.",
			data = get_client_data(data),
		}
	end

	data.settings[settingName] = enabled == true
	fire_data_changed(player)

	return {
		ok = true,
		message = "Setting updated.",
		data = get_client_data(data),
	}
end

local function ensure_remotes(): ()
	remoteFolder = RemoteController.create_folder()
	getPlayerDataRemote = RemoteController.create_function(RemoteNames.getPlayerData)
	selectWorldRemote = RemoteController.create_function(RemoteNames.selectWorld)
	trainRemote = RemoteController.create_function(RemoteNames.train)
	battleActionRemote = RemoteController.create_function(RemoteNames.battleAction)
	questActionRemote = RemoteController.create_function(RemoteNames.questAction)
	updateSettingRemote = RemoteController.create_function(RemoteNames.updateSetting)
	dataChangedRemote = RemoteController.create_event(RemoteNames.dataChanged)
	notifyRemote = RemoteController.create_event(RemoteNames.notify)
end

------------------//MAIN FUNCTIONS
local function on_player_added(player: Player): ()
	load_player_data(player)
	fire_data_changed(player)
end

local function on_player_removing(player: Player): ()
	save_player_data(player)
	playerData[player] = nil
	lastTrainAt[player] = nil
end

local function connect_remotes(): ()
	(getPlayerDataRemote :: RemoteFunction).OnServerInvoke = function(player: Player)
		return get_client_data(get_player_data(player))
	end

	(selectWorldRemote :: RemoteFunction).OnServerInvoke = function(player: Player, worldId: string)
		local result = select_world(player, worldId)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end

	(trainRemote :: RemoteFunction).OnServerInvoke = function(player: Player)
		local result = train_player(player)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end

	(battleActionRemote :: RemoteFunction).OnServerInvoke = function(player: Player, actionName: string)
		local result = battle_action(player, actionName)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end

	(questActionRemote :: RemoteFunction).OnServerInvoke = function(player: Player, questId: string)
		local result = quest_action(player, questId)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end

	(updateSettingRemote :: RemoteFunction).OnServerInvoke = function(player: Player, settingName: string, enabled: boolean)
		local result = update_setting(player, settingName, enabled)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end
end

local function start_auto_save(): ()
	task.spawn(function()
		while true do
			task.wait(GameConfig.AUTO_SAVE_SECONDS)
			for player in playerData do
				save_player_data(player)
			end
		end
	end)
end

------------------//INIT
ensure_remotes()
connect_remotes()
start_auto_save()

for _, player in Players:GetPlayers() do
	on_player_added(player)
end

Players.PlayerAdded:Connect(on_player_added)
Players.PlayerRemoving:Connect(on_player_removing)

game:BindToClose(function()
	for player in playerData do
		save_player_data(player)
	end
end)

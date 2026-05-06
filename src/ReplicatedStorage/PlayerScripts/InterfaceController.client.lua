--!strict
------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService: RunService = game:GetService("RunService")

------------------//CONSTANTS
local MODULES_FOLDER_NAME: string = "Modules"

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local replicatedModules: Folder = ReplicatedStorage:WaitForChild(MODULES_FOLDER_NAME) :: Folder
local utilityModules: Folder = replicatedModules:WaitForChild("Utility") :: Folder
local dictionaryModules: Folder = replicatedModules:WaitForChild("Dictionary") :: Folder
local gameModules: Folder = replicatedModules:WaitForChild("Game") :: Folder

local ModuleCache = require(utilityModules:WaitForChild("ModuleCache") :: ModuleScript)
local RemoteNames = ModuleCache.require(utilityModules:WaitForChild("RemoteNames") :: ModuleScript)
local RemoteController = ModuleCache.require(utilityModules:WaitForChild("RemoteController") :: ModuleScript)
local UIDictionary = ModuleCache.require(dictionaryModules:WaitForChild("UIDictionary") :: ModuleScript)
local WorldDictionary = ModuleCache.require(dictionaryModules:WaitForChild("WorldDictionary") :: ModuleScript)
local ExpFormula = ModuleCache.require(gameModules:WaitForChild("ExpFormula") :: ModuleScript)
local GameConfig = ModuleCache.require(gameModules:WaitForChild("GameConfig") :: ModuleScript)
local FlipCard = ModuleCache.require(utilityModules:WaitForChild("FlipCard") :: ModuleScript)

local getPlayerDataRemote: RemoteFunction = RemoteController.get_function(RemoteNames.getPlayerData)
local selectWorldRemote: RemoteFunction = RemoteController.get_function(RemoteNames.selectWorld)
local trainRemote: RemoteFunction = RemoteController.get_function(RemoteNames.train)
local battleActionRemote: RemoteFunction = RemoteController.get_function(RemoteNames.battleAction)
local questActionRemote: RemoteFunction = RemoteController.get_function(RemoteNames.questAction)
local updateSettingRemote: RemoteFunction = RemoteController.get_function(RemoteNames.updateSetting)
local dataChangedRemote: RemoteEvent = RemoteController.get_event(RemoteNames.dataChanged)
local notifyRemote: RemoteEvent = RemoteController.get_event(RemoteNames.notify)

local hud: ScreenGui? = playerGui:WaitForChild(UIDictionary.screenGuiName, 10) :: ScreenGui?
local currentData: any = nil
local currentPage: string = UIDictionary.pages.options
local hasSelectedSave: boolean = false

------------------//FUNCTIONS
local function get_hud_child(childName: string): Instance?
	if not hud then return nil end
	return hud:FindFirstChild(childName, true)
end

local function get_label(labelName: string): TextLabel?
	local label = get_hud_child(labelName)
	if label and label:IsA("TextLabel") then return label end
	return nil
end

local function get_button(buttonName: string): GuiButton?
	local button = get_hud_child(buttonName)
	if button and button:IsA("GuiButton") then return button end
	return nil
end

local function set_label_text(labelName: string, text: string): ()
	local label = get_label(labelName)
	if label then label.Text = text end
end

local function set_notice(message: string): ()
	set_label_text(UIDictionary.labels.notice, message)
end

local function format_number(value: number): string
	if currentData and currentData.settings and currentData.settings.abbreviations then
		if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
		if value >= 1000 then return string.format("%.1fK", value / 1000) end
	end
	return tostring(math.floor(value))
end

local function format_bool(value: boolean): string
	return value and "ON" or "OFF"
end

local function invoke_remote(remote: RemoteFunction, ...): any
	local success, result = pcall(function(...)
		return remote:InvokeServer(...)
	end, ...)
	if not success then
		set_notice("Server request failed.")
		return nil
	end
	return result
end

local function show_screen(screenName: string): ()
	if not hud then return end

	local charSelection = hud:FindFirstChild("CharacterSelection")
	local root = hud:FindFirstChild("Root")

	if screenName == "CharacterSelection" then
		if charSelection then charSelection.Visible = true end
		if root then root.Visible = false end
	else
		if charSelection then charSelection.Visible = false end
		if root then 
			root.Visible = true 
			local main = root:FindFirstChild("Main")
			if main then main.Visible = true end
		end
	end
end

local function set_tab_selected(tabName: string, selected: boolean): ()
	local button = get_button(tabName)
	if button then
		button.BackgroundColor3 = selected and UIDictionary.colors.card or UIDictionary.colors.panel
		if button:IsA("ImageButton") then
			button.ImageColor3 = button.BackgroundColor3
		end
	end
end

local function show_page(pageName: string): ()
	currentPage = pageName
	for _, targetPageName in UIDictionary.pages do
		local page = get_hud_child(targetPageName)
		if page and page:IsA("GuiObject") then
			page.Visible = targetPageName == pageName
		end
	end
	set_tab_selected(UIDictionary.buttons.optionsTab,    pageName == UIDictionary.pages.options)
	set_tab_selected(UIDictionary.buttons.statsTab,      pageName == UIDictionary.pages.stats)
	set_tab_selected(UIDictionary.buttons.questsTab,     pageName == UIDictionary.pages.quests)
	set_tab_selected(UIDictionary.buttons.inventoryTab,  pageName == UIDictionary.pages.inventory)
	set_tab_selected(UIDictionary.buttons.guildTab,      pageName == UIDictionary.pages.guild)
	set_tab_selected(UIDictionary.buttons.shopTab,       pageName == UIDictionary.pages.shop)
	set_tab_selected(UIDictionary.buttons.miscTab,       pageName == UIDictionary.pages.misc)
	set_tab_selected(UIDictionary.buttons.settingsTab,   pageName == UIDictionary.pages.settings)
end

local function update_fill(fillName: string, value: number, maxValue: number): ()
	local fill = get_hud_child(fillName)
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.fromScale(math.clamp(value / maxValue, 0, 1), 1)
	end
end

local function get_rank_name(level: number): string
	if level >= 500 then return "Immortal" end
	if level >= 300 then return "Heaven Breaker" end
	if level >= 100 then return "Special Grade" end
	if level >= 50  then return "Grade 1" end
	return "Mortal IX"
end

local function get_mechanic_text(data: any): string
	if data.world == "JJK" and data.jjk then
		return "Cursed Energy: " .. tostring(math.floor(data.jjk.curseEnergy)) .. "%"
	end
	if data.world == "Naruto" and data.naruto then return "Chakra: Foundation" end
	return "No mechanic"
end

local function render_resources(data: any): ()
	local resources = data.resources or {}
	local stamina   = resources.stamina   or 0
	local food      = resources.food      or 0
	local knowledge = resources.knowledge or 0
	set_label_text(UIDictionary.labels.staminaValue,   "Stamina: "   .. format_number(stamina)   .. "/" .. tostring(GameConfig.RESOURCE_MAX))
	set_label_text(UIDictionary.labels.foodValue,      "Food: "      .. format_number(food)      .. "/" .. tostring(GameConfig.RESOURCE_MAX))
	set_label_text(UIDictionary.labels.knowledgeValue, "Knowledge: " .. format_number(knowledge) .. "/" .. tostring(GameConfig.RESOURCE_MAX))
	update_fill(UIDictionary.labels.staminaFill,   stamina,   GameConfig.RESOURCE_MAX)
	update_fill(UIDictionary.labels.foodFill,      food,      GameConfig.RESOURCE_MAX)
	update_fill(UIDictionary.labels.knowledgeFill, knowledge, GameConfig.RESOURCE_MAX)
end

local function render_save_cards(data: any): ()
	local world     = WorldDictionary.get_world(data.world)
	local worldName = world and world.displayName or "Unborn"
	local playtime  = data.progress and data.progress.playtimeSeconds or 0

	set_label_text(UIDictionary.labels.saveOneInfo,   "World: " .. worldName .. "\nCultivation: " .. get_rank_name(data.level) .. "\nPVP Battles Won: " .. tostring(data.progress.pvpWins) .. "\nQuests Completed: " .. tostring(data.progress.questsCompleted) .. "\nWorld Souls: " .. tostring(data.worldSouls) .. "\nPlaytime: " .. tostring(playtime))
	set_label_text(UIDictionary.labels.saveTwoInfo,   "World: Naruto\nCultivation: Mortal I\nStatus: Locked Foundation\nBuy Slot: Later")
	set_label_text(UIDictionary.labels.saveThreeInfo, "World: JJK\nCultivation: Mortal I\nStatus: Locked Slot\nBuy Slot: Later")
end

local function render_stats_page(data: any): ()
	local world       = WorldDictionary.get_world(data.world)
	local requiredExp = ExpFormula.get_required_exp(data.level)
	local focusValue  = data.training and data.training.focus or 0
	local stats       = data.stats
	local bloodline   = data.world == "JJK" and "Bloodline: Chosen Vessel | Clan: None" or "Bloodline: Unknown | Clan: None"

	set_label_text(UIDictionary.labels.worldValue,       world and world.displayName or "No World")
	set_label_text(UIDictionary.labels.levelValue,       "Level " .. tostring(data.level))
	set_label_text(UIDictionary.labels.expValue,         format_number(data.exp) .. " / " .. format_number(requiredExp) .. " EXP")
	set_label_text(UIDictionary.labels.focusValue,       tostring(math.floor(focusValue)) .. "% Focus")
	set_label_text(UIDictionary.labels.mechanicValue,    get_mechanic_text(data))
	set_label_text(UIDictionary.labels.cultivationValue, "Cultivation: " .. get_rank_name(data.level))
	set_label_text(UIDictionary.labels.ageValue,         "Age: 18 Years, 6 Months, 10 Days")
	set_label_text(UIDictionary.labels.lifespanValue,    "Lifespan: 100 Years, 4 Months, 2 Days")
	set_label_text(UIDictionary.labels.qiValue,          "Current Qi: " .. format_number(data.exp))
	set_label_text(UIDictionary.labels.qiNeededValue,    "Qi Needed: " .. format_number(requiredExp))
	set_label_text(UIDictionary.labels.manualValue,      "Current Manual: None")
	set_label_text(UIDictionary.labels.bloodlineValue,   bloodline)
	set_label_text(UIDictionary.labels.statsValue,       "Strength: " .. format_number(stats.atk) .. "\nVitality: " .. format_number(stats.hp) .. "\nSpeed: " .. format_number(stats.spd) .. "\nDefense: " .. format_number(stats.def) .. "\nLuck: " .. format_number(stats.luck))
	update_fill(UIDictionary.labels.focusFill, focusValue, 100)
end

local function render_quests_page(data: any): ()
	local QuestDictionaryLocal = require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
	local questProgress = data.progress and data.progress.questProgress or {}
	local claimedQuests = data.progress and data.progress.claimedQuests or {}

	for _, questId in QuestDictionaryLocal.order do
		local questDef = QuestDictionaryLocal.get_quest(questId)
		if not questDef then continue end

		local card = get_hud_child(questId .. "Card")
		if card then
			local currentProg = questProgress[questId] or 0
			local isClaimed = table.find(claimedQuests, questId) ~= nil

			local barFill = card:FindFirstChild("ProgressBar") and card.ProgressBar:FindFirstChild("ProgressFill")
			local progressTextLabel = card:FindFirstChild("ProgressBar") and card.ProgressBar:FindFirstChild("ProgressText")
			local actionBtn = card:FindFirstChild(questId .. "Button")

			-- Atualiza Barra
			if barFill and progressTextLabel then
				local ratio = math.clamp(currentProg / questDef.requiredProgress, 0, 1)
				barFill.Size = UDim2.fromScale(ratio, 1)
				progressTextLabel.Text = tostring(currentProg) .. " / " .. tostring(questDef.requiredProgress)
			end

			if actionBtn then
				local btnText = actionBtn:FindFirstChild("ButtonText")
				if isClaimed and not questDef.repeatable then
					actionBtn.BackgroundColor3 = UIDictionary.colors.disabled
					if btnText then btnText.Text = "COMPLETA" end
				elseif currentProg >= questDef.requiredProgress then
					actionBtn.BackgroundColor3 = UIDictionary.colors.gold
					if btnText then btnText.Text = "RESGATAR" end
				else
					actionBtn.BackgroundColor3 = UIDictionary.colors.darkButton
					if btnText then btnText.Text = "FAZER" end
				end
			end
		end
	end
end

local function render_inventory_page(data: any): ()
	local inventory = data.inventory or {}
	local items     = inventory.items    or {}
	local equipped  = inventory.equipped or {}

	set_label_text(UIDictionary.labels.inventoryValue, "Items Owned: " .. tostring(#items) .. "\nHead: " .. (equipped.head or "None") .. "\nNeck: " .. (equipped.neck or "None") .. "\nShirt: " .. (equipped.shirt or "None") .. "\nPants: " .. (equipped.pants or "None") .. "\nWeapon: " .. (equipped.weapon or "None"))
end

local function render_static_pages(data: any): ()
	set_label_text(UIDictionary.labels.guildValue,    "Guilds are prepared for party progression.\nJoin and create actions are placeholders.")
	set_label_text(UIDictionary.labels.shopValue,     "World Souls: " .. tostring(data.worldSouls) .. "\nDivine Tokens: " .. tostring(data.divineTokens) .. "\nProducts are placeholder only.")
	set_label_text(UIDictionary.labels.miscValue,     "#1  You\n#2  Future Rival\n#3  Empty Slot\n\nLeaderboard data will connect later.")
	set_label_text(UIDictionary.labels.settingsValue, "Abbreviations: " .. format_bool(data.settings.abbreviations) .. "\nHard Mode: " .. format_bool(data.settings.hardMode) .. "\nAuto Breakthrough: " .. format_bool(data.settings.autoBreakthrough))
end

local function render_data(data: any): ()
	currentData = data
	if not data then return end

	render_save_cards(data)
	render_resources(data)
	render_stats_page(data)
	render_quests_page(data)
	render_inventory_page(data)
	render_static_pages(data)

	if (data.world == nil or data.world == "") and not hasSelectedSave then
		show_screen("CharacterSelection")
	else
		show_screen("Main")
		show_page(currentPage)
	end
end

local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, _gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = input.Position
		local guis = playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)

		print("========================================")
		print("[RADAR DE CLIQUE] Você clicou nos seguintes elementos:")
		for i, gui in ipairs(guis) do
			print(" [" .. i .. "] -> " .. gui.Name .. " (" .. gui.ClassName .. ") | ZIndex: " .. tostring(gui.ZIndex) .. " | Active: " .. tostring(gui.Active))
		end
		print("========================================")
	end
end)

local function apply_remote_result(result: any): ()
	if not result then return end
	if result.message then set_notice(result.message) end
	if result.data    then render_data(result.data)   end
end

local function select_world(worldId: string): ()
	print("[DEBUG] Chamando select_world com o ID: " .. tostring(worldId))
	apply_remote_result(invoke_remote(selectWorldRemote, worldId))
end

local function run_train(): ()
	apply_remote_result(invoke_remote(trainRemote))
end

local function run_battle_action(actionName: string): ()
	apply_remote_result(invoke_remote(battleActionRemote, actionName))
end

local function run_quest(questId: string): ()
	apply_remote_result(invoke_remote(questActionRemote, questId))
end

local function toggle_setting(settingName: string): ()
	if not currentData or not currentData.settings then return end
	apply_remote_result(invoke_remote(updateSettingRemote, settingName, not currentData.settings[settingName]))
end

local function connect_button(buttonName: string, callback: () -> ()): ()
	local button = get_button(buttonName)
	if button then button.Activated:Connect(callback) end
end

local function connect_navigation(): ()
	connect_button(UIDictionary.buttons.optionsTab,   function() show_page(UIDictionary.pages.options)   end)
	connect_button(UIDictionary.buttons.statsTab,     function() show_page(UIDictionary.pages.stats)     end)
	connect_button(UIDictionary.buttons.questsTab,    function() show_page(UIDictionary.pages.quests)    end)
	connect_button(UIDictionary.buttons.inventoryTab, function() show_page(UIDictionary.pages.inventory) end)
	connect_button(UIDictionary.buttons.guildTab,     function() show_page(UIDictionary.pages.guild)     end)
	connect_button(UIDictionary.buttons.shopTab,      function() show_page(UIDictionary.pages.shop)      end)
	connect_button(UIDictionary.buttons.miscTab,      function() show_page(UIDictionary.pages.misc)      end)
	connect_button(UIDictionary.buttons.settingsTab,  function() show_page(UIDictionary.pages.settings)  end)
end

local function connect_actions(): ()
	if hud then
		FlipCard.setup("JJK",      "SAVE 3Card", hud)
		FlipCard.setup("Naruto",   "SAVE 2Card", hud)
		FlipCard.setup("Onepiece", "SAVE 1Card", hud)
	end

	-- Função auxiliar para empurrar a carta inteira para a frente e conectar o clique
	local function fix_zIndex_and_connect(buttonName: string, worldId: string)
		local btn = get_button(buttonName)
		if btn then
			local backCard = btn.Parent

			-- 1. Puxa o Fundo do Verso da Carta (Ex: SAVE 1Card)
			if backCard and backCard:IsA("GuiObject") then
				backCard.ZIndex = 900

				-- 2. Puxa TODOS os textos informativos (SaveOneInfoLabel, etc) para a frente do fundo
				for _, child in backCard:GetDescendants() do
					if child:IsA("GuiObject") then
						child.ZIndex = 905
					end
				end
			end

			-- 3. Puxa o Botão de Select para a frente de tudo para garantir o clique
			btn.ZIndex = 999

			-- 4. Puxa o texto de dentro do botão (Ex: "SELECT")
			for _, child in btn:GetDescendants() do
				if child:IsA("GuiObject") then
					child.ZIndex = 1000 
				end
			end

			-- Conecta a ação de trocar de tela
			btn.Activated:Connect(function()
				hasSelectedSave = true
				show_screen("Main") 
				select_world(worldId)
			end)
		end
	end

	-- Aplica a correção de camadas e conecta os 3 botões
	fix_zIndex_and_connect("SaveOneButton", "Onepiece")
	fix_zIndex_and_connect("SaveTwoButton", "Naruto")
	fix_zIndex_and_connect("SaveThreeButton", "JJK")
	
	local QuestDictionaryLocal = require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
	for _, questId in QuestDictionaryLocal.order do
		local btn = get_button(questId .. "Button")
		if btn then
			btn.Activated:Connect(function()
				run_quest(questId)
			end)
		end
	end
	connect_button(UIDictionary.buttons.cultivate, run_train)
	connect_button(UIDictionary.buttons.trophy, function()
		set_notice("Achievements will connect after leaderboard data.")
	end)
	connect_button(UIDictionary.buttons.punch,  function() run_battle_action("Punch") end)
	connect_button(UIDictionary.buttons.whack,  function() run_battle_action("Whack") end)
	connect_button(UIDictionary.buttons.block,  function() run_battle_action("Block") end)
	connect_button(UIDictionary.buttons.storyQuest,  function() run_quest("LookAround")   end)
	connect_button(UIDictionary.buttons.cryQuest,    function() run_quest("CryLoudly")    end)
	connect_button(UIDictionary.buttons.sleepQuest,  function() run_quest("Sleep")        end)
	connect_button(UIDictionary.buttons.wiggleQuest, function() run_quest("WiggleAround") end)
	connect_button(UIDictionary.buttons.guildJoin,   function() set_notice("Guild join is a placeholder.")             end)
	connect_button(UIDictionary.buttons.guildCreate, function() set_notice("Guild creation is a placeholder.")         end)
	connect_button(UIDictionary.buttons.shopReincarnate, function() set_notice("Shop products are not connected yet.") end)
	connect_button(UIDictionary.buttons.shopEarly,   function() set_notice("Early unlock is placeholder only.")        end)
	connect_button(UIDictionary.buttons.shopGift,    function() set_notice("Gift flow is placeholder only.")           end)
	connect_button(UIDictionary.buttons.miscLeaderboards, function() set_notice("Leaderboards are static for now.")    end)
	connect_button(UIDictionary.buttons.miscStats,   function() set_notice("Stats are shown on the Stats tab.")        end)
	connect_button(UIDictionary.buttons.miscCodes,   function() set_notice("Codes will connect to rewards later.")     end)
	connect_button(UIDictionary.buttons.miscConsole, function() set_notice("Console is disabled in the foundation build.") end)
	connect_button(UIDictionary.buttons.settingAbbreviations,    function() toggle_setting("abbreviations")    end)
	connect_button(UIDictionary.buttons.settingHardMode,         function() toggle_setting("hardMode")         end)
	connect_button(UIDictionary.buttons.settingAutoBreakthrough, function() toggle_setting("autoBreakthrough") end)
end

------------------//INIT
if not hud then
	warn("ChosenByGodHud not found. Run the StarterGui HUD builder first.")
	return
end

show_screen("CharacterSelection")

connect_navigation()
connect_actions()

dataChangedRemote.OnClientEvent:Connect(render_data)
notifyRemote.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) == "table" and payload.message then
		set_notice(payload.message)
	else
		set_notice(tostring(payload))
	end
end)

render_data(invoke_remote(getPlayerDataRemote))
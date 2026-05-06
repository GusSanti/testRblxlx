------------------//SERVICES
local StarterGui: StarterGui = game:GetService("StarterGui")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local MODULES_FOLDER_NAME: string = "Modules"

------------------//VARIABLES
local replicatedModules: Folder = ReplicatedStorage:WaitForChild(MODULES_FOLDER_NAME) :: Folder
local dictionaryModules: Folder = replicatedModules:WaitForChild("Dictionary") :: Folder
local utilityModules: Folder = replicatedModules:WaitForChild("Utility") :: Folder
local ModuleCache = require(utilityModules:WaitForChild("ModuleCache") :: ModuleScript)
local UIDictionary = ModuleCache.require(dictionaryModules:WaitForChild("UIDictionary") :: ModuleScript)

local DEFAULT_UI = {
	screenGuiName = "ChosenByGodHud",
	rootName = "Root",
	screens = {
		saveSelection = "SaveSelection",
		main = "Main",
	},
	pages = {
		options = "OptionsPage",
		stats = "StatsPage",
		quests = "QuestsPage",
		inventory = "InventoryPage",
		guild = "GuildPage",
		shop = "ShopPage",
		misc = "MiscPage",
		settings = "SettingsPage",
	},
	buttons = {
		saveOne = "SaveOneButton",
		saveTwo = "SaveTwoButton",
		saveThree = "SaveThreeButton",
		optionsTab = "OptionsTabButton",
		statsTab = "StatsTabButton",
		questsTab = "QuestsTabButton",
		inventoryTab = "InventoryTabButton",
		guildTab = "GuildTabButton",
		shopTab = "ShopTabButton",
		miscTab = "MiscTabButton",
		settingsTab = "SettingsTabButton",
		cultivate = "CultivateButton",
		trophy = "TrophyButton",
		punch = "PunchButton",
		whack = "WhackButton",
		block = "BlockButton",
		storyQuest = "StoryQuestButton",
		cryQuest = "CryQuestButton",
		sleepQuest = "SleepQuestButton",
		wiggleQuest = "WiggleQuestButton",
		guildJoin = "GuildJoinButton",
		guildCreate = "GuildCreateButton",
		shopReincarnate = "ShopReincarnateButton",
		shopEarly = "ShopEarlyButton",
		shopGift = "ShopGiftButton",
		miscLeaderboards = "MiscLeaderboardsButton",
		miscStats = "MiscStatsButton",
		miscCodes = "MiscCodesButton",
		miscConsole = "MiscConsoleButton",
		settingAbbreviations = "SettingAbbreviationsButton",
		settingHardMode = "SettingHardModeButton",
		settingAutoBreakthrough = "SettingAutoBreakthroughButton",
	},
	labels = {
		notice = "NoticeLabel",
		saveOneInfo = "SaveOneInfoLabel",
		saveTwoInfo = "SaveTwoInfoLabel",
		saveThreeInfo = "SaveThreeInfoLabel",
		worldValue = "WorldValue",
		levelValue = "LevelValue",
		expValue = "ExpValue",
		focusValue = "FocusValue",
		focusFill = "FocusFill",
		mechanicValue = "MechanicValue",
		cultivationValue = "CultivationValue",
		ageValue = "AgeValue",
		lifespanValue = "LifespanValue",
		qiValue = "QiValue",
		qiNeededValue = "QiNeededValue",
		manualValue = "ManualValue",
		bloodlineValue = "BloodlineValue",
		statsValue = "StatsValue",
		staminaValue = "StaminaValue",
		foodValue = "FoodValue",
		knowledgeValue = "KnowledgeValue",
		staminaFill = "StaminaFill",
		foodFill = "FoodFill",
		knowledgeFill = "KnowledgeFill",
		storyQuestStatus = "StoryQuestStatusLabel",
		repeatQuestStatus = "RepeatQuestStatusLabel",
		playerBattleStatus = "PlayerBattleStatusLabel",
		inventoryValue = "InventoryValue",
		guildValue = "GuildValue",
		shopValue = "ShopValue",
		miscValue = "MiscValue",
		settingsValue = "SettingsValue",
	},
	colors = {
		background = Color3.fromRGB(14, 17, 24),
		canvas = Color3.fromRGB(20, 24, 34),
		panel = Color3.fromRGB(28, 34, 46),
		card = Color3.fromRGB(36, 42, 56),
		line = Color3.fromRGB(118, 128, 150),
		text = Color3.fromRGB(246, 248, 255),
		whiteText = Color3.fromRGB(255, 255, 255),
		mutedText = Color3.fromRGB(172, 180, 198),
		darkButton = Color3.fromRGB(56, 63, 82),
		disabled = Color3.fromRGB(84, 90, 106),
		jjk = Color3.fromRGB(124, 72, 214),
		naruto = Color3.fromRGB(60, 132, 210),
		stamina = Color3.fromRGB(84, 194, 189),
		food = Color3.fromRGB(201, 91, 98),
		knowledge = Color3.fromRGB(197, 66, 181),
		blueAction = Color3.fromRGB(93, 129, 255),
		redAction = Color3.fromRGB(226, 88, 74),
		gold = Color3.fromRGB(232, 199, 72),
		warning = Color3.fromRGB(255, 96, 96),
	},
}

------------------//FUNCTIONS
local function apply_defaults(target: {[any]: any}, defaults: {[any]: any}): ()
	for key, value in defaults do
		if typeof(value) == "table" then
			if typeof(target[key]) ~= "table" then
				target[key] = {}
			end
			apply_defaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end
end

local function apply_dark_theme(): ()
	UIDictionary.colors = DEFAULT_UI.colors
end

local function set_properties(instance: Instance, properties: {[string]: any}): Instance
	for propertyName, propertyValue in properties do
		(instance :: any)[propertyName] = propertyValue
	end
	return instance
end

local function create_instance(className: string, properties: {[string]: any}, parent: Instance?): Instance
	local instance = Instance.new(className)
	set_properties(instance, properties)
	instance.Parent = parent
	return instance
end

local function add_stroke(parent: Instance, color: Color3, thickness: number): UIStroke
	return create_instance("UIStroke", {
		Color = color,
		Thickness = thickness,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent) :: UIStroke
end

local function create_frame(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3, visible: boolean): Frame
	local frame = create_instance("Frame", {
		Name = name,
		Position = position,
		Size = size,
		BackgroundColor3 = color,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Visible = visible,
	}, parent) :: Frame

	return frame
end

local function create_label(parent: Instance, name: string, text: string, position: UDim2, size: UDim2, textColor: Color3, font: Enum.Font, align: Enum.TextXAlignment): TextLabel
	return create_instance("TextLabel", {
		Name = name,
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = font,
		Text = text,
		TextColor3 = textColor,
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = align,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent) :: TextLabel
end

local function create_button(parent: Instance, name: string, text: string, position: UDim2, size: UDim2, color: Color3, textColor: Color3): ImageButton
	local button = create_instance("ImageButton", {
		Name = name,
		Position = position,
		Size = size,
		BackgroundColor3 = color,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Image = "",
		ImageColor3 = color,
		ScaleType = Enum.ScaleType.Stretch,
		AutoButtonColor = true,
	}, parent) :: ImageButton

	add_stroke(button, UIDictionary.colors.line, 2)
	create_label(button, "ButtonText", text, UDim2.fromScale(0.04, 0.12), UDim2.fromScale(0.92, 0.76), textColor, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	return button
end

local function create_panel(parent: Instance, name: string, position: UDim2, size: UDim2): Frame
	local panel = create_frame(parent, name, position, size, UIDictionary.colors.card, true)
	add_stroke(panel, UIDictionary.colors.line, 1)
	return panel
end

local function create_bar(parent: Instance, name: string, fillName: string, position: UDim2, size: UDim2, fillColor: Color3): Frame
	local bar = create_frame(parent, name, position, size, Color3.fromRGB(78, 85, 102), true)
	create_frame(bar, fillName, UDim2.fromScale(0, 0), UDim2.fromScale(0, 1), fillColor, true)
	return bar
end

local function create_resource_row(parent: Instance, labelName: string, fillName: string, title: string, y: number, fillColor: Color3): ()
	local row = create_panel(parent, title .. "Row", UDim2.fromScale(0.08, y), UDim2.fromScale(0.84, 0.16))
	create_label(row, labelName, title .. ": 0/10", UDim2.fromScale(0.08, 0.1), UDim2.fromScale(0.84, 0.5), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	create_bar(row, title .. "Bar", fillName, UDim2.fromScale(0.08, 0.67), UDim2.fromScale(0.84, 0.18), fillColor)
end

local function clear_existing_hud(): ()
	local existingHud = StarterGui:FindFirstChild(UIDictionary.screenGuiName)
	if existingHud then
		existingHud:Destroy()
	end
end

local function create_screen_gui(): ScreenGui
	return create_instance("ScreenGui", {
		Name = UIDictionary.screenGuiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5,
	}, StarterGui) :: ScreenGui
end

local function create_save_card(parent: Instance, title: string, labelName: string, buttonName: string, x: number, locked: boolean): ()
	create_label(parent, title .. "Title", title, UDim2.fromScale(x, 0.04), UDim2.fromScale(0.26, 0.08), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)

	local cardColor = locked and Color3.fromRGB(43, 47, 58) or UIDictionary.colors.card
	local card = create_panel(parent, title .. "Card", UDim2.fromScale(x, 0.16), UDim2.fromScale(0.26, 0.74))
	card.BackgroundColor3 = cardColor

	create_label(card, labelName, "World: Unborn\nCultivation: Mortal I\nPVP Battles Won: 0\nQuests Completed: 0\nWorld Souls: 0\nPlaytime: 0", UDim2.fromScale(0.08, 0.08), UDim2.fromScale(0.84, 0.62), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)

	local buttonText = locked and "LOCKED" or "SELECT"
	local buttonColor = locked and UIDictionary.colors.disabled or UIDictionary.colors.card
	create_button(card, buttonName, buttonText, UDim2.fromScale(0.18, 0.78), UDim2.fromScale(0.64, 0.12), buttonColor, locked and UIDictionary.colors.warning or UIDictionary.colors.text)
end

local function create_save_selection(root: Frame): ()
	local screen = create_frame(root, UIDictionary.screens.saveSelection, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.background, true)
	local container = create_panel(screen, "SaveContainer", UDim2.fromScale(0.12, 0.1), UDim2.fromScale(0.76, 0.82))

	create_save_card(container, "SAVE 1", UIDictionary.labels.saveOneInfo, UIDictionary.buttons.saveOne, 0.04, false)
	create_save_card(container, "SAVE 2", UIDictionary.labels.saveTwoInfo, UIDictionary.buttons.saveTwo, 0.37, true)
	create_save_card(container, "SAVE 3", UIDictionary.labels.saveThreeInfo, UIDictionary.buttons.saveThree, 0.7, true)
end

local function create_left_sidebar(main: Frame): ()
	local sidebar = create_frame(main, "Sidebar", UDim2.fromScale(0.025, 0.12), UDim2.fromScale(0.195, 0.84), UIDictionary.colors.canvas, true)

	local portrait = create_panel(sidebar, "PortraitPanel", UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.92, 0.43))
	create_label(portrait, UIDictionary.labels.worldValue, "No World", UDim2.fromScale(0.08, 0.08), UDim2.fromScale(0.84, 0.12), UIDictionary.colors.mutedText, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	create_label(portrait, UIDictionary.labels.levelValue, "Level 1", UDim2.fromScale(0.08, 0.78), UDim2.fromScale(0.84, 0.1), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	create_label(portrait, UIDictionary.labels.expValue, "0 / 0 EXP", UDim2.fromScale(0.08, 0.88), UDim2.fromScale(0.84, 0.08), UIDictionary.colors.mutedText, Enum.Font.GothamBold, Enum.TextXAlignment.Center)

	create_label(sidebar, "ItemsTitle", "Items", UDim2.fromScale(0.18, 0.46), UDim2.fromScale(0.64, 0.08), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	local items = create_panel(sidebar, "ItemsPanel", UDim2.fromScale(0.04, 0.54), UDim2.fromScale(0.92, 0.42))
	create_resource_row(items, UIDictionary.labels.staminaValue, UIDictionary.labels.staminaFill, "Stamina", 0.08, UIDictionary.colors.stamina)
	create_resource_row(items, UIDictionary.labels.foodValue, UIDictionary.labels.foodFill, "Food", 0.38, UIDictionary.colors.food)
	create_resource_row(items, UIDictionary.labels.knowledgeValue, UIDictionary.labels.knowledgeFill, "Knowledge", 0.68, UIDictionary.colors.knowledge)
end

local function create_top_tabs(main: Frame): ()
	local top = create_frame(main, "TopTabs", UDim2.fromScale(0.23, 0.045), UDim2.fromScale(0.745, 0.07), UIDictionary.colors.canvas, true)
	local tabs = {
		{name = UIDictionary.buttons.optionsTab, text = "OPTIONS"},
		{name = UIDictionary.buttons.statsTab, text = "STATS"},
		{name = UIDictionary.buttons.questsTab, text = "QUESTS"},
		{name = UIDictionary.buttons.inventoryTab, text = "INVENTORY"},
		{name = UIDictionary.buttons.guildTab, text = "GUILD"},
		{name = UIDictionary.buttons.shopTab, text = "SHOP"},
		{name = UIDictionary.buttons.miscTab, text = "MISC"},
		{name = UIDictionary.buttons.settingsTab, text = "SETTINGS"},
	}

	for index, tabInfo in tabs do
		local x = (index - 1) * 0.123
		create_button(top, tabInfo.name, tabInfo.text, UDim2.fromScale(x, 0.06), UDim2.fromScale(0.115, 0.82), UIDictionary.colors.panel, UIDictionary.colors.whiteText)
	end
end

local function create_options_page(content: Frame): ()
	local page = create_frame(content, UIDictionary.pages.options, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.canvas, true)
	local columns = {
		{title = "STORY", x = 0.02},
		{title = "REPEATABLES", x = 0.35},
		{title = "UPGRADES", x = 0.68},
	}

	for _, column in columns do
		create_label(page, column.title .. "OptionsTitle", column.title, UDim2.fromScale(column.x, 0.04), UDim2.fromScale(0.3, 0.08), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
		create_panel(page, column.title .. "OptionsPanel", UDim2.fromScale(column.x, 0.14), UDim2.fromScale(0.3, 0.8))
	end

	create_button(page, UIDictionary.buttons.storyQuest, "Look Around", UDim2.fromScale(0.05, 0.2), UDim2.fromScale(0.24, 0.12), UIDictionary.colors.darkButton, UIDictionary.colors.whiteText)
	create_button(page, UIDictionary.buttons.cryQuest, "Cry Loudly", UDim2.fromScale(0.38, 0.2), UDim2.fromScale(0.24, 0.12), UIDictionary.colors.darkButton, UIDictionary.colors.whiteText)
	create_button(page, UIDictionary.buttons.sleepQuest, "Sleep", UDim2.fromScale(0.38, 0.35), UDim2.fromScale(0.24, 0.12), UIDictionary.colors.darkButton, UIDictionary.colors.whiteText)
	create_button(page, UIDictionary.buttons.wiggleQuest, "Wiggle Around", UDim2.fromScale(0.38, 0.5), UDim2.fromScale(0.24, 0.12), Color3.fromRGB(124, 78, 78), UIDictionary.colors.whiteText)
	create_label(page, "UpgradeText", "Basic upgrades will attach here after battle tiers.", UDim2.fromScale(0.72, 0.24), UDim2.fromScale(0.22, 0.14), UIDictionary.colors.mutedText, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
end

local function create_stats_page(content: Frame): ()
	local page = create_frame(content, UIDictionary.pages.stats, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.canvas, false)
	create_label(page, "SilhouetteLabel", "SILHOUETTE", UDim2.fromScale(0.07, 0.12), UDim2.fromScale(0.4, 0.48), UIDictionary.colors.line, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)

	local info = create_frame(page, "StatsInfoPanel", UDim2.fromScale(0.53, 0.1), UDim2.fromScale(0.42, 0.32), UIDictionary.colors.canvas, true)
	create_label(info, UIDictionary.labels.cultivationValue, "Cultivation: Mortal IX", UDim2.fromScale(0.02, 0.02), UDim2.fromScale(0.96, 0.14), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	create_label(info, UIDictionary.labels.ageValue, "Age: 18 Years", UDim2.fromScale(0.02, 0.17), UDim2.fromScale(0.96, 0.13), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	create_label(info, UIDictionary.labels.lifespanValue, "Lifespan: 100 Years", UDim2.fromScale(0.02, 0.32), UDim2.fromScale(0.96, 0.13), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	create_label(info, UIDictionary.labels.qiValue, "Current Qi: 0", UDim2.fromScale(0.02, 0.47), UDim2.fromScale(0.96, 0.13), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	create_label(info, UIDictionary.labels.qiNeededValue, "Qi Needed: 0", UDim2.fromScale(0.02, 0.62), UDim2.fromScale(0.96, 0.13), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	create_label(info, UIDictionary.labels.manualValue, "Current Manual: None", UDim2.fromScale(0.02, 0.77), UDim2.fromScale(0.96, 0.13), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)

	create_button(page, UIDictionary.buttons.cultivate, "CULTIVATE", UDim2.fromScale(0.54, 0.46), UDim2.fromScale(0.35, 0.09), UIDictionary.colors.card, UIDictionary.colors.blueAction)
	create_button(page, UIDictionary.buttons.trophy, "ACH", UDim2.fromScale(0.91, 0.46), UDim2.fromScale(0.08, 0.09), UIDictionary.colors.card, UIDictionary.colors.blueAction)
	create_bar(page, "FocusBar", UIDictionary.labels.focusFill, UDim2.fromScale(0.54, 0.57), UDim2.fromScale(0.35, 0.035), UIDictionary.colors.blueAction)
	create_label(page, UIDictionary.labels.focusValue, "0% Focus", UDim2.fromScale(0.9, 0.56), UDim2.fromScale(0.09, 0.05), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
	create_label(page, UIDictionary.labels.mechanicValue, "No mechanic", UDim2.fromScale(0.54, 0.61), UDim2.fromScale(0.42, 0.05), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	create_label(page, UIDictionary.labels.bloodlineValue, "Bloodline: None | Clan: None", UDim2.fromScale(0.32, 0.67), UDim2.fromScale(0.64, 0.06), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)

	local statsPanel = create_panel(page, "StatsReadoutPanel", UDim2.fromScale(0.04, 0.76), UDim2.fromScale(0.43, 0.18))
	create_label(statsPanel, UIDictionary.labels.statsValue, "Strength: 0\nVitality: 0\nSpeed: 0\nDefense: 0", UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.92, 0.84), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Left)

	local actionPanel = create_panel(page, "BattleActionPanel", UDim2.fromScale(0.53, 0.76), UDim2.fromScale(0.43, 0.18))
	create_button(actionPanel, UIDictionary.buttons.punch, "Punch", UDim2.fromScale(0.07, 0.12), UDim2.fromScale(0.38, 0.32), UIDictionary.colors.card, UIDictionary.colors.text)
	create_button(actionPanel, UIDictionary.buttons.whack, "Whack", UDim2.fromScale(0.55, 0.12), UDim2.fromScale(0.38, 0.32), UIDictionary.colors.card, UIDictionary.colors.text)
	create_button(actionPanel, UIDictionary.buttons.block, "Block", UDim2.fromScale(0.31, 0.56), UDim2.fromScale(0.38, 0.32), UIDictionary.colors.card, UIDictionary.colors.text)
end

local function create_quest_card(parent: Instance, questDef: any, yPos: number): ()
	local card = create_panel(parent, questDef.id .. "Card", UDim2.fromScale(0.05, yPos), UDim2.fromScale(0.9, 0.22))

	-- Nome da Quest
	create_label(card, "Title", questDef.displayName, UDim2.fromScale(0.05, 0.08), UDim2.fromScale(0.9, 0.25), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Left)

	-- Recompensas (Minimalista)
	local rewardsText = "Rewards: " .. tostring(questDef.rewardExp) .. " EXP | " .. tostring(questDef.rewardSouls) .. " Souls"
	create_label(card, "Rewards", rewardsText, UDim2.fromScale(0.05, 0.35), UDim2.fromScale(0.9, 0.2), UIDictionary.colors.mutedText, Enum.Font.Gotham, Enum.TextXAlignment.Left)

	-- Barra de Progresso
	local bar = create_bar(card, "ProgressBar", "ProgressFill", UDim2.fromScale(0.05, 0.65), UDim2.fromScale(0.6, 0.18), UIDictionary.colors.blueAction)
	create_label(bar, "ProgressText", "0 / " .. tostring(questDef.requiredProgress), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.whiteText, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)

	-- Botão de Ação / Resgate usando o ID exato da quest
	create_button(card, questDef.id .. "Button", "Ação", UDim2.fromScale(0.7, 0.55), UDim2.fromScale(0.25, 0.35), UIDictionary.colors.darkButton, UIDictionary.colors.whiteText)
end

local function create_quests_page(content: Frame): ()
	local page = create_frame(content, UIDictionary.pages.quests, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.canvas, false)
	local columns = {
		{title = "STORY QUESTS", x = 0.02, type = "Story"},
		{title = "SECT QUESTS", x = 0.35, type = "Repeatable"},
		{title = "PLAYER BATTLES", x = 0.68, type = "PVP"},
	}

	local panels = {}
	for _, column in columns do
		create_label(page, column.title .. "Title", column.title, UDim2.fromScale(column.x, 0.04), UDim2.fromScale(0.3, 0.08), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
		panels[column.type] = create_panel(page, column.title .. "Panel", UDim2.fromScale(column.x, 0.14), UDim2.fromScale(0.3, 0.8))
	end

	-- Lê dinamicamente o QuestDictionary e cria as UIs
	local storyY, repeatY = 0.02, 0.02
	local QuestDictionary = require(game.ReplicatedStorage.Modules.Dictionary.QuestDictionary) -- Ajuste o caminho se necessário

	for _, questId in QuestDictionary.order do
		local quest = QuestDictionary.get_quest(questId)
		if quest then
			if quest.questType == "Story" then
				create_quest_card(panels["Story"], quest, storyY)
				storyY += 0.24
			elseif quest.questType == "Repeatable" then
				create_quest_card(panels["Repeatable"], quest, repeatY)
				repeatY += 0.24
			end
		end
	end

	create_label(panels["PVP"], UIDictionary.labels.playerBattleStatus, "Select a Player", UDim2.fromScale(0.05, 0.05), UDim2.fromScale(0.9, 0.06), UIDictionary.colors.warning, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
end

local function create_inventory_page(content: Frame): ()
	local page = create_frame(content, UIDictionary.pages.inventory, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.canvas, false)
	create_frame(page, "InventoryHeader", UDim2.fromScale(0.02, 0.03), UDim2.fromScale(0.96, 0.13), Color3.fromRGB(39, 55, 76), true)
	create_label(page, "InventoryTitle", "INVENTORY", UDim2.fromScale(0.04, 0.045), UDim2.fromScale(0.4, 0.1), UIDictionary.colors.whiteText, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)

	local equipped = create_panel(page, "EquippedPanel", UDim2.fromScale(0.02, 0.2), UDim2.fromScale(0.28, 0.7))
	create_label(equipped, "EquippedTitle", "Equipped Items", UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.08), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	create_label(equipped, "AvatarPreview", "PLAYER\nPREVIEW", UDim2.fromScale(0.12, 0.18), UDim2.fromScale(0.76, 0.34), UIDictionary.colors.line, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	create_label(equipped, UIDictionary.labels.inventoryValue, "Items Owned: 0", UDim2.fromScale(0.08, 0.56), UDim2.fromScale(0.84, 0.38), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Left)

	create_label(page, "InventorySearch", "SEARCH ITEM HERE", UDim2.fromScale(0.34, 0.2), UDim2.fromScale(0.6, 0.06), UIDictionary.colors.mutedText, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	create_panel(page, "InventoryGrid", UDim2.fromScale(0.34, 0.28), UDim2.fromScale(0.6, 0.62))
end

local function create_guild_page(content: Frame): ()
	local page = create_frame(content, UIDictionary.pages.guild, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.canvas, false)
	create_label(page, "GuildTitle", "~ GUILD ~", UDim2.fromScale(0.05, 0.12), UDim2.fromScale(0.35, 0.1), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	create_label(page, UIDictionary.labels.guildValue, "Guilds are prepared.", UDim2.fromScale(0.05, 0.25), UDim2.fromScale(0.55, 0.18), UIDictionary.colors.text, Enum.Font.Gotham, Enum.TextXAlignment.Left)
	create_label(page, "GuildIcon", "GROUP", UDim2.fromScale(0.68, 0.14), UDim2.fromScale(0.22, 0.22), UIDictionary.colors.jjk, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	create_button(page, UIDictionary.buttons.guildJoin, "JOIN A GUILD", UDim2.fromScale(0.1, 0.55), UDim2.fromScale(0.8, 0.12), UIDictionary.colors.card, UIDictionary.colors.blueAction)
	create_button(page, UIDictionary.buttons.guildCreate, "CREATE A GUILD", UDim2.fromScale(0.1, 0.73), UDim2.fromScale(0.8, 0.12), UIDictionary.colors.card, UIDictionary.colors.redAction)
end

local function create_shop_page(content: Frame): ()
	local page = create_frame(content, UIDictionary.pages.shop, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.canvas, false)
	create_label(page, "ShopTitle", "~ SHOP ~", UDim2.fromScale(0.05, 0.08), UDim2.fromScale(0.3, 0.08), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	create_label(page, "ShopTabs", "ROBUX        SF        KP        GIFTS", UDim2.fromScale(0.08, 0.18), UDim2.fromScale(0.84, 0.08), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	create_label(page, UIDictionary.labels.shopValue, "Products are placeholder only.", UDim2.fromScale(0.14, 0.28), UDim2.fromScale(0.72, 0.08), UIDictionary.colors.text, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	create_button(page, UIDictionary.buttons.shopReincarnate, "REINCARNATE\n99 ROBUX\nBUY", UDim2.fromScale(0.08, 0.42), UDim2.fromScale(0.26, 0.34), UIDictionary.colors.card, UIDictionary.colors.redAction)
	create_button(page, UIDictionary.buttons.shopEarly, "EARLY SECT & AFFINITY\n499 ROBUX\nBUY", UDim2.fromScale(0.38, 0.42), UDim2.fromScale(0.34, 0.34), UIDictionary.colors.card, UIDictionary.colors.redAction)
	create_button(page, UIDictionary.buttons.shopGift, "GIFT", UDim2.fromScale(0.74, 0.58), UDim2.fromScale(0.18, 0.12), UIDictionary.colors.card, UIDictionary.colors.gold)
end

local function create_misc_page(content: Frame): ()
	local page = create_frame(content, UIDictionary.pages.misc, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.canvas, false)
	local menu = create_panel(page, "MiscMenu", UDim2.fromScale(0.02, 0.04), UDim2.fromScale(0.22, 0.9))
	create_button(menu, UIDictionary.buttons.miscLeaderboards, "LEADERBOARDS", UDim2.fromScale(0, 0.25), UDim2.fromScale(1, 0.11), UIDictionary.colors.card, UIDictionary.colors.text)
	create_button(menu, UIDictionary.buttons.miscStats, "STATS", UDim2.fromScale(0, 0.38), UDim2.fromScale(1, 0.11), UIDictionary.colors.card, UIDictionary.colors.text)
	create_button(menu, UIDictionary.buttons.miscCodes, "CODES", UDim2.fromScale(0, 0.51), UDim2.fromScale(1, 0.11), UIDictionary.colors.card, UIDictionary.colors.text)
	create_button(menu, UIDictionary.buttons.miscConsole, "CONSOLE", UDim2.fromScale(0, 0.64), UDim2.fromScale(1, 0.11), UIDictionary.colors.card, UIDictionary.colors.text)

	create_frame(page, "MiscHeader", UDim2.fromScale(0.27, 0.04), UDim2.fromScale(0.68, 0.13), Color3.fromRGB(39, 55, 76), true)
	create_label(page, "MiscTitle", "MISC", UDim2.fromScale(0.29, 0.055), UDim2.fromScale(0.3, 0.1), UIDictionary.colors.whiteText, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	create_label(page, "LeaderboardTabs", "CULTIVATION   SOUL FRAGS   TOP SPENDER   QUESTS DONE", UDim2.fromScale(0.29, 0.2), UDim2.fromScale(0.64, 0.07), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	create_panel(page, "LeaderboardPanel", UDim2.fromScale(0.29, 0.31), UDim2.fromScale(0.64, 0.56))
	create_label(page, UIDictionary.labels.miscValue, "#1  You\n#2  Future Rival\n#3  Empty Slot", UDim2.fromScale(0.33, 0.36), UDim2.fromScale(0.56, 0.4), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
end

local function create_settings_page(content: Frame): ()
	local page = create_frame(content, UIDictionary.pages.settings, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.canvas, false)
	local menu = create_panel(page, "SettingsMenu", UDim2.fromScale(0.02, 0.04), UDim2.fromScale(0.22, 0.9))
	create_label(menu, "GameplayTab", "GAMEPLAY", UDim2.fromScale(0, 0.28), UDim2.fromScale(1, 0.1), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	create_label(menu, "VisualsTab", "VISUALS", UDim2.fromScale(0, 0.4), UDim2.fromScale(1, 0.1), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	create_label(menu, "SoundsTab", "SOUNDS", UDim2.fromScale(0, 0.52), UDim2.fromScale(1, 0.1), UIDictionary.colors.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	create_label(menu, "PerformanceTab", "HIGH PERFORMANCE", UDim2.fromScale(0, 0.64), UDim2.fromScale(1, 0.08), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)

	create_frame(page, "SettingsHeader", UDim2.fromScale(0.27, 0.04), UDim2.fromScale(0.68, 0.13), Color3.fromRGB(39, 55, 76), true)
	create_label(page, "SettingsTitle", "SETTINGS", UDim2.fromScale(0.29, 0.055), UDim2.fromScale(0.4, 0.1), UIDictionary.colors.whiteText, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	local settingsPanel = create_panel(page, "SettingsPanel", UDim2.fromScale(0.28, 0.22), UDim2.fromScale(0.66, 0.65))
	create_button(settingsPanel, UIDictionary.buttons.settingAbbreviations, "Abbreviations", UDim2.fromScale(0.34, 0.1), UDim2.fromScale(0.32, 0.12), UIDictionary.colors.card, UIDictionary.colors.text)
	create_button(settingsPanel, UIDictionary.buttons.settingHardMode, "Hard Mode", UDim2.fromScale(0.34, 0.34), UDim2.fromScale(0.32, 0.12), UIDictionary.colors.card, UIDictionary.colors.text)
	create_button(settingsPanel, UIDictionary.buttons.settingAutoBreakthrough, "Auto Breakthrough", UDim2.fromScale(0.34, 0.58), UDim2.fromScale(0.32, 0.12), UIDictionary.colors.card, UIDictionary.colors.text)
	create_label(settingsPanel, UIDictionary.labels.settingsValue, "Abbreviations: OFF\nHard Mode: OFF\nAuto Breakthrough: OFF", UDim2.fromScale(0.1, 0.76), UDim2.fromScale(0.8, 0.16), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
end

local function create_main(root: Frame): ()
	local main = create_frame(root, UIDictionary.screens.main, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.background, false)
	create_left_sidebar(main)
	create_top_tabs(main)

	local content = create_frame(main, "Content", UDim2.fromScale(0.23, 0.13), UDim2.fromScale(0.745, 0.83), UIDictionary.colors.canvas, true)
	create_options_page(content)
	create_stats_page(content)
	create_quests_page(content)
	create_inventory_page(content)
	create_guild_page(content)
	create_shop_page(content)
	create_misc_page(content)
	create_settings_page(content)
end

------------------//MAIN FUNCTIONS
local function create_hud(): ()
	clear_existing_hud()

	local screenGui = create_screen_gui()
	local root = create_frame(screenGui, UIDictionary.rootName, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), UIDictionary.colors.background, true)

	create_label(root, UIDictionary.labels.notice, "Foundation build ready.", UDim2.fromScale(0.02, 0.965), UDim2.fromScale(0.6, 0.03), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
	create_label(root, "VersionLabel", "VERSION - FOUNDATION TEST", UDim2.fromScale(0.78, 0.965), UDim2.fromScale(0.2, 0.03), UIDictionary.colors.text, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
	create_save_selection(root)
	create_main(root)
end

------------------//INIT
apply_defaults(UIDictionary, DEFAULT_UI)
apply_dark_theme()
create_hud()
print("ChosenByGodHud dark placeholder created in StarterGui.")

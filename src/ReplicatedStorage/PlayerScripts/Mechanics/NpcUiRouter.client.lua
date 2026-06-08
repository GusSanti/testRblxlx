------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService: ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui: StarterGui = game:GetService("StarterGui")
local TextChatService: TextChatService = game:GetService("TextChatService")

------------------//CONSTANTS
local PagesClientService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("PagesClientService"))

local NPCS_FOLDER_NAME = "Npcs"
local DEBUG_PREFIX = "[NpcUi]"
local OPEN_COOLDOWN = 0.25

type NpcUiConfig = {
	pageName: string?,
	screenGuiName: string,
	openPath: { string },
	closePaths: { { string } }?,
	bindableEventName: string?,
}

local NPC_UI_CONFIG: { [string]: NpcUiConfig } = {
	Shop = {
		pageName = "Shop",
		screenGuiName = "Lobby",
		openPath = {},
	},
	["Kash bxnds"] = {
		screenGuiName = "CharacterCreatorGui",
		openPath = {},
		bindableEventName = "OpenFromNpc",
	},
	["Kash Bxnds"] = {
		screenGuiName = "CharacterCreatorGui",
		openPath = {},
		bindableEventName = "OpenFromNpc",
	},
}

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Warn = Color3.fromRGB(255, 218, 120),
	Error = Color3.fromRGB(255, 135, 135),
}

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local lastOpenAtByNpcName: { [string]: number } = {}
local warnedMissingNpcsFolder = false

------------------//FUNCTIONS
local function get_chat_color(colorName: string?): Color3
	if colorName and CHAT_COLORS[colorName] then
		return CHAT_COLORS[colorName]
	end

	return CHAT_COLORS.Info
end

local function try_system_message(text: string, colorName: string?): boolean
	local textChannels = TextChatService:FindFirstChild("TextChannels")
	local generalChannel = textChannels and textChannels:FindFirstChild("RBXGeneral")

	if generalChannel and generalChannel:IsA("TextChannel") then
		generalChannel:DisplaySystemMessage(text)
		return true
	end

	local success = pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = text,
			Color = get_chat_color(colorName),
		})
	end)

	return success
end

local function send_debug(message: string, colorName: string?): ()
	local text = DEBUG_PREFIX .. " " .. message

	if try_system_message(text, colorName) then
		return
	end

	task.spawn(function()
		local attempts = 0

		while attempts < 10 do
			attempts += 1
			task.wait(0.5)

			if try_system_message(text, colorName) then
				return
			end
		end
	end)
end

local function get_npcs_folder(): Instance?
	local folder = workspace:FindFirstChild(NPCS_FOLDER_NAME)

	if folder then
		warnedMissingNpcsFolder = false
		return folder
	end

	if not warnedMissingNpcsFolder then
		warnedMissingNpcsFolder = true
		send_debug("workspace." .. NPCS_FOLDER_NAME .. " nao encontrado.", "Warn")
	end

	return nil
end

local function resolve_path(root: Instance, path: { string }): Instance?
	local current: Instance? = root

	for _, segment in path do
		if not current then
			return nil
		end

		current = current:FindFirstChild(segment)
	end

	return current
end

local function set_instance_visible(instance: Instance, visible: boolean): ()
	if instance:IsA("GuiObject") then
		instance.Visible = visible
		return
	end

	if instance:IsA("ScreenGui") then
		instance.Enabled = visible
	end
end

local function open_ui_for_npc(npcName: string, config: NpcUiConfig): ()
	if config.pageName and config.pageName ~= "" then
		PagesClientService.open_page(config.pageName)
		send_debug("NPC " .. npcName .. " abriu page " .. config.pageName .. ".", "Info")
		return
	end

	local screenGui = playerGui:FindFirstChild(config.screenGuiName)

	if not screenGui or not screenGui:IsA("ScreenGui") then
		send_debug("ScreenGui '" .. config.screenGuiName .. "' nao encontrado para NPC " .. npcName .. ".", "Error")
		return
	end

	screenGui.Enabled = true

	if config.bindableEventName and config.bindableEventName ~= "" then
		local bindable = screenGui:FindFirstChild(config.bindableEventName)

		if bindable and bindable:IsA("BindableEvent") then
			bindable:Fire()
			send_debug("NPC " .. npcName .. " abriu UI via evento.", "Info")
			return
		end

		send_debug("BindableEvent '" .. config.bindableEventName .. "' nao encontrado para NPC " .. npcName .. ".", "Error")
		return
	end

	if config.closePaths then
		for _, closePath in config.closePaths do
			local closeTarget = resolve_path(screenGui, closePath)

			if closeTarget then
				set_instance_visible(closeTarget, false)
			end
		end
	end

	local openTarget = resolve_path(screenGui, config.openPath)

	if not openTarget then
		send_debug("Path de UI nao encontrado para NPC " .. npcName .. ".", "Error")
		return
	end

	set_instance_visible(openTarget, true)
	send_debug("NPC " .. npcName .. " abriu UI.", "Info")
end

local function get_npc_name_for_prompt(prompt: ProximityPrompt): string?
	local npcsFolder = get_npcs_folder()

	if not npcsFolder then
		return nil
	end

	if not prompt:IsDescendantOf(npcsFolder) then
		return nil
	end

	local cursor: Instance? = prompt

	while cursor and cursor ~= npcsFolder do
		if NPC_UI_CONFIG[cursor.Name] then
			return cursor.Name
		end

		cursor = cursor.Parent
	end

	return nil
end

local function can_open_now(npcName: string): boolean
	local now = os.clock()
	local lastOpenAt = lastOpenAtByNpcName[npcName] or 0

	if now - lastOpenAt < OPEN_COOLDOWN then
		return false
	end

	lastOpenAtByNpcName[npcName] = now
	return true
end

local function on_prompt_triggered(prompt: ProximityPrompt): ()
	local npcName = get_npc_name_for_prompt(prompt)

	if not npcName then
		return
	end

	local config = NPC_UI_CONFIG[npcName]

	if not config then
		return
	end

	if not can_open_now(npcName) then
		return
	end

	open_ui_for_npc(npcName, config)
end

------------------//MAIN FUNCTIONS
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, _extra: any)
	on_prompt_triggered(prompt)
end)

------------------//INIT
send_debug("Router iniciado.", "Info")

------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui: StarterGui = game:GetService("StarterGui")
local TextChatService: TextChatService = game:GetService("TextChatService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local ItemsDataDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("ItemsDataDictionary"))
local PagesClientService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("PagesClientService"))

local modulesFolder: Folder = ReplicatedStorage:WaitForChild("Modules") :: Folder
local utilityFolder: Folder = modulesFolder:WaitForChild("Utility") :: Folder
local DataUtility = require(utilityFolder:WaitForChild("DataUtility"))

local EQUIPPED_COLOR = Color3.fromRGB(255, 235, 160)
local NORMAL_COLOR = Color3.fromRGB(255, 255, 255)
local DEBUG_PREFIX = "[InventoryHud]"
local INVENTORY_PAGE_NAME = "Inventory"

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Warn = Color3.fromRGB(255, 218, 120),
	Error = Color3.fromRGB(255, 135, 135),
}

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local lobbyGui: ScreenGui = playerGui:WaitForChild("Lobby") :: ScreenGui
local pagesGui: ScreenGui = playerGui:WaitForChild("Pages") :: ScreenGui

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local inventoryRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.INVENTORY_REMOTE_EVENT_NAME) :: RemoteEvent

local inventoryPage: GuiObject? = nil
local inventoryContainer: GuiObject? = nil
local inventoryTemplate: GuiObject? = nil
local inventoryToggleButton: GuiButton? = nil
local inventoryVisible = false

local bindWeaponsConnection: { Disconnect: (self: any) -> () }? = nil
local bindEquippedConnection: { Disconnect: (self: any) -> () }? = nil
local lastRenderSignature = ""

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

local function has_weapon(weapons: { string }, weaponName: string): boolean
	for _, ownedWeaponName in weapons do
		if ownedWeaponName == weaponName then
			return true
		end
	end

	return false
end

local function normalize_owned_weapons(rawWeapons: any): { string }
	local validOwnedSet: { [string]: boolean } = {}

	if typeof(rawWeapons) == "table" then
		for _, value in rawWeapons do
			if typeof(value) == "string" and ItemsDataDictionary.is_valid_weapon(value) then
				validOwnedSet[value] = true
			end
		end
	end

	validOwnedSet[ItemsDataDictionary.DEFAULT_WEAPON] = true

	local normalized: { string } = {}
	local orderedWeapons = ItemsDataDictionary.get_weapon_names()

	for _, weaponName in orderedWeapons do
		if validOwnedSet[weaponName] then
			table.insert(normalized, weaponName)
		end
	end

	return normalized
end

local function get_equipped_weapon(ownedWeapons: { string }): string
	local equippedWeapon = DataUtility.client.get("EquippedWeapon")

	if typeof(equippedWeapon) == "string" and has_weapon(ownedWeapons, equippedWeapon) then
		return equippedWeapon
	end

	return ItemsDataDictionary.DEFAULT_WEAPON
end

local function is_inventory_panel_candidate(instance: Instance?): boolean
	if not instance or not instance:IsA("GuiObject") then
		return false
	end

	local template = instance:FindFirstChild("Template")
	if template and (template:IsA("TextButton") or template:IsA("TextLabel")) then
		return true
	end

	local holder = instance:FindFirstChild("Holder")
	if not holder or not holder:IsA("GuiObject") then
		return false
	end

	local holderTemplate = holder:FindFirstChild("Template")

	if not holderTemplate then
		return false
	end

	return holderTemplate:IsA("TextButton") or holderTemplate:IsA("TextLabel")
end

local function find_inventory_page(): GuiObject?
	local pageInventory = pagesGui:FindFirstChild("Inventory")

	if is_inventory_panel_candidate(pageInventory) then
		return pageInventory :: GuiObject
	end

	local pageInventario = pagesGui:FindFirstChild("Inventario")

	if is_inventory_panel_candidate(pageInventario) then
		return pageInventario :: GuiObject
	end

	local directInventario = lobbyGui:FindFirstChild("Inventario")

	if is_inventory_panel_candidate(directInventario) then
		return directInventario :: GuiObject
	end

	local directInventory = lobbyGui:FindFirstChild("Inventory")

	if is_inventory_panel_candidate(directInventory) then
		return directInventory :: GuiObject
	end

	for _, descendant in lobbyGui:GetDescendants() do
		if (descendant.Name == "Inventario" or descendant.Name == "Inventory") and is_inventory_panel_candidate(descendant) then
			return descendant :: GuiObject
		end
	end

	return nil
end

local function find_inventory_toggle_button(): GuiButton?
	local holder = lobbyGui:FindFirstChild("Holder")

	if holder then
		local holderInventory = holder:FindFirstChild("Inventory")

		if holderInventory and holderInventory:IsA("GuiButton") then
			return holderInventory
		end

		local holderInventario = holder:FindFirstChild("Inventario")

		if holderInventario and holderInventario:IsA("GuiButton") then
			return holderInventario
		end
	end

	return nil
end

local function set_inventory_visible(visible: boolean): ()
	if visible then
		PagesClientService.open_page(INVENTORY_PAGE_NAME)
		return
	end

	PagesClientService.close_page(INVENTORY_PAGE_NAME)
end

local function clear_inventory_rows(): ()
	local container = inventoryContainer
	local template = inventoryTemplate

	if not container or not template then
		return
	end

	for _, child in container:GetChildren() do
		if child ~= template and not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
end

local function connect_weapon_activate(row: GuiObject, weaponName: string): ()
	if row:IsA("GuiButton") then
		row.Activated:Connect(function()
			inventoryRemote:FireServer("Equip", weaponName)
		end)
		return
	end

	row.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			inventoryRemote:FireServer("Equip", weaponName)
		end
	end)
end

local function render_inventory(): ()
	local container = inventoryContainer
	local template = inventoryTemplate

	if not container or not template then
		return
	end

	local ownedWeapons = normalize_owned_weapons(
		DataUtility.client.get("WeaponsOwned")
	)
	local equippedWeapon = get_equipped_weapon(ownedWeapons)

	template.Visible = false
	clear_inventory_rows()

	for _, weaponName in ownedWeapons do
		local row = template:Clone()
		row.Name = "Weapon_" .. weaponName
		row.Visible = true

		if row:IsA("TextButton") or row:IsA("TextLabel") then
			row.Text = weaponName
			row.TextColor3 = if weaponName == equippedWeapon then EQUIPPED_COLOR else NORMAL_COLOR
		end

		if row:IsA("GuiButton") then
			row.Active = true
			row.AutoButtonColor = true
		end

		connect_weapon_activate(row, weaponName)
		row.Parent = container
	end

	local signature = equippedWeapon .. "|" .. table.concat(ownedWeapons, ",")

	if signature ~= lastRenderSignature then
		lastRenderSignature = signature
		send_debug("Render atualizado: " .. tostring(#ownedWeapons) .. " armas / equipada: " .. equippedWeapon, "Info")
	end
end

local function configure_ui(): ()
	inventoryPage = find_inventory_page()

	if not inventoryPage then
		send_debug("Painel de inventario nao encontrado (Lobby.Inventario ou Lobby.Inventory).", "Error")
		return
	end

	local template: Instance? = nil
	local holder = inventoryPage:FindFirstChild("Holder")

	if holder and holder:IsA("GuiObject") then
		local holderTemplate = holder:FindFirstChild("Template")

		if holderTemplate then
			template = holderTemplate
			inventoryContainer = holder
		end
	end

	if not template then
		template = inventoryPage:FindFirstChild("Template")
		inventoryContainer = inventoryPage
	end

	if not template or not inventoryContainer or not (template:IsA("TextButton") or template:IsA("TextLabel")) then
		send_debug("Template do inventario nao encontrado ou invalido.", "Error")
		return
	end

	inventoryTemplate = template :: GuiObject
	inventoryTemplate.Visible = false

	PagesClientService.register_page(INVENTORY_PAGE_NAME, inventoryPage)
	inventoryPage:GetPropertyChangedSignal("Visible"):Connect(function()
		if inventoryPage then
			inventoryVisible = inventoryPage.Visible
		end
	end)
	inventoryVisible = PagesClientService.is_page_open(INVENTORY_PAGE_NAME)

	inventoryToggleButton = find_inventory_toggle_button()

	if not inventoryToggleButton then
		send_debug("Botao Lobby.Holder.Inventory nao encontrado. Inventario pode ser aberto por NPC.", "Info")
	else
		inventoryToggleButton.Activated:Connect(function()
			PagesClientService.toggle_page(INVENTORY_PAGE_NAME)
			inventoryVisible = PagesClientService.is_page_open(INVENTORY_PAGE_NAME)
			send_debug("Inventario " .. (if inventoryVisible then "aberto" else "fechado") .. ".", "Info")
		end)
	end

	if inventoryPage.Visible then
		PagesClientService.open_page(INVENTORY_PAGE_NAME)
	else
		PagesClientService.close_page(INVENTORY_PAGE_NAME)
	end

	inventoryVisible = PagesClientService.is_page_open(INVENTORY_PAGE_NAME)
	send_debug("UI conectada: " .. inventoryPage:GetFullName(), "Info")
end

------------------//MAIN FUNCTIONS
DataUtility.client.ensure_remotes()
configure_ui()

if bindWeaponsConnection then
	bindWeaponsConnection:Disconnect()
end

bindWeaponsConnection = DataUtility.client.bind("WeaponsOwned", function(_value: any)
	render_inventory()
end)

if bindEquippedConnection then
	bindEquippedConnection:Disconnect()
end

bindEquippedConnection = DataUtility.client.bind("EquippedWeapon", function(_value: any)
	render_inventory()
end)

render_inventory()

------------------//INIT

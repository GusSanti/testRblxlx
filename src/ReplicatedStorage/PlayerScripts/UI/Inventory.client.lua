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
local WeaponViewport = require(utilityFolder:WaitForChild("WeaponViewport"))

local DEBUG_PREFIX = "[InventoryHud]"
local INVENTORY_PAGE_NAME = "Inventory"
local ACTION_EQUIP_COLOR = Color3.fromRGB(80, 220, 110)
local ACTION_EQUIPPED_COLOR = Color3.fromRGB(255, 255, 255)

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Warn = Color3.fromRGB(255, 218, 120),
	Error = Color3.fromRGB(255, 135, 135),
}

type WeaponConfig = {
	name: string,
	displayName: string,
	model: string?,
	price: number,
	rarity: string,
	description: string?,
}

type WeaponAssetEntry = WeaponViewport.WeaponAssetEntry

type InventoryDisplayEntry = {
	config: WeaponConfig,
	assetEntry: WeaponAssetEntry?,
}

type InventoryUiRefs = {
	pageObject: GuiObject,
	rootObject: GuiObject,
	bg: GuiObject,
	closeButton: GuiObject?,
	detailViewport: ViewportFrame,
	detailActionButton: GuiObject,
	detailActionText: TextLabel,
	detailDescriptionLabel: TextLabel,
	detailNameLabel: TextLabel,
	itemsScrollingFrame: ScrollingFrame,
	itemTemplate: GuiObject,
}

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local lobbyGui: ScreenGui = playerGui:WaitForChild("Lobby") :: ScreenGui
local pagesGui: ScreenGui = playerGui:WaitForChild("Pages") :: ScreenGui

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local inventoryRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.INVENTORY_REMOTE_EVENT_NAME) :: RemoteEvent

local inventoryUi: InventoryUiRefs? = nil
local inventoryToggleButton: GuiButton? = nil
local inventoryVisible = false
local selectedWeaponName: string? = nil

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

local function has_weapon(ownedWeapons: { string }, weaponName: string): boolean
	for _, ownedWeaponName in ownedWeapons do
		if ownedWeaponName == weaponName then
			return true
		end
	end

	return false
end

local function is_supported_weapon_name(weaponName: string): boolean
	if weaponName == "" then
		return false
	end

	return ItemsDataDictionary.is_valid_weapon(weaponName) or WeaponViewport.has_weapon_asset(weaponName)
end

local function normalize_owned_weapons(rawWeapons: any): { string }
	local validOwnedSet: { [string]: boolean } = {}

	if typeof(rawWeapons) == "table" then
		for _, value in rawWeapons do
			if typeof(value) == "string" and is_supported_weapon_name(value) then
				validOwnedSet[value] = true
			end
		end
	end

	validOwnedSet[ItemsDataDictionary.DEFAULT_WEAPON] = true

	local normalized: { string } = {}
	local insertedSet: { [string]: boolean } = {}

	for _, weaponName in ItemsDataDictionary.get_weapon_names() do
		if validOwnedSet[weaponName] then
			table.insert(normalized, weaponName)
			insertedSet[weaponName] = true
		end
	end

	local directWeaponNames: { string } = {}
	for weaponName in validOwnedSet do
		if not insertedSet[weaponName] then
			table.insert(directWeaponNames, weaponName)
		end
	end

	table.sort(directWeaponNames)

	for _, weaponName in directWeaponNames do
		table.insert(normalized, weaponName)
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

local function build_inventory_weapon_config(weaponName: string): WeaponConfig
	local existingConfig = ItemsDataDictionary.get_weapon_config(weaponName)
	if existingConfig then
		return existingConfig
	end

	return {
		name = weaponName,
		displayName = WeaponViewport.get_display_name(weaponName),
		model = nil,
		price = 0,
		rarity = "Common",
		description = "Description coming soon.",
	}
end

local function set_image_or_background_color(instance: GuiObject, color: Color3): ()
	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		instance.ImageColor3 = color
		return
	end

	instance.BackgroundColor3 = color
end

local function set_activate_handler(target: GuiObject, callback: () -> ()): ()
	if target:IsA("GuiButton") then
		target.Activated:Connect(callback)
		return
	end

	target.Active = true
	target.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			callback()
		end
	end)
end

local function get_page_object_for_candidate(candidate: GuiObject): GuiObject
	local cursor: Instance = candidate

	while cursor.Parent and not cursor.Parent:IsA("ScreenGui") do
		if not cursor.Parent:IsA("GuiObject") then
			break
		end

		cursor = cursor.Parent
	end

	return cursor :: GuiObject
end

local function build_inventory_ui_refs(pageObject: GuiObject, rootObject: GuiObject): InventoryUiRefs?
	local bg = rootObject:FindFirstChild("bg")
	if not bg or not bg:IsA("GuiObject") then
		return nil
	end

	local detailObject = bg:FindFirstChild("detailed")
	local itemsObject = bg:FindFirstChild("items")
	local ignoreObject = bg:FindFirstChild("Ignore")

	if not detailObject or not detailObject:IsA("GuiObject") or not itemsObject or not itemsObject:IsA("GuiObject") then
		return nil
	end

	local imageButton = detailObject:FindFirstChild("ImageButton")
	local detailViewport = imageButton and imageButton:FindFirstChild("ViewportFrame")
	local ownButton = detailObject:FindFirstChild("ow")
	local ownText = ownButton and ownButton:FindFirstChild("current")
	local descriptionLabel = detailObject:FindFirstChild("desc")
	local nameLabel = detailObject:FindFirstChild("nameweapon")
	local scrollingFrame = itemsObject:FindFirstChild("ScrollingFrame")
	local itemTemplate = scrollingFrame and scrollingFrame:FindFirstChild("Item")
	local closeButton: GuiObject? = nil

	if ignoreObject and ignoreObject:IsA("GuiObject") then
		local nestedClose = ignoreObject:FindFirstChild("x")
		if nestedClose and nestedClose:IsA("GuiObject") then
			closeButton = nestedClose
		end
	end

	if not closeButton then
		local directClose = bg:FindFirstChild("x")
		if directClose and directClose:IsA("GuiObject") then
			closeButton = directClose
		end
	end

	if not imageButton or not imageButton:IsA("GuiObject")
		or not detailViewport or not detailViewport:IsA("ViewportFrame")
		or not ownButton or not ownButton:IsA("GuiObject")
		or not ownText or not ownText:IsA("TextLabel")
		or not descriptionLabel or not descriptionLabel:IsA("TextLabel")
		or not nameLabel or not nameLabel:IsA("TextLabel")
		or not scrollingFrame or not scrollingFrame:IsA("ScrollingFrame")
		or not itemTemplate or not itemTemplate:IsA("GuiObject")
	then
		return nil
	end

	return {
		pageObject = pageObject,
		rootObject = rootObject,
		bg = bg,
		closeButton = closeButton,
		detailViewport = detailViewport,
		detailActionButton = ownButton,
		detailActionText = ownText,
		detailDescriptionLabel = descriptionLabel,
		detailNameLabel = nameLabel,
		itemsScrollingFrame = scrollingFrame,
		itemTemplate = itemTemplate,
	}
end

local function find_inventory_page(): InventoryUiRefs?
	local candidates: { GuiObject } = {}

	local function register_candidate(instance: Instance?): ()
		if instance and instance:IsA("GuiObject") then
			table.insert(candidates, instance)
		end
	end

	register_candidate(pagesGui:FindFirstChild("Inventory"))
	register_candidate(pagesGui:FindFirstChild("Inventario"))
	register_candidate(lobbyGui:FindFirstChild("Inventory"))
	register_candidate(lobbyGui:FindFirstChild("Inventario"))

	for _, descendant in pagesGui:GetDescendants() do
		if descendant.Name == "Inventory" or descendant.Name == "Inventario" then
			register_candidate(descendant)
		end
	end

	for _, descendant in lobbyGui:GetDescendants() do
		if descendant.Name == "Inventory" or descendant.Name == "Inventario" then
			register_candidate(descendant)
		end
	end

	for _, candidate in candidates do
		local pageObject = get_page_object_for_candidate(candidate)
		local refs = build_inventory_ui_refs(pageObject, candidate)

		if refs then
			return refs
		end

		if candidate ~= pageObject then
			refs = build_inventory_ui_refs(pageObject, pageObject)
			if refs then
				return refs
			end
		end
	end

	return nil
end

local function find_inventory_toggle_button(): GuiButton?
	local hud = lobbyGui:FindFirstChild("HUD")

	if hud and hud:IsA("GuiObject") then
		local itemsButton = hud:FindFirstChild("Items")
		if itemsButton and itemsButton:IsA("GuiButton") then
			return itemsButton
		end

		local inventoryButton = hud:FindFirstChild("Inventory")
		if inventoryButton and inventoryButton:IsA("GuiButton") then
			return inventoryButton
		end
	end

	local directItemsButton = lobbyGui:FindFirstChild("Items")
	if directItemsButton and directItemsButton:IsA("GuiButton") then
		return directItemsButton
	end

	return nil
end

local function clear_inventory_items(refs: InventoryUiRefs): ()
	for _, child in refs.itemsScrollingFrame:GetChildren() do
		if child ~= refs.itemTemplate and child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	refs.itemTemplate.Visible = false
end

local function set_inventory_visible(visible: boolean): ()
	if visible then
		PagesClientService.open_page(INVENTORY_PAGE_NAME)
		return
	end

	PagesClientService.close_page(INVENTORY_PAGE_NAME)
end

local function get_inventory_display_entries(ownedWeapons: { string }): { InventoryDisplayEntry }
	local assetEntries = WeaponViewport.get_available_weapon_assets()
	local displayEntries: { InventoryDisplayEntry } = {}
	local assignedAssets: { [number]: boolean } = {}

	for _, weaponName in ownedWeapons do
		table.insert(displayEntries, {
			config = build_inventory_weapon_config(weaponName),
			assetEntry = WeaponViewport.resolve_asset_entry_for_weapon(weaponName, assetEntries, assignedAssets),
		})
	end

	return displayEntries
end

local function get_selected_weapon(ownedWeapons: { string }, equippedWeapon: string): string?
	if selectedWeaponName and has_weapon(ownedWeapons, selectedWeaponName) then
		return selectedWeaponName
	end

	if has_weapon(ownedWeapons, equippedWeapon) then
		return equippedWeapon
	end

	return ownedWeapons[1]
end

local function render_inventory_details(refs: InventoryUiRefs, displayEntry: InventoryDisplayEntry, isEquipped: boolean): ()
	local weaponConfig = displayEntry.config
	refs.detailNameLabel.Text = weaponConfig.displayName
	refs.detailDescriptionLabel.Text = weaponConfig.description or ItemsDataDictionary.get_weapon_description(weaponConfig.name)

	WeaponViewport.render_weapon_viewport(refs.detailViewport, displayEntry.assetEntry or weaponConfig.name)

	refs.detailActionText.Text = if isEquipped then "Equiped" else "Equip"
	set_image_or_background_color(refs.detailActionButton, if isEquipped then ACTION_EQUIPPED_COLOR else ACTION_EQUIP_COLOR)

	if refs.detailActionButton:IsA("GuiButton") then
		refs.detailActionButton.Active = not isEquipped
		refs.detailActionButton.AutoButtonColor = not isEquipped
	end
end

local function render_inventory(): ()
	local refs = inventoryUi

	if not refs then
		return
	end

	local ownedWeapons = normalize_owned_weapons(DataUtility.client.get("WeaponsOwned"))
	local equippedWeapon = get_equipped_weapon(ownedWeapons)
	local displayEntries = get_inventory_display_entries(ownedWeapons)

	selectedWeaponName = get_selected_weapon(ownedWeapons, equippedWeapon)
	clear_inventory_items(refs)

	local itemCount = 0

	for index, displayEntry in displayEntries do
		local weaponConfig = displayEntry.config
		itemCount += 1

		local row = refs.itemTemplate:Clone()
		row.Name = "InventoryItem_" .. weaponConfig.name
		row.Visible = true
		row.LayoutOrder = index

		local viewport = row:FindFirstChild("ViewportFrame")
		if viewport and viewport:IsA("ViewportFrame") then
			WeaponViewport.render_weapon_viewport(viewport, displayEntry.assetEntry or weaponConfig.name)
		end

		if row:IsA("GuiButton") then
			row.Active = true
			row.AutoButtonColor = true
		end

		set_activate_handler(row, function()
			selectedWeaponName = weaponConfig.name
			render_inventory()
		end)

		row.Parent = refs.itemsScrollingFrame
	end

	if not selectedWeaponName then
		refs.detailNameLabel.Text = "No Weapon"
		refs.detailDescriptionLabel.Text = "No description available."
		refs.detailActionText.Text = "Equiped"
		set_image_or_background_color(refs.detailActionButton, ACTION_EQUIPPED_COLOR)
		WeaponViewport.clear_viewport(refs.detailViewport)

		if refs.detailActionButton:IsA("GuiButton") then
			refs.detailActionButton.Active = false
			refs.detailActionButton.AutoButtonColor = false
		end
	else
		for _, displayEntry in displayEntries do
			if displayEntry.config.name == selectedWeaponName then
				render_inventory_details(refs, displayEntry, displayEntry.config.name == equippedWeapon)
				break
			end
		end
	end

	local signatureParts: { string } = {
		equippedWeapon,
		selectedWeaponName or "",
	}

	for _, displayEntry in displayEntries do
		local assetToken = if displayEntry.assetEntry then displayEntry.assetEntry.sourceName else "placeholder"
		table.insert(signatureParts, displayEntry.config.name .. ":" .. assetToken)
	end

	local signature = table.concat(signatureParts, "|")

	if signature ~= lastRenderSignature then
		lastRenderSignature = signature
		send_debug("Inventario atualizado: " .. tostring(itemCount) .. " armas exibidas / equipada: " .. equippedWeapon, "Info")
	end
end

local function on_equip_selected_weapon(): ()
	if not selectedWeaponName or not is_supported_weapon_name(selectedWeaponName) then
		return
	end

	local ownedWeapons = normalize_owned_weapons(DataUtility.client.get("WeaponsOwned"))
	local equippedWeapon = get_equipped_weapon(ownedWeapons)

	if selectedWeaponName == equippedWeapon then
		render_inventory()
		return
	end

	inventoryRemote:FireServer("Equip", selectedWeaponName)
end

local function configure_ui(): ()
	inventoryUi = find_inventory_page()

	if not inventoryUi then
		send_debug("Painel da nova UI de inventario nao encontrado.", "Error")
		return
	end

	inventoryUi.itemTemplate.Visible = false

	PagesClientService.register_page(INVENTORY_PAGE_NAME, inventoryUi.pageObject)
	inventoryUi.pageObject:GetPropertyChangedSignal("Visible"):Connect(function()
		if inventoryUi then
			inventoryVisible = inventoryUi.pageObject.Visible
		end
	end)

	inventoryVisible = PagesClientService.is_page_open(INVENTORY_PAGE_NAME)
	inventoryToggleButton = find_inventory_toggle_button()

	if inventoryToggleButton then
		inventoryToggleButton.Activated:Connect(function()
			PagesClientService.toggle_page(INVENTORY_PAGE_NAME)
			inventoryVisible = PagesClientService.is_page_open(INVENTORY_PAGE_NAME)
			send_debug("Inventario " .. (if inventoryVisible then "aberto" else "fechado") .. ".", "Info")
		end)
	end

	if inventoryUi.closeButton then
		set_activate_handler(inventoryUi.closeButton, function()
			set_inventory_visible(false)
			inventoryVisible = PagesClientService.is_page_open(INVENTORY_PAGE_NAME)
		end)
	end

	set_activate_handler(inventoryUi.detailActionButton, on_equip_selected_weapon)

	if inventoryUi.pageObject.Visible then
		PagesClientService.open_page(INVENTORY_PAGE_NAME)
	else
		PagesClientService.close_page(INVENTORY_PAGE_NAME)
	end

	inventoryVisible = PagesClientService.is_page_open(INVENTORY_PAGE_NAME)
	send_debug("UI do inventario conectada: " .. inventoryUi.pageObject:GetFullName(), "Info")
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

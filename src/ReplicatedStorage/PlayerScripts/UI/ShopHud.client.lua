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

local DEBUG_PREFIX = "[ShopHud]"
local SHOP_PAGE_NAME = "Shop"
local OWNED_COLOR = Color3.fromRGB(255, 255, 255)
local BUY_COLOR = Color3.fromRGB(80, 220, 110)

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Warn = Color3.fromRGB(255, 218, 120),
	Error = Color3.fromRGB(255, 135, 135),
	Success = Color3.fromRGB(130, 255, 160),
}

type WeaponConfig = {
	name: string,
	displayName: string,
	price: number,
	rarity: string,
}

type WeaponAssetEntry = WeaponViewport.WeaponAssetEntry

type ShopDisplayEntry = {
	config: WeaponConfig,
	assetEntry: WeaponAssetEntry?,
}

type ShopUiRefs = {
	pageObject: GuiObject,
	rootObject: GuiObject,
	bg: GuiObject,
	closeButton: GuiObject?,
	detailViewport: ViewportFrame,
	detailActionButton: GuiObject,
	detailActionText: TextLabel,
	detailPriceLabel: TextLabel,
	detailRarityLabel: TextLabel,
	detailNameLabel: TextLabel,
	itemsScrollingFrame: ScrollingFrame,
	itemTemplate: GuiObject,
	moneyCountLabel: TextLabel,
}

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local lobbyGui: ScreenGui = playerGui:WaitForChild("Lobby") :: ScreenGui
local pagesGui: ScreenGui = playerGui:WaitForChild("Pages") :: ScreenGui

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local shopRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.SHOP_REMOTE_EVENT_NAME) :: RemoteEvent

local shopUi: ShopUiRefs? = nil
local shopToggleButton: GuiButton? = nil
local shopVisible = false
local selectedWeaponName: string? = nil
local currentDisplayEntries: { ShopDisplayEntry } = {}
local currentOwnedWeapons: { string } = {}
local currentCoins = 0
local lastListSignature = ""

local bindWeaponsConnection: { Disconnect: (self: any) -> () }? = nil
local bindCoinsConnection: { Disconnect: (self: any) -> () }? = nil
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

	for _, weaponName in ItemsDataDictionary.get_weapon_names() do
		if validOwnedSet[weaponName] then
			table.insert(normalized, weaponName)
		end
	end

	return normalized
end

local function get_player_coins(): number
	local value = DataUtility.client.get("Coins")

	if typeof(value) ~= "number" then
		return 0
	end

	return math.max(0, math.floor(value))
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

local function build_shop_ui_refs(pageObject: GuiObject, rootObject: GuiObject): ShopUiRefs?
	local bg = rootObject:FindFirstChild("bg")
	if not bg or not bg:IsA("GuiObject") then
		return nil
	end

	local detailObject = bg:FindFirstChild("detailed")
	local itemsObject = bg:FindFirstChild("items")
	local moneyObject = bg:FindFirstChild("money")
	local closeButton = bg:FindFirstChild("x")

	if not detailObject or not detailObject:IsA("GuiObject") or not itemsObject or not itemsObject:IsA("GuiObject") or not moneyObject or not moneyObject:IsA("GuiObject") then
		return nil
	end

	local imageButton = detailObject:FindFirstChild("ImageButton")
	local detailViewport = imageButton and imageButton:FindFirstChild("ViewportFrame")
	local ownButton = detailObject:FindFirstChild("ow")
	local ownText = ownButton and ownButton:FindFirstChild("current")
	local priceLabel = detailObject:FindFirstChild("count")
	local rarityLabel = detailObject:FindFirstChild("desc")
	local nameLabel = detailObject:FindFirstChild("nameweapon")
	local scrollingFrame = itemsObject:FindFirstChild("ScrollingFrame")
	local itemTemplate = scrollingFrame and scrollingFrame:FindFirstChild("Item")
	local moneyCount = moneyObject:FindFirstChild("count")

	if not imageButton or not imageButton:IsA("GuiObject")
		or not detailViewport or not detailViewport:IsA("ViewportFrame")
		or not ownButton or not ownButton:IsA("GuiObject")
		or not ownText or not ownText:IsA("TextLabel")
		or not priceLabel or not priceLabel:IsA("TextLabel")
		or not rarityLabel or not rarityLabel:IsA("TextLabel")
		or not nameLabel or not nameLabel:IsA("TextLabel")
		or not scrollingFrame or not scrollingFrame:IsA("ScrollingFrame")
		or not itemTemplate or not itemTemplate:IsA("GuiObject")
		or not moneyCount or not moneyCount:IsA("TextLabel")
	then
		return nil
	end

	return {
		pageObject = pageObject,
		rootObject = rootObject,
		bg = bg,
		closeButton = if closeButton and closeButton:IsA("GuiObject") then closeButton else nil,
		detailViewport = detailViewport,
		detailActionButton = ownButton,
		detailActionText = ownText,
		detailPriceLabel = priceLabel,
		detailRarityLabel = rarityLabel,
		detailNameLabel = nameLabel,
		itemsScrollingFrame = scrollingFrame,
		itemTemplate = itemTemplate,
		moneyCountLabel = moneyCount,
	}
end

local function find_shop_page(): ShopUiRefs?
	local candidates: { GuiObject } = {}

	local function register_candidate(instance: Instance?): ()
		if instance and instance:IsA("GuiObject") then
			table.insert(candidates, instance)
		end
	end

	register_candidate(pagesGui:FindFirstChild("WeaponShop"))
	register_candidate(pagesGui:FindFirstChild("Shop"))
	register_candidate(lobbyGui:FindFirstChild("WeaponShop"))
	register_candidate(lobbyGui:FindFirstChild("Shop"))

	for _, descendant in pagesGui:GetDescendants() do
		if descendant.Name == "WeaponShop" or descendant.Name == "Shop" then
			register_candidate(descendant)
		end
	end

	for _, descendant in lobbyGui:GetDescendants() do
		if descendant.Name == "WeaponShop" or descendant.Name == "Shop" then
			register_candidate(descendant)
		end
	end

	for _, candidate in candidates do
		local pageObject = get_page_object_for_candidate(candidate)
		local refs = build_shop_ui_refs(pageObject, candidate)

		if refs then
			return refs
		end

		if candidate ~= pageObject then
			refs = build_shop_ui_refs(pageObject, pageObject)
			if refs then
				return refs
			end
		end
	end

	return nil
end

local function find_shop_toggle_button(): GuiButton?
	local hud = lobbyGui:FindFirstChild("HUD")

	if hud and hud:IsA("GuiObject") then
		local hudButton = hud:FindFirstChild("Shop")
		if hudButton and hudButton:IsA("GuiButton") then
			return hudButton
		end
	end

	local holder = lobbyGui:FindFirstChild("Holder")

	if holder then
		local holderButton = holder:FindFirstChild("Shop")
		if holderButton and holderButton:IsA("GuiButton") then
			return holderButton
		end
	end

	local directButton = lobbyGui:FindFirstChild("Shop")
	if directButton and directButton:IsA("GuiButton") then
		return directButton
	end

	return nil
end

local function clear_shop_items(refs: ShopUiRefs): ()
	for _, child in refs.itemsScrollingFrame:GetChildren() do
		if child ~= refs.itemTemplate and child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	refs.itemTemplate.Visible = false
end

local function get_display_entry_by_name(displayEntries: { ShopDisplayEntry }, weaponName: string?): ShopDisplayEntry?
	if not weaponName then
		return nil
	end

	for _, displayEntry in displayEntries do
		if displayEntry.config.name == weaponName then
			return displayEntry
		end
	end

	return nil
end

local function set_shop_visible(visible: boolean): ()
	if visible then
		PagesClientService.open_page(SHOP_PAGE_NAME)
		return
	end

	PagesClientService.close_page(SHOP_PAGE_NAME)
end

local function get_shop_display_entries(): { ShopDisplayEntry }
	local weaponConfigs = ItemsDataDictionary.get_weapons_sorted_by_rarity()
	local assetEntries = WeaponViewport.get_available_weapon_assets()
	local displayEntries: { ShopDisplayEntry } = {}
	local assignedAssets: { [number]: boolean } = {}

	for _, weaponConfig in weaponConfigs do
		table.insert(displayEntries, {
			config = weaponConfig,
			assetEntry = WeaponViewport.resolve_asset_entry_for_weapon(weaponConfig.name, assetEntries, assignedAssets),
		})
	end

	return displayEntries
end

local function get_selected_weapon(displayEntries: { ShopDisplayEntry }, ownedWeapons: { string }): string?
	if selectedWeaponName and ItemsDataDictionary.is_valid_weapon(selectedWeaponName) then
		return selectedWeaponName
	end

	for _, displayEntry in displayEntries do
		if not has_weapon(ownedWeapons, displayEntry.config.name) then
			return displayEntry.config.name
		end
	end

	if #displayEntries > 0 then
		return displayEntries[1].config.name
	end

	return nil
end

local function render_shop_details(refs: ShopUiRefs, displayEntry: ShopDisplayEntry, isOwned: boolean): ()
	local weaponConfig = displayEntry.config
	refs.detailNameLabel.Text = weaponConfig.displayName
	refs.detailRarityLabel.Text = weaponConfig.rarity
	refs.detailPriceLabel.Text = "$" .. tostring(weaponConfig.price)

	WeaponViewport.render_weapon_viewport(refs.detailViewport, displayEntry.assetEntry or weaponConfig.name)

	refs.detailActionText.Text = if isOwned then "Owned" else "Buy"
	set_image_or_background_color(refs.detailActionButton, if isOwned then OWNED_COLOR else BUY_COLOR)

	if refs.detailActionButton:IsA("GuiButton") then
		refs.detailActionButton.Active = not isOwned
		refs.detailActionButton.AutoButtonColor = not isOwned
	end
end

local function render_shop_selection_details(): ()
	local refs = shopUi

	if not refs then
		return
	end

	refs.moneyCountLabel.Text = "$" .. tostring(currentCoins)
	selectedWeaponName = get_selected_weapon(currentDisplayEntries, currentOwnedWeapons)

	if not selectedWeaponName then
		refs.detailNameLabel.Text = "No Weapon"
		refs.detailRarityLabel.Text = "-"
		refs.detailPriceLabel.Text = "$0"
		refs.detailActionText.Text = "Owned"
		set_image_or_background_color(refs.detailActionButton, OWNED_COLOR)
		WeaponViewport.clear_viewport(refs.detailViewport)

		if refs.detailActionButton:IsA("GuiButton") then
			refs.detailActionButton.Active = false
			refs.detailActionButton.AutoButtonColor = false
		end

		return
	end

	local selectedDisplayEntry = get_display_entry_by_name(currentDisplayEntries, selectedWeaponName)

	if not selectedDisplayEntry then
		return
	end

	render_shop_details(refs, selectedDisplayEntry, has_weapon(currentOwnedWeapons, selectedDisplayEntry.config.name))
end

local function rebuild_shop_list(refs: ShopUiRefs, displayEntries: { ShopDisplayEntry }): number
	clear_shop_items(refs)

	local itemCount = 0

	for index, displayEntry in displayEntries do
		local weaponConfig = displayEntry.config
		itemCount += 1

		local row = refs.itemTemplate:Clone()
		row.Name = "ShopItem_" .. weaponConfig.name
		row.Visible = true
		row.LayoutOrder = index

		local viewport = row:FindFirstChild("ViewportFrame")
		if viewport and viewport:IsA("ViewportFrame") then
			WeaponViewport.render_weapon_viewport(viewport, displayEntry.assetEntry or weaponConfig.name)
		end

		set_activate_handler(row, function()
			selectedWeaponName = weaponConfig.name
			render_shop_selection_details()
		end)

		row.Parent = refs.itemsScrollingFrame
	end

	return itemCount
end

local function render_shop(): ()
	local refs = shopUi

	if not refs then
		return
	end

	local displayEntries = get_shop_display_entries()
	local ownedWeapons = normalize_owned_weapons(DataUtility.client.get("WeaponsOwned"))
	local coins = get_player_coins()

	local listSignatureParts: { string } = {}
	for _, displayEntry in displayEntries do
		local assetToken = if displayEntry.assetEntry then displayEntry.assetEntry.sourceName else "placeholder"
		table.insert(listSignatureParts, displayEntry.config.name .. ":" .. assetToken)
	end

	local listSignature = table.concat(listSignatureParts, "|")
	local itemCount = #displayEntries

	currentDisplayEntries = displayEntries
	currentOwnedWeapons = ownedWeapons
	currentCoins = coins
	selectedWeaponName = get_selected_weapon(currentDisplayEntries, currentOwnedWeapons)

	if listSignature ~= lastListSignature then
		lastListSignature = listSignature
		itemCount = rebuild_shop_list(refs, currentDisplayEntries)
	end

	render_shop_selection_details()

	local signatureParts: { string } = { tostring(coins) }

	for _, displayEntry in currentDisplayEntries do
		local assetToken = if displayEntry.assetEntry then displayEntry.assetEntry.sourceName else "placeholder"
		table.insert(signatureParts, displayEntry.config.name .. ":" .. assetToken .. ":" .. tostring(has_weapon(currentOwnedWeapons, displayEntry.config.name)))
	end

	local signature = table.concat(signatureParts, "|")

	if signature ~= lastRenderSignature then
		lastRenderSignature = signature
		send_debug("Shop atualizada: " .. tostring(itemCount) .. " armas exibidas.", "Info")
	end
end

local function on_buy_selected_weapon(): ()
	if not selectedWeaponName or not ItemsDataDictionary.is_valid_weapon(selectedWeaponName) then
		return
	end

	local ownedWeapons = normalize_owned_weapons(DataUtility.client.get("WeaponsOwned"))
	if has_weapon(ownedWeapons, selectedWeaponName) then
		render_shop()
		return
	end

	shopRemote:FireServer("Buy", selectedWeaponName)
end

local function configure_ui(): ()
	shopUi = find_shop_page()

	if not shopUi then
		send_debug("Painel da WeaponShop nao encontrado.", "Error")
		return
	end

	shopUi.itemTemplate.Visible = false

	PagesClientService.register_page(SHOP_PAGE_NAME, shopUi.pageObject)
	shopUi.pageObject:GetPropertyChangedSignal("Visible"):Connect(function()
		if shopUi then
			shopVisible = shopUi.pageObject.Visible
		end
	end)

	shopVisible = PagesClientService.is_page_open(SHOP_PAGE_NAME)
	shopToggleButton = find_shop_toggle_button()

	if shopToggleButton then
		shopToggleButton.Activated:Connect(function()
			PagesClientService.toggle_page(SHOP_PAGE_NAME)
			shopVisible = PagesClientService.is_page_open(SHOP_PAGE_NAME)
			send_debug("Shop " .. (if shopVisible then "aberta" else "fechada") .. ".", "Info")
		end)
	end

	if shopUi.closeButton then
		set_activate_handler(shopUi.closeButton, function()
			set_shop_visible(false)
			shopVisible = PagesClientService.is_page_open(SHOP_PAGE_NAME)
		end)
	end

	set_activate_handler(shopUi.detailActionButton, on_buy_selected_weapon)

	if shopUi.pageObject.Visible then
		PagesClientService.open_page(SHOP_PAGE_NAME)
	else
		PagesClientService.close_page(SHOP_PAGE_NAME)
	end

	shopVisible = PagesClientService.is_page_open(SHOP_PAGE_NAME)
	send_debug("UI da shop conectada: " .. shopUi.pageObject:GetFullName(), "Info")
end

local function on_shop_remote_event(action: string, payload: any): ()
	if action ~= "PurchaseResult" then
		return
	end

	if typeof(payload) ~= "table" then
		return
	end

	if typeof(payload.weaponName) == "string" and payload.weaponName ~= "" then
		selectedWeaponName = payload.weaponName
	end

	local message = if typeof(payload.message) == "string" then payload.message else "Shop update."
	local success = payload.success == true
	send_debug(message, if success then "Success" else "Warn")
	render_shop()
end

------------------//MAIN FUNCTIONS
DataUtility.client.ensure_remotes()
configure_ui()

shopRemote.OnClientEvent:Connect(on_shop_remote_event)

if bindWeaponsConnection then
	bindWeaponsConnection:Disconnect()
end

bindWeaponsConnection = DataUtility.client.bind("WeaponsOwned", function(_value: any)
	render_shop()
end)

if bindCoinsConnection then
	bindCoinsConnection:Disconnect()
end

bindCoinsConnection = DataUtility.client.bind("Coins", function(_value: any)
	render_shop()
end)

render_shop()

------------------//INIT

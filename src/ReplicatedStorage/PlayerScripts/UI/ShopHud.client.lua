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

local DEBUG_PREFIX = "[ShopHud]"
local SHOP_PAGE_NAME = "Shop"
local NORMAL_COLOR = Color3.fromRGB(255, 255, 255)
local DISABLED_COLOR = Color3.fromRGB(180, 120, 120)

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Warn = Color3.fromRGB(255, 218, 120),
	Error = Color3.fromRGB(255, 135, 135),
	Success = Color3.fromRGB(130, 255, 160),
}

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local lobbyGui: ScreenGui = playerGui:WaitForChild("Lobby") :: ScreenGui
local pagesGui: ScreenGui = playerGui:WaitForChild("Pages") :: ScreenGui

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local shopRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.SHOP_REMOTE_EVENT_NAME) :: RemoteEvent

local shopPage: GuiObject? = nil
local shopContainer: GuiObject? = nil
local shopTemplate: GuiObject? = nil
local shopToggleButton: GuiButton? = nil
local shopVisible = false

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

local function is_shop_panel_candidate(instance: Instance?): boolean
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

local function find_shop_page(): GuiObject?
	local pagesShop = pagesGui:FindFirstChild("Shop")

	if is_shop_panel_candidate(pagesShop) then
		return pagesShop :: GuiObject
	end

	local directShop = lobbyGui:FindFirstChild("Shop")

	if is_shop_panel_candidate(directShop) then
		return directShop :: GuiObject
	end

	for _, descendant in lobbyGui:GetDescendants() do
		if descendant.Name == "Shop" and is_shop_panel_candidate(descendant) then
			return descendant :: GuiObject
		end
	end

	return nil
end

local function find_shop_toggle_button(): GuiButton?
	local holder = lobbyGui:FindFirstChild("Holder")

	if not holder then
		return nil
	end

	local button = holder:FindFirstChild("Shop")

	if button and button:IsA("GuiButton") then
		return button
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

local function clear_shop_rows(): ()
	local container = shopContainer
	local template = shopTemplate

	if not container or not template then
		return
	end

	for _, child in container:GetChildren() do
		if child ~= template and not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
end

local function has_weapon(ownedWeapons: { string }, weaponName: string): boolean
	for _, ownedWeaponName in ownedWeapons do
		if ownedWeaponName == weaponName then
			return true
		end
	end

	return false
end

local function normalize_owned_weapons(rawWeapons: any): { string }
	local ownedSet: { [string]: boolean } = {}

	if typeof(rawWeapons) == "table" then
		for _, value in rawWeapons do
			if typeof(value) == "string" and ItemsDataDictionary.is_valid_weapon(value) then
				ownedSet[value] = true
			end
		end
	end

	ownedSet[ItemsDataDictionary.DEFAULT_WEAPON] = true

	local normalized: { string } = {}

	for _, weaponName in ItemsDataDictionary.get_weapon_names() do
		if ownedSet[weaponName] then
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

local function set_row_text_and_state(row: GuiObject, weaponName: string, rarityText: string, priceText: string, canAfford: boolean): ()
	if row:IsA("TextButton") or row:IsA("TextLabel") then
		row.Text = weaponName
		row.TextColor3 = if canAfford then NORMAL_COLOR else DISABLED_COLOR
	end

	local rarityLabel = row:FindFirstChild("Rarity")

	if rarityLabel and (rarityLabel:IsA("TextLabel") or rarityLabel:IsA("TextButton")) then
		rarityLabel.Text = rarityText
		rarityLabel.TextColor3 = if canAfford then NORMAL_COLOR else DISABLED_COLOR
	end

	local priceLabel = row:FindFirstChild("Price")

	if priceLabel and (priceLabel:IsA("TextLabel") or priceLabel:IsA("TextButton")) then
		priceLabel.Text = priceText
		priceLabel.TextColor3 = if canAfford then NORMAL_COLOR else DISABLED_COLOR
	end

	if row:IsA("GuiButton") then
		row.Active = canAfford
		row.AutoButtonColor = canAfford
	end
end

local function connect_buy_action(row: GuiObject, weaponName: string, canAfford: boolean): ()
	if not canAfford then
		return
	end

	if row:IsA("GuiButton") then
		row.Activated:Connect(function()
			shopRemote:FireServer("Buy", weaponName)
		end)
		return
	end

	row.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			shopRemote:FireServer("Buy", weaponName)
		end
	end)
end

local function render_shop(): ()
	local container = shopContainer
	local template = shopTemplate

	if not container or not template then
		return
	end

	local ownedWeapons = normalize_owned_weapons(DataUtility.client.get("WeaponsOwned"))
	local coins = get_player_coins()
	local sortedWeapons = ItemsDataDictionary.get_weapons_sorted_by_rarity()

	template.Visible = false
	clear_shop_rows()

	local shopCount = 0

	for _, weaponConfig in sortedWeapons do
		if has_weapon(ownedWeapons, weaponConfig.name) then
			continue
		end

		shopCount += 1

		local row = template:Clone()
		row.Name = "ShopWeapon_" .. weaponConfig.name
		row.Visible = true
		row.LayoutOrder = shopCount

		local canAfford = coins >= weaponConfig.price
		set_row_text_and_state(
			row,
			weaponConfig.name,
			weaponConfig.rarity,
			tostring(weaponConfig.price),
			canAfford
		)
		connect_buy_action(row, weaponConfig.name, canAfford)
		row.Parent = container
	end

	local signatureParts: { string } = { tostring(coins) }

	for _, weaponConfig in sortedWeapons do
		if not has_weapon(ownedWeapons, weaponConfig.name) then
			table.insert(signatureParts, weaponConfig.name)
		end
	end

	local signature = table.concat(signatureParts, "|")

	if signature ~= lastRenderSignature then
		lastRenderSignature = signature
		send_debug("Shop atualizado: " .. tostring(shopCount) .. " itens disponiveis.", "Info")
	end
end

local function configure_ui(): ()
	shopPage = find_shop_page()

	if not shopPage then
		send_debug("Painel Lobby.Shop nao encontrado.", "Error")
		return
	end

	local template: Instance? = nil
	local holder = shopPage:FindFirstChild("Holder")

	if holder and holder:IsA("GuiObject") then
		local holderTemplate = holder:FindFirstChild("Template")

		if holderTemplate then
			template = holderTemplate
			shopContainer = holder
		end
	end

	if not template then
		template = shopPage:FindFirstChild("Template")
		shopContainer = shopPage
	end

	if not template or not shopContainer or not (template:IsA("TextButton") or template:IsA("TextLabel")) then
		send_debug("Template da shop nao encontrado ou invalido.", "Error")
		return
	end

	shopTemplate = template :: GuiObject
	shopTemplate.Visible = false

	PagesClientService.register_page(SHOP_PAGE_NAME, shopPage)
	shopPage:GetPropertyChangedSignal("Visible"):Connect(function()
		if shopPage then
			shopVisible = shopPage.Visible
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

	if shopPage.Visible then
		PagesClientService.open_page(SHOP_PAGE_NAME)
	else
		PagesClientService.close_page(SHOP_PAGE_NAME)
	end

	shopVisible = PagesClientService.is_page_open(SHOP_PAGE_NAME)
	send_debug("UI da shop conectada: " .. shopPage:GetFullName(), "Info")
end

local function on_shop_remote_event(action: string, payload: any): ()
	if action ~= "PurchaseResult" then
		return
	end

	if typeof(payload) ~= "table" then
		return
	end

	local message = if typeof(payload.message) == "string" then payload.message else "Shop update."
	local success = payload.success == true
	send_debug(message, if success then "Success" else "Warn")
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

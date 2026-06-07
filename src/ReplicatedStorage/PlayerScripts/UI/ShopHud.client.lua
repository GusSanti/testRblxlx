------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui: StarterGui = game:GetService("StarterGui")
local TextChatService: TextChatService = game:GetService("TextChatService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local ItemsDataDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("ItemsDataDictionary"))
local PagesClientService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("PagesClientService"))
local WeaponSettings = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Libraries"):WaitForChild("WeaponSettings"))

local modulesFolder: Folder = ReplicatedStorage:WaitForChild("Modules") :: Folder
local utilityFolder: Folder = modulesFolder:WaitForChild("Utility") :: Folder
local DataUtility = require(utilityFolder:WaitForChild("DataUtility"))

local assetsFolder: Folder = ReplicatedStorage:WaitForChild("Assets") :: Folder
local weaponsFolder: Folder? = assetsFolder:FindFirstChild("Weapons") :: Folder?

local DEBUG_PREFIX = "[ShopHud]"
local SHOP_PAGE_NAME = "Shop"
local OWNED_COLOR = Color3.fromRGB(255, 255, 255)
local BUY_COLOR = Color3.fromRGB(80, 220, 110)
local FALLBACK_WEAPON_COLOR = Color3.fromRGB(55, 55, 55)
local FALLBACK_ACCENT_COLOR = Color3.fromRGB(150, 150, 150)

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

type WeaponAssetEntry = {
	sourceName: string,
	assetName: string,
	asset: Instance,
	resolvedWeaponKey: string?,
}

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

local function normalize_lookup_token(value: string): string
	local normalized = string.lower(value)
	return string.gsub(normalized, "[^%w]", "")
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

local function clear_viewport(viewport: ViewportFrame): ()
	for _, child in viewport:GetChildren() do
		child:Destroy()
	end

	viewport.CurrentCamera = nil
end

local function is_weapon_tool(instance: Instance?): boolean
	return instance ~= nil and instance:IsA("Tool") and instance:FindFirstChild("WeaponConfig") ~= nil
end

local function get_tool_from_instance(instance: Instance?): Tool?
	if not instance then
		return nil
	end

	if is_weapon_tool(instance) then
		return instance :: Tool
	end

	local nestedTool = instance:FindFirstChildWhichIsA("Tool", true)
	if is_weapon_tool(nestedTool) then
		return nestedTool :: Tool
	end

	return nil
end

local function get_display_asset_from_instance(instance: Instance?): Instance?
	if not instance then
		return nil
	end

	local tool = get_tool_from_instance(instance)
	if tool then
		return tool
	end

	if instance:IsA("Model") then
		return instance
	end

	local nestedModel = instance:FindFirstChildWhichIsA("Model", true)
	if nestedModel then
		return nestedModel
	end

	if instance:FindFirstChildWhichIsA("BasePart", true) then
		return instance
	end

	return nil
end

local function get_available_weapon_assets(): { WeaponAssetEntry }
	local entries: { WeaponAssetEntry } = {}
	local seen: { [string]: boolean } = {}

	local function register_from_container(container: Instance?): ()
		if not container then
			return
		end

		for _, child in container:GetChildren() do
			local asset = get_display_asset_from_instance(child)

			if not asset then
				continue
			end

			local sourceName = child.Name
			local assetName = asset.Name
			local dedupeKey = sourceName .. "|" .. assetName

			if seen[dedupeKey] then
				continue
			end

			seen[dedupeKey] = true

			local resolvedWeaponKey: string? = nil
			if asset:IsA("Tool") then
				resolvedWeaponKey = WeaponSettings.ResolveTool(asset)
			else
				resolvedWeaponKey = WeaponSettings.ResolveWeaponKey(assetName)
			end

			table.insert(entries, {
				sourceName = sourceName,
				assetName = assetName,
				asset = asset,
				resolvedWeaponKey = resolvedWeaponKey,
			})
		end
	end

	register_from_container(weaponsFolder)

	return entries
end

local function resolve_asset_entry_for_weapon(
	weaponName: string,
	assetEntries: { WeaponAssetEntry },
	assignedAssets: { [number]: boolean }
): WeaponAssetEntry?
	if weaponName == "" then
		return nil
	end

	local normalizedWeaponName = normalize_lookup_token(weaponName)
	local resolvedWeaponKey = WeaponSettings.ResolveWeaponKey(weaponName)

	local function collect_matches(predicate: (WeaponAssetEntry) -> boolean): { { index: number, entry: WeaponAssetEntry } }
		local matches: { { index: number, entry: WeaponAssetEntry } } = {}

		for index, entry in assetEntries do
			if not assignedAssets[index] and predicate(entry) then
				table.insert(matches, {
					index = index,
					entry = entry,
				})
			end
		end

		return matches
	end

	local directMatches = collect_matches(function(entry: WeaponAssetEntry): boolean
		return entry.sourceName == weaponName or entry.assetName == weaponName
	end)

	if #directMatches == 1 then
		local match = directMatches[1]
		assignedAssets[match.index] = true
		return match.entry
	end

	local normalizedMatches = collect_matches(function(entry: WeaponAssetEntry): boolean
		return normalize_lookup_token(entry.sourceName) == normalizedWeaponName
			or normalize_lookup_token(entry.assetName) == normalizedWeaponName
	end)

	if #normalizedMatches == 1 then
		local match = normalizedMatches[1]
		assignedAssets[match.index] = true
		return match.entry
	end

	if resolvedWeaponKey then
		local keyMatches = collect_matches(function(entry: WeaponAssetEntry): boolean
			return entry.resolvedWeaponKey == resolvedWeaponKey
		end)

		if #keyMatches == 1 then
			local match = keyMatches[1]
			assignedAssets[match.index] = true
			return match.entry
		end
	end

	return nil
end

local function clone_display_asset(instance: Instance): Model?
	local originalArchivable = instance.Archivable
	instance.Archivable = true

	local success, cloneResult = pcall(function()
		return instance:Clone()
	end)

	instance.Archivable = originalArchivable

	if not success or not cloneResult or not cloneResult:IsA("Instance") then
		return nil
	end

	local clone: Instance = cloneResult
	local model: Model

	if clone:IsA("Model") then
		model = clone
	else
		model = Instance.new("Model")
		model.Name = clone.Name

		for _, child in clone:GetChildren() do
			child.Parent = model
		end

		clone:Destroy()
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	if not model:FindFirstChildWhichIsA("BasePart", true) then
		model:Destroy()
		return nil
	end

	return model
end

local function build_placeholder_weapon_model(): Model
	local model = Instance.new("Model")
	model.Name = "WeaponPlaceholder"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.6, 0.4, 0.55)
	body.Color = FALLBACK_WEAPON_COLOR
	body.Material = Enum.Material.SmoothPlastic
	body.CFrame = CFrame.new(0, 0.35, 0)
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = false
	body.Parent = model

	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(1.2, 0.18, 0.18)
	barrel.Color = FALLBACK_ACCENT_COLOR
	barrel.Material = Enum.Material.Metal
	barrel.CFrame = CFrame.new(1.75, 0.42, 0)
	barrel.Anchored = true
	barrel.CanCollide = false
	barrel.CanTouch = false
	barrel.CanQuery = false
	barrel.Parent = model

	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Size = Vector3.new(0.4, 0.9, 0.32)
	grip.Color = FALLBACK_ACCENT_COLOR
	grip.Material = Enum.Material.Metal
	grip.CFrame = CFrame.new(-0.55, -0.3, 0) * CFrame.Angles(0, 0, math.rad(18))
	grip.Anchored = true
	grip.CanCollide = false
	grip.CanTouch = false
	grip.CanQuery = false
	grip.Parent = model

	return model
end

local function render_weapon_viewport(viewport: ViewportFrame, assetEntry: WeaponAssetEntry?): boolean
	clear_viewport(viewport)

	local displayModel = if assetEntry then clone_display_asset(assetEntry.asset) else nil

	if not displayModel then
		displayModel = build_placeholder_weapon_model()
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport
	displayModel.Parent = worldModel

	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local boundingCFrame, boundingSize = displayModel:GetBoundingBox()
	local maxAxis = math.max(boundingSize.X, boundingSize.Y, boundingSize.Z, 1)
	local focusPosition = boundingCFrame.Position
	local cameraOffset = Vector3.new(maxAxis * 1.15, maxAxis * 0.45, maxAxis * 1.8)

	camera.FieldOfView = 28
	camera.CFrame = CFrame.lookAt(focusPosition + cameraOffset, focusPosition)
	return true
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

local function clear_shop_items(refs: ShopUiRefs): ()
	for _, child in refs.itemsScrollingFrame:GetChildren() do
		if child ~= refs.itemTemplate and child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	refs.itemTemplate.Visible = false
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
	local assetEntries = get_available_weapon_assets()
	local displayEntries: { ShopDisplayEntry } = {}
	local assignedAssets: { [number]: boolean } = {}

	for _, weaponConfig in weaponConfigs do
		table.insert(displayEntries, {
			config = weaponConfig,
			assetEntry = resolve_asset_entry_for_weapon(weaponConfig.name, assetEntries, assignedAssets),
		})
	end

	local nextFallbackIndex = 1

	for _, displayEntry in displayEntries do
		if displayEntry.assetEntry == nil then
			while assetEntries[nextFallbackIndex] and assignedAssets[nextFallbackIndex] do
				nextFallbackIndex += 1
			end

			local fallbackAssetEntry = assetEntries[nextFallbackIndex]
			if fallbackAssetEntry then
				displayEntry.assetEntry = fallbackAssetEntry
				assignedAssets[nextFallbackIndex] = true
				nextFallbackIndex += 1
			end
		end
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

	render_weapon_viewport(refs.detailViewport, displayEntry.assetEntry)

	refs.detailActionText.Text = if isOwned then "Owned" else "Buy"
	set_image_or_background_color(refs.detailActionButton, if isOwned then OWNED_COLOR else BUY_COLOR)

	if refs.detailActionButton:IsA("GuiButton") then
		refs.detailActionButton.Active = not isOwned
		refs.detailActionButton.AutoButtonColor = not isOwned
	end
end

local function render_shop(): ()
	local refs = shopUi

	if not refs then
		return
	end

	local displayEntries = get_shop_display_entries()
	local ownedWeapons = normalize_owned_weapons(DataUtility.client.get("WeaponsOwned"))
	local coins = get_player_coins()

	selectedWeaponName = get_selected_weapon(displayEntries, ownedWeapons)
	clear_shop_items(refs)

	local itemCount = 0

	for _, displayEntry in displayEntries do
		local weaponConfig = displayEntry.config
		itemCount += 1

		local row = refs.itemTemplate:Clone()
		row.Name = "ShopItem_" .. weaponConfig.name
		row.Visible = true

		local viewport = row:FindFirstChild("ViewportFrame")
		if viewport and viewport:IsA("ViewportFrame") then
			render_weapon_viewport(viewport, displayEntry.assetEntry)
		end

		set_activate_handler(row, function()
			selectedWeaponName = weaponConfig.name
			render_shop()
		end)

		row.Parent = refs.itemsScrollingFrame
	end

	refs.moneyCountLabel.Text = "$" .. tostring(coins)

	if not selectedWeaponName then
		refs.detailNameLabel.Text = "No Weapon"
		refs.detailRarityLabel.Text = "-"
		refs.detailPriceLabel.Text = "$0"
		refs.detailActionText.Text = "Owned"
		set_image_or_background_color(refs.detailActionButton, OWNED_COLOR)
		clear_viewport(refs.detailViewport)
	else
		for _, displayEntry in displayEntries do
			if displayEntry.config.name == selectedWeaponName then
				render_shop_details(refs, displayEntry, has_weapon(ownedWeapons, displayEntry.config.name))
				break
			end
		end
	end

	local signatureParts: { string } = { tostring(coins) }

	for _, displayEntry in displayEntries do
		local assetToken = if displayEntry.assetEntry then displayEntry.assetEntry.sourceName else "placeholder"
		table.insert(signatureParts, displayEntry.config.name .. ":" .. assetToken .. ":" .. tostring(has_weapon(ownedWeapons, displayEntry.config.name)))
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

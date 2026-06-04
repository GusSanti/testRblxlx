------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local ItemsDataDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("ItemsDataDictionary"))

local modulesFolder: Folder = ReplicatedStorage:WaitForChild("Modules") :: Folder
local utilityFolder: Folder = modulesFolder:WaitForChild("Utility") :: Folder
local DataUtility = require(utilityFolder:WaitForChild("DataUtility"))

------------------//VARIABLES
local remotesFolderInstance: Folder? = ReplicatedStorage:FindFirstChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder?

if not remotesFolderInstance then
	remotesFolderInstance = Instance.new("Folder")
	remotesFolderInstance.Name = MatchmakingDictionary.REMOTE_FOLDER_NAME
	remotesFolderInstance.Parent = ReplicatedStorage
end

local remotesFolder: Folder = remotesFolderInstance :: Folder
local shopRemoteInstance: RemoteEvent? = remotesFolder:FindFirstChild(MatchmakingDictionary.SHOP_REMOTE_EVENT_NAME) :: RemoteEvent?

if not shopRemoteInstance then
	shopRemoteInstance = Instance.new("RemoteEvent")
	shopRemoteInstance.Name = MatchmakingDictionary.SHOP_REMOTE_EVENT_NAME
	shopRemoteInstance.Parent = remotesFolder
end

local shopRemote: RemoteEvent = shopRemoteInstance :: RemoteEvent
local purchaseLocks: { [number]: boolean } = {}

------------------//FUNCTIONS
local function debug_log(message: string): ()
	print("[Shop] " .. message)
end

local function send_result(player: Player, success: boolean, message: string, weaponName: string?): ()
	shopRemote:FireClient(player, "PurchaseResult", {
		success = success,
		message = message,
		weaponName = weaponName,
	})
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

local function ensure_defaults(player: Player): ()
	local normalizedWeapons = normalize_owned_weapons(DataUtility.server.get(player, "WeaponsOwned"))
	local equippedWeapon = DataUtility.server.get(player, "EquippedWeapon")
	local finalEquipped = ItemsDataDictionary.DEFAULT_WEAPON

	if typeof(equippedWeapon) == "string"
		and ItemsDataDictionary.is_valid_weapon(equippedWeapon)
		and has_weapon(normalizedWeapons, equippedWeapon)
	then
		finalEquipped = equippedWeapon
	end

	DataUtility.server.set(player, "WeaponsOwned", normalizedWeapons)
	DataUtility.server.set(player, "EquippedWeapon", finalEquipped)
end

local function get_player_coins(player: Player): number
	local value = DataUtility.server.get(player, "Coins")

	if typeof(value) ~= "number" then
		return 0
	end

	return math.max(0, math.floor(value))
end

local function try_buy_weapon(player: Player, weaponName: string): ()
	if not ItemsDataDictionary.is_valid_weapon(weaponName) then
		send_result(player, false, "Invalid weapon.", weaponName)
		return
	end

	local ownedWeapons = normalize_owned_weapons(DataUtility.server.get(player, "WeaponsOwned"))

	if has_weapon(ownedWeapons, weaponName) then
		send_result(player, false, "You already own this weapon.", weaponName)
		return
	end

	local price = ItemsDataDictionary.get_weapon_price(weaponName)
	local coins = get_player_coins(player)

	if coins < price then
		send_result(player, false, "Not enough coins.", weaponName)
		return
	end

	local nextCoins = coins - price
	table.insert(ownedWeapons, weaponName)
	local nextOwned = normalize_owned_weapons(ownedWeapons)

	DataUtility.server.set(player, "Coins", nextCoins)
	DataUtility.server.set(player, "WeaponsOwned", nextOwned)

	send_result(player, true, "Purchased: " .. weaponName, weaponName)
	debug_log(player.Name .. " comprou " .. weaponName .. " por " .. tostring(price) .. " coins.")
end

local function on_shop_remote_event(player: Player, action: string, payload: any): ()
	if action ~= "Buy" then
		return
	end

	if typeof(payload) ~= "string" then
		send_result(player, false, "Invalid purchase payload.", nil)
		return
	end

	if purchaseLocks[player.UserId] then
		send_result(player, false, "Purchase already in progress.", payload)
		return
	end

	purchaseLocks[player.UserId] = true

	local success, err = pcall(function()
		try_buy_weapon(player, payload)
	end)

	purchaseLocks[player.UserId] = nil

	if not success then
		warn("[Shop] Falha ao processar compra de " .. player.Name .. ": " .. tostring(err))
		send_result(player, false, "Purchase failed. Try again.", payload)
	end
end

local function on_player_added(player: Player): ()
	ensure_defaults(player)
end

local function on_player_removing(player: Player): ()
	purchaseLocks[player.UserId] = nil
end

------------------//MAIN FUNCTIONS
DataUtility.server.ensure_remotes()
shopRemote.OnServerEvent:Connect(on_shop_remote_event)
Players.PlayerAdded:Connect(on_player_added)
Players.PlayerRemoving:Connect(on_player_removing)

for _, player in Players:GetPlayers() do
	task.spawn(function()
		on_player_added(player)
	end)
end

------------------//INIT

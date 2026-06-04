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
local inventoryRemoteInstance: RemoteEvent? = remotesFolder:FindFirstChild(MatchmakingDictionary.INVENTORY_REMOTE_EVENT_NAME) :: RemoteEvent?

if not inventoryRemoteInstance then
	inventoryRemoteInstance = Instance.new("RemoteEvent")
	inventoryRemoteInstance.Name = MatchmakingDictionary.INVENTORY_REMOTE_EVENT_NAME
	inventoryRemoteInstance.Parent = remotesFolder
end

local inventoryRemote: RemoteEvent = inventoryRemoteInstance :: RemoteEvent

------------------//FUNCTIONS
local function debug_log(message: string): ()
	print("[Inventory] " .. message)
end

local function has_weapon(weapons: { string }, weaponName: string): boolean
	for _, ownedWeaponName in weapons do
		if ownedWeaponName == weaponName then
			return true
		end
	end

	return false
end

local function normalize_owned_weapons(rawWeapons: any, rawLegacySkins: any): { string }
	local validOwnedSet: { [string]: boolean } = {}

	if typeof(rawWeapons) == "table" then
		for _, value in rawWeapons do
			if typeof(value) == "string" and ItemsDataDictionary.is_valid_weapon(value) then
				validOwnedSet[value] = true
			end
		end
	end

	if typeof(rawLegacySkins) == "table" then
		for _, value in rawLegacySkins do
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

local function save_player_weapons(player: Player, weapons: { string }): ()
	DataUtility.server.set(player, "WeaponsOwned", weapons)
end

local function save_player_equipped_weapon(player: Player, weaponName: string): ()
	DataUtility.server.set(player, "EquippedWeapon", weaponName)
end

local function ensure_player_inventory_defaults(player: Player): ()
	local rawWeapons = DataUtility.server.get(player, "WeaponsOwned")
	local rawLegacySkins = DataUtility.server.get(player, "Skins")
	local normalizedWeapons = normalize_owned_weapons(rawWeapons, rawLegacySkins)
	local currentEquippedWeapon = DataUtility.server.get(player, "EquippedWeapon")
	local legacyEquippedSkin = DataUtility.server.get(player, "EquippedSkin")
	local equippedWeaponName = ItemsDataDictionary.DEFAULT_WEAPON

	if typeof(currentEquippedWeapon) == "string"
		and ItemsDataDictionary.is_valid_weapon(currentEquippedWeapon)
		and has_weapon(normalizedWeapons, currentEquippedWeapon)
	then
		equippedWeaponName = currentEquippedWeapon
	elseif typeof(legacyEquippedSkin) == "string"
		and ItemsDataDictionary.is_valid_weapon(legacyEquippedSkin)
		and has_weapon(normalizedWeapons, legacyEquippedSkin)
	then
		equippedWeaponName = legacyEquippedSkin
	end

	save_player_weapons(player, normalizedWeapons)
	save_player_equipped_weapon(player, equippedWeaponName)
end

local function equip_weapon(player: Player, weaponName: string): ()
	if not ItemsDataDictionary.is_valid_weapon(weaponName) then
		return
	end

	local normalizedWeapons = normalize_owned_weapons(
		DataUtility.server.get(player, "WeaponsOwned"),
		DataUtility.server.get(player, "Skins")
	)

	if not has_weapon(normalizedWeapons, weaponName) then
		return
	end

	save_player_equipped_weapon(player, weaponName)
	debug_log(player.Name .. " equipou arma " .. weaponName .. ".")
end

local function on_player_added(player: Player): ()
	ensure_player_inventory_defaults(player)
end

local function on_inventory_remote_event(player: Player, action: string, payload: any): ()
	if action ~= "Equip" then
		return
	end

	if typeof(payload) ~= "string" then
		return
	end

	equip_weapon(player, payload)
end

------------------//MAIN FUNCTIONS
DataUtility.server.ensure_remotes()
inventoryRemote.OnServerEvent:Connect(on_inventory_remote_event)
Players.PlayerAdded:Connect(on_player_added)

for _, player in Players:GetPlayers() do
	task.spawn(function()
		on_player_added(player)
	end)
end

------------------//INIT

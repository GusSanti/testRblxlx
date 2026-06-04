local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local utilityFolder = modulesFolder:WaitForChild("Utility")
local dictionaryFolder = modulesFolder:WaitForChild("Dictionary")
local assetsFolder = ReplicatedStorage:WaitForChild("Assets")
local weaponsFolder = assetsFolder:WaitForChild("Weapons")

local DataUtility = require(utilityFolder:WaitForChild("DataUtility"))
local ItemsDataDictionary = require(dictionaryFolder:WaitForChild("ItemsDataDictionary"))

local playerDataConnectionsByUserId: { [number]: { any } } = {}

local function debug_log(message: string): ()
	print("[PlayerLoadout] " .. message)
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
	for _, weaponName in ItemsDataDictionary.get_weapon_names() do
		if validOwnedSet[weaponName] then
			table.insert(normalized, weaponName)
		end
	end

	return normalized
end

local function resolve_equipped_weapon_name(player: Player): string
	local normalizedWeapons = normalize_owned_weapons(
		DataUtility.server.get(player, "WeaponsOwned"),
		DataUtility.server.get(player, "Skins")
	)

	local equippedWeapon = DataUtility.server.get(player, "EquippedWeapon")
	local legacyEquippedSkin = DataUtility.server.get(player, "EquippedSkin")
	local chosenWeapon = ItemsDataDictionary.DEFAULT_WEAPON

	if typeof(equippedWeapon) == "string"
		and ItemsDataDictionary.is_valid_weapon(equippedWeapon)
		and has_weapon(normalizedWeapons, equippedWeapon)
	then
		chosenWeapon = equippedWeapon
	elseif typeof(legacyEquippedSkin) == "string"
		and ItemsDataDictionary.is_valid_weapon(legacyEquippedSkin)
		and has_weapon(normalizedWeapons, legacyEquippedSkin)
	then
		chosenWeapon = legacyEquippedSkin
	end

	return chosenWeapon
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

local function find_weapon_template_by_name(weaponName: string): Tool?
	local weaponAsset = get_tool_from_instance(weaponsFolder:FindFirstChild(weaponName))
	if weaponAsset then
		return weaponAsset
	end

	local starterPackTool = get_tool_from_instance(StarterPack:FindFirstChild(weaponName))
	if starterPackTool then
		return starterPackTool
	end

	return nil
end

local function find_first_weapon_template(): Tool?
	for _, child in weaponsFolder:GetChildren() do
		local tool = get_tool_from_instance(child)
		if tool then
			return tool
		end
	end

	for _, child in StarterPack:GetChildren() do
		local tool = get_tool_from_instance(child)
		if tool then
			return tool
		end
	end

	return nil
end

local function clear_weapon_tools(container: Instance?): ()
	if not container then
		return
	end

	for _, child in container:GetChildren() do
		if is_weapon_tool(child) then
			child:Destroy()
		end
	end
end

local function apply_player_weapon_loadout(player: Player): ()
	if player.Parent ~= Players then
		return
	end

	local selectedWeaponName = resolve_equipped_weapon_name(player)
	local template = find_weapon_template_by_name(selectedWeaponName)

	if not template then
		template = find_weapon_template_by_name(ItemsDataDictionary.DEFAULT_WEAPON)
	end

	if not template then
		template = find_first_weapon_template()
	end

	if not template then
		warn("[PlayerLoadout] Nenhum template de arma encontrado para " .. player.Name)
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then
		warn("[PlayerLoadout] Backpack nao encontrado para " .. player.Name)
		return
	end

	local starterGear = player:FindFirstChild("StarterGear")
	local character = player.Character

	clear_weapon_tools(backpack)
	clear_weapon_tools(starterGear)
	clear_weapon_tools(character)

	local backpackTool = template:Clone()
	backpackTool.Parent = backpack

	if starterGear then
		local starterGearTool = template:Clone()
		starterGearTool.Parent = starterGear
	end

	debug_log(player.Name .. " recebeu arma inicial: " .. template.Name)
end

local function disconnect_player_data_connections(userId: number): ()
	local connections = playerDataConnectionsByUserId[userId]
	if not connections then
		return
	end

	for _, connection in connections do
		if connection then
			connection:Disconnect()
		end
	end

	playerDataConnectionsByUserId[userId] = nil
end

local function onCharacterAdded(player: Player, character: Model): ()
	local playerNameLabel = character:FindFirstChild("PlayerName", true)
	if playerNameLabel and playerNameLabel:IsA("TextLabel") then
		playerNameLabel.Text = player.Name
	end

	task.defer(function()
		apply_player_weapon_loadout(player)
	end)
end

local function onCharacterRemoving(character: Model): ()
	debug_log(character.Name .. " esta saindo do jogo.")
end

local function onPlayerAdded(player: Player): ()
	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end)

	player.CharacterRemoving:Connect(onCharacterRemoving)

	local connections: { any } = {}
	local equippedConnection = DataUtility.server.bind(player, "EquippedWeapon", function(_value: any)
		task.defer(function()
			apply_player_weapon_loadout(player)
		end)
	end)

	if equippedConnection then
		table.insert(connections, equippedConnection)
	end

	local weaponsConnection = DataUtility.server.bind(player, "WeaponsOwned", function(_value: any)
		task.defer(function()
			apply_player_weapon_loadout(player)
		end)
	end)

	if weaponsConnection then
		table.insert(connections, weaponsConnection)
	end

	local skinsConnection = DataUtility.server.bind(player, "Skins", function(_value: any)
		task.defer(function()
			apply_player_weapon_loadout(player)
		end)
	end)

	if skinsConnection then
		table.insert(connections, skinsConnection)
	end

	local legacyEquippedConnection = DataUtility.server.bind(player, "EquippedSkin", function(_value: any)
		task.defer(function()
			apply_player_weapon_loadout(player)
		end)
	end)

	if legacyEquippedConnection then
		table.insert(connections, legacyEquippedConnection)
	end

	playerDataConnectionsByUserId[player.UserId] = connections

	if player.Character then
		onCharacterAdded(player, player.Character)
	end

	task.defer(function()
		apply_player_weapon_loadout(player)
	end)
end

local function onPlayerRemoving(player: Player): ()
	disconnect_player_data_connections(player.UserId)
end

DataUtility.server.ensure_remotes()

for _, player in Players:GetPlayers() do
	task.spawn(function()
		onPlayerAdded(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPack = game:GetService("StarterPack")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local utilityFolder = modulesFolder:WaitForChild("Utility")
local dictionaryFolder = modulesFolder:WaitForChild("Dictionary")
local librariesFolder = modulesFolder:WaitForChild("Libraries")
local assetsFolder = ReplicatedStorage:WaitForChild("Assets")
local weaponsFolder = assetsFolder:WaitForChild("Weapons")

local DataUtility = require(utilityFolder:WaitForChild("DataUtility"))
local ItemsDataDictionary = require(dictionaryFolder:WaitForChild("ItemsDataDictionary"))
local WeaponSettings = require(librariesFolder:WaitForChild("WeaponSettings"))

local playerDataConnectionsByUserId: { [number]: { any } } = {}
local TEST_WEAPON_COMMAND_PREFIXES = {
	["!gun"] = true,
	[";gun"] = true,
	["!weapon"] = true,
	[";weapon"] = true,
}
local TEST_WEAPON_LIST_COMMANDS = {
	["!guns"] = true,
	[";guns"] = true,
	["!weapons"] = true,
	[";weapons"] = true,
}

local function debug_log(message: string): ()
	print("[PlayerLoadout] " .. message)
end

local function normalize_lookup_token(value: string): string
	local normalized = string.lower(value)
	normalized = string.gsub(normalized, "[^%w]", "")
	return normalized
end

local function is_supported_weapon_name(weaponName: string): boolean
	if weaponName == "" then
		return false
	end

	if ItemsDataDictionary.is_valid_weapon(weaponName) then
		return true
	end

	return weaponsFolder:FindFirstChild(weaponName) ~= nil or StarterPack:FindFirstChild(weaponName) ~= nil
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
			if typeof(value) == "string" and is_supported_weapon_name(value) then
				validOwnedSet[value] = true
			end
		end
	end

	if typeof(rawLegacySkins) == "table" then
		for _, value in rawLegacySkins do
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

local function resolve_equipped_weapon_name(player: Player): string
	local normalizedWeapons = normalize_owned_weapons(
		DataUtility.server.get(player, "WeaponsOwned"),
		DataUtility.server.get(player, "Skins")
	)

	local equippedWeapon = DataUtility.server.get(player, "EquippedWeapon")
	local legacyEquippedSkin = DataUtility.server.get(player, "EquippedSkin")
	local chosenWeapon = ItemsDataDictionary.DEFAULT_WEAPON

	if typeof(equippedWeapon) == "string"
		and is_supported_weapon_name(equippedWeapon)
		and has_weapon(normalizedWeapons, equippedWeapon)
	then
		chosenWeapon = equippedWeapon
	elseif typeof(legacyEquippedSkin) == "string"
		and is_supported_weapon_name(legacyEquippedSkin)
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

local function get_available_weapon_templates(): { { name: string, tool: Tool } }
	local templates: { { name: string, tool: Tool } } = {}
	local seen: { [string]: boolean } = {}

	local function register_from_container(container: Instance): ()
		for _, child in container:GetChildren() do
			local tool = get_tool_from_instance(child)
			local weaponName = if tool then tool.Name else child.Name

			if tool and not seen[weaponName] then
				seen[weaponName] = true
				table.insert(templates, {
					name = weaponName,
					tool = tool,
				})
			end
		end
	end

	register_from_container(weaponsFolder)
	register_from_container(StarterPack)

	table.sort(templates, function(a, b)
		return a.name < b.name
	end)

	return templates
end

local function find_weapon_template_by_identifier(identifier: string): (Tool?, string?)
	if identifier == "" then
		return nil, nil
	end

	local direct = find_weapon_template_by_name(identifier)
	if direct then
		return direct, direct.Name
	end

	local normalizedIdentifier = normalize_lookup_token(identifier)
	local matchedTool: Tool? = nil
	local matchedName: string? = nil

	for _, entry in get_available_weapon_templates() do
		if normalize_lookup_token(entry.name) == normalizedIdentifier then
			return entry.tool, entry.name
		end
	end

	local resolvedWeaponKey = WeaponSettings.ResolveWeaponKey(identifier)
	if not resolvedWeaponKey then
		return nil, nil
	end

	for _, entry in get_available_weapon_templates() do
		local entryResolvedWeaponKey = WeaponSettings.ResolveWeaponKey(entry.name)
		if entryResolvedWeaponKey == resolvedWeaponKey then
			if matchedTool and matchedName ~= entry.name then
				return nil, nil
			end

			matchedTool = entry.tool
			matchedName = entry.name
		end
	end

	return matchedTool, matchedName
end

local function tag_weapon_tool(tool: Tool, requestedWeaponName: string): ()
	local fallbackName = if tool.Name ~= "" then tool.Name else requestedWeaponName
	local resolvedWeaponName = fallbackName

	if requestedWeaponName ~= "" and WeaponSettings.ResolveWeaponKey(requestedWeaponName) then
		resolvedWeaponName = requestedWeaponName
	elseif tool.Name ~= "" and WeaponSettings.ResolveWeaponKey(tool.Name) then
		resolvedWeaponName = tool.Name
	end

	tool:SetAttribute("WeaponKey", resolvedWeaponName)
	tool:SetAttribute("WeaponId", resolvedWeaponName)
	debug_log(
		("Tag aplicada em %s -> WeaponKey=%s WeaponId=%s (pedido=%s)")
			:format(tool.Name, tostring(tool:GetAttribute("WeaponKey")), tostring(tool:GetAttribute("WeaponId")), requestedWeaponName)
	)
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
		debug_log("Template nao encontrado para arma equipada " .. selectedWeaponName .. "; tentando arma padrao.")
		template = find_weapon_template_by_name(ItemsDataDictionary.DEFAULT_WEAPON)
	end

	if not template then
		debug_log("Arma padrao " .. ItemsDataDictionary.DEFAULT_WEAPON .. " nao encontrada; tentando primeiro template disponivel.")
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
	tag_weapon_tool(backpackTool, selectedWeaponName)
	backpackTool.Parent = backpack

	if starterGear then
		local starterGearTool = template:Clone()
		tag_weapon_tool(starterGearTool, selectedWeaponName)
		starterGearTool.Parent = starterGear
	end

	debug_log(
		("%s recebeu arma inicial: %s (equippedData=%s, weaponKey=%s)")
			:format(player.Name, template.Name, selectedWeaponName, tostring(backpackTool:GetAttribute("WeaponKey")))
	)
end

local function equip_weapon_in_hand(player: Player, requestedWeaponName: string): ()
	task.spawn(function()
		local deadline = os.clock() + 3
		local expectedWeaponKey = WeaponSettings.ResolveWeaponKey(requestedWeaponName)

		while os.clock() < deadline do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local backpack = player:FindFirstChildOfClass("Backpack")

			if humanoid and backpack then
				for _, child in backpack:GetChildren() do
					if child:IsA("Tool") then
						local currentWeaponKey = WeaponSettings.ResolveTool(child)
						local matchesName = child.Name == requestedWeaponName
						local matchesKey = expectedWeaponKey ~= nil and currentWeaponKey == expectedWeaponKey

						if matchesName or matchesKey then
							humanoid:EquipTool(child)
							debug_log(player.Name .. " equipou na mao a arma de teste " .. child.Name .. ".")
							return
						end
					end
				end
			end

			task.wait()
		end

		warn("[PlayerLoadout] Nao foi possivel equipar na mao a arma de teste " .. requestedWeaponName .. " para " .. player.Name)
	end)
end

local function can_use_test_weapon_commands(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end

	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end

	if game.PrivateServerOwnerId ~= 0 and player.UserId == game.PrivateServerOwnerId then
		return true
	end

	return false
end

local function get_owned_weapons_with_test_weapon(player: Player, weaponName: string): { string }
	local normalizedWeapons = normalize_owned_weapons(
		DataUtility.server.get(player, "WeaponsOwned"),
		DataUtility.server.get(player, "Skins")
	)

	if not has_weapon(normalizedWeapons, weaponName) then
		table.insert(normalizedWeapons, weaponName)
	end

	return normalizedWeapons
end

local function spawn_test_weapon(player: Player, requestedIdentifier: string): ()
	local template, resolvedWeaponName = find_weapon_template_by_identifier(requestedIdentifier)

	if not template or not resolvedWeaponName then
		warn("[PlayerLoadout] Comando de teste falhou; arma nao encontrada: " .. requestedIdentifier)
		return
	end

	local nextOwnedWeapons = get_owned_weapons_with_test_weapon(player, resolvedWeaponName)
	DataUtility.server.set(player, "WeaponsOwned", nextOwnedWeapons)
	DataUtility.server.set(player, "EquippedWeapon", resolvedWeaponName)

	apply_player_weapon_loadout(player)
	equip_weapon_in_hand(player, resolvedWeaponName)

	debug_log(
		("%s executou comando de teste e trocou para a arma %s.")
			:format(player.Name, resolvedWeaponName)
	)
end

local function print_available_test_weapons(player: Player): ()
	local weaponNames: { string } = {}

	for _, entry in get_available_weapon_templates() do
		table.insert(weaponNames, entry.name)
	end

	debug_log(
		("Armas disponiveis para teste por %s: %s")
			:format(player.Name, table.concat(weaponNames, ", "))
	)
end

local function on_player_chatted(player: Player, message: string): ()
	if not can_use_test_weapon_commands(player) then
		return
	end

	local trimmedMessage = string.match(message, "^%s*(.-)%s*$") or ""
	if trimmedMessage == "" then
		return
	end

	local commandName, commandArgument = string.match(trimmedMessage, "^(%S+)%s*(.-)$")
	if not commandName then
		return
	end

	commandName = string.lower(commandName)
	commandArgument = commandArgument or ""
	commandArgument = string.match(commandArgument, "^%s*(.-)%s*$") or ""

	if TEST_WEAPON_LIST_COMMANDS[commandName] then
		print_available_test_weapons(player)
		return
	end

	if not TEST_WEAPON_COMMAND_PREFIXES[commandName] then
		return
	end

	if commandArgument == "" then
		warn("[PlayerLoadout] Uso do comando: !gun <NomeDaArma> ou !weapons")
		return
	end

	spawn_test_weapon(player, commandArgument)
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
	player.Chatted:Connect(function(message: string)
		on_player_chatted(player, message)
	end)

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

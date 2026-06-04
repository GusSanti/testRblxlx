------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//VARIABLES
local items = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("CharacterItems")
local CharacterCreatorRE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CharacterCreatorEvent")

local DataUtility = require(
	ReplicatedStorage:WaitForChild("Modules")
		:WaitForChild("Utility")
		:WaitForChild("DataUtility")
)

------------------//CONSTANTS
local DATA_PATH = "CurrentItems"
local CURRENT_ITEMS_FOLDER_NAME = "CurrentItems"
local MAX_ITEMS_TO_EQUIP = 24
local MAX_ACCESSORIES = 10
local MIN_SECONDS_BETWEEN_EQUIP = 0.2
local MAX_PROFILE_LOAD_RETRIES = 3
local PROFILE_RETRY_DELAY = 1

local BLOCKED_ITEM_NAMES: { [string]: boolean } = {
	["Police Top"] = true,
	["Police Bottom"] = true,
	["bon bon"] = true,
	["sigma"] = true,
}
local equipRequestTimesByUserId: { [number]: number } = {}

------------------//FUNCTIONS
local function get_or_create_current_items_folder(player: Player): Folder
	local folder = player:FindFirstChild(CURRENT_ITEMS_FOLDER_NAME) :: Folder?

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = CURRENT_ITEMS_FOLDER_NAME
		folder.Parent = player
	end

	return folder
end

local function is_item_name_blocked(itemName: string): boolean
	return BLOCKED_ITEM_NAMES[itemName] == true
end

local function is_wearable_instance(instance: Instance): boolean
	return instance:IsA("Shirt") or instance:IsA("Pants") or instance:IsA("Accessory")
end

local function resolve_wearable_from_instance(instance: Instance): Instance?
	if is_wearable_instance(instance) then
		return instance
	end

	return instance:FindFirstChildOfClass("Shirt")
		or instance:FindFirstChildOfClass("Pants")
		or instance:FindFirstChildOfClass("Accessory")
end

local function find_wearable_item(itemName: string): Instance?
	if is_item_name_blocked(itemName) then
		return nil
	end

	local found = items:FindFirstChild(itemName, true)

	if not found then
		return nil
	end

	local wearable = resolve_wearable_from_instance(found)

	if not wearable then
		return nil
	end

	if is_item_name_blocked(wearable.Name) then
		return nil
	end

	return wearable
end

local function get_first_allowed_wearable_by_class(className: string, usedNames: { [string]: boolean }): Instance?
	for _, descendant in items:GetDescendants() do
		if descendant:IsA(className) and not is_item_name_blocked(descendant.Name) and not usedNames[descendant.Name] then
			return descendant
		end
	end

	return nil
end

local function collect_current_item_names(currentItems: Folder): { string }
	local itemNames: { string } = {}

	for _, item in currentItems:GetChildren() do
		if is_wearable_instance(item) then
			table.insert(itemNames, item.Name)
		end
	end

	return itemNames
end

local function sanitize_item_names(rawItems: any): { string }
	local sanitized: { string } = {}
	local seenNames: { [string]: boolean } = {}
	local hasShirt = false
	local hasPants = false
	local accessoryCount = 0

	if type(rawItems) ~= "table" then
		return sanitized
	end

	for _, rawItemName in rawItems do
		if #sanitized >= MAX_ITEMS_TO_EQUIP then
			break
		end

		if type(rawItemName) == "string" and not seenNames[rawItemName] and not is_item_name_blocked(rawItemName) then
			local wearable = find_wearable_item(rawItemName)

			if wearable then
				local wearableName = wearable.Name

				if not seenNames[wearableName] then
					local shouldAdd = false

					if wearable:IsA("Shirt") then
						if not hasShirt then
							hasShirt = true
							shouldAdd = true
						end
					elseif wearable:IsA("Pants") then
						if not hasPants then
							hasPants = true
							shouldAdd = true
						end
					elseif wearable:IsA("Accessory") then
						if accessoryCount < MAX_ACCESSORIES then
							accessoryCount += 1
							shouldAdd = true
						end
					end

					if shouldAdd then
						table.insert(sanitized, wearableName)
						seenNames[rawItemName] = true
						seenNames[wearableName] = true
					end
				end
			end
		end
	end

	return sanitized
end

local function ensure_default_clothes(currentItems: Folder): ()
	local hasShirt = false
	local hasPants = false
	local usedNames: { [string]: boolean } = {}

	for _, item in currentItems:GetChildren() do
		usedNames[item.Name] = true

		if item:IsA("Shirt") then
			hasShirt = true
		elseif item:IsA("Pants") then
			hasPants = true
		end
	end

	if not hasShirt then
		local defaultShirt = get_first_allowed_wearable_by_class("Shirt", usedNames)

		if defaultShirt then
			local shirtClone = defaultShirt:Clone()
			shirtClone.Parent = currentItems
			usedNames[shirtClone.Name] = true
		end
	end

	if not hasPants then
		local defaultPants = get_first_allowed_wearable_by_class("Pants", usedNames)

		if defaultPants then
			local pantsClone = defaultPants:Clone()
			pantsClone.Parent = currentItems
		end
	end
end

local function rebuild_current_items_from_names(player: Player, rawItems: any): Folder
	local currentItems = get_or_create_current_items_folder(player)
	currentItems:ClearAllChildren()

	local sanitizedNames = sanitize_item_names(rawItems)

	for _, itemName in sanitizedNames do
		local wearable = find_wearable_item(itemName)

		if wearable then
			wearable:Clone().Parent = currentItems
		end
	end

	ensure_default_clothes(currentItems)
	return currentItems
end

local function save_current_items_to_profile(player: Player): ()
	local currentItems = get_or_create_current_items_folder(player)
	ensure_default_clothes(currentItems)

	local itemNames = sanitize_item_names(collect_current_item_names(currentItems))

	DataUtility.server.set(player, DATA_PATH, itemNames)
end

local function clear_character_items(character: Model): ()
	for _, child in character:GetChildren() do
		if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("Accessory") then
			child:Destroy()
		end
	end
end

local function load_avatar(player: Player): ()
	local currentItems = get_or_create_current_items_folder(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	ensure_default_clothes(currentItems)
	clear_character_items(character)

	for _, item in currentItems:GetChildren() do
		if item:IsA("Shirt") or item:IsA("Pants") then
			item:Clone().Parent = character
		elseif item:IsA("Accessory") then
			humanoid:AddAccessory(item:Clone())
		end
	end
end

local function load_saved_items_from_profile(player: Player, attempt: number?): ()
	local tryNumber = attempt or 1
	local savedItems = DataUtility.server.get(player, DATA_PATH)

	if savedItems == nil and tryNumber < MAX_PROFILE_LOAD_RETRIES then
		task.delay(PROFILE_RETRY_DELAY, function()
			if player.Parent == Players then
				load_saved_items_from_profile(player, tryNumber + 1)
			end
		end)
		return
	end

	rebuild_current_items_from_names(player, savedItems)
	save_current_items_to_profile(player)
end

local function equip_items(player: Player, itemsList: {any}): ()
	if type(itemsList) ~= "table" then
		return
	end

	local now = os.clock()
	local lastRequestAt = equipRequestTimesByUserId[player.UserId]

	if lastRequestAt and now - lastRequestAt < MIN_SECONDS_BETWEEN_EQUIP then
		return
	end

	equipRequestTimesByUserId[player.UserId] = now

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local currentItems = rebuild_current_items_from_names(player, itemsList)
	clear_character_items(character)

	for _, item in currentItems:GetChildren() do
		local newItem = item:Clone()

		if newItem:IsA("Shirt") or newItem:IsA("Pants") then
			newItem.Parent = character
		elseif newItem:IsA("Accessory") then
			humanoid:AddAccessory(newItem)
		end
	end

	save_current_items_to_profile(player)
end

------------------//MAIN
Players.PlayerAdded:Connect(function(player: Player)
	get_or_create_current_items_folder(player)

	load_saved_items_from_profile(player)

	player.CharacterAdded:Connect(function()
		task.defer(function()
			load_avatar(player)
		end)
	end)

	if player.Character then
		load_avatar(player)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	equipRequestTimesByUserId[player.UserId] = nil
	save_current_items_to_profile(player)
end)

CharacterCreatorRE.OnServerEvent:Connect(function(player: Player, itemsList: {any})
	equip_items(player, itemsList)
end)

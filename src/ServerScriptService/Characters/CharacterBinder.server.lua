------------------//SERVICES
local Players: Players = game:GetService("Players")

------------------//CONSTANTS
local CHARACTERS_FOLDER_NAME = "Characters"

------------------//VARIABLES
local charactersFolder: Folder? = nil

------------------//FUNCTIONS
local function debug_log(message: string): ()
	print("[CharactersFolder] " .. message)
end

local function ensure_characters_folder(): Folder
	if charactersFolder and charactersFolder.Parent == workspace and charactersFolder.Name == CHARACTERS_FOLDER_NAME then
		return charactersFolder
	end

	local folder = workspace:FindFirstChild(CHARACTERS_FOLDER_NAME)

	if folder and folder:IsA("Folder") then
		charactersFolder = folder
		return folder
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = CHARACTERS_FOLDER_NAME
	newFolder.Parent = workspace
	charactersFolder = newFolder
	debug_log("Pasta workspace." .. CHARACTERS_FOLDER_NAME .. " criada.")
	return newFolder
end

local function mark_model_as_participant(model: Model, player: Player?): ()
	model:SetAttribute("IsMatchParticipant", true)

	if player then
		model:SetAttribute("OwnerUserId", player.UserId)
		model:SetAttribute("OwnerName", player.Name)
		return
	end

	model:SetAttribute("OwnerUserId", 0)
	model:SetAttribute("OwnerName", "Model")
end

local function move_character_to_characters_folder(player: Player, character: Model): ()
	local folder = ensure_characters_folder()

	if character.Parent ~= folder then
		character.Parent = folder
	end

	mark_model_as_participant(character, player)
	debug_log("Character de " .. player.Name .. " movido para workspace." .. CHARACTERS_FOLDER_NAME .. ".")
end

local function on_character_added(player: Player, character: Model): ()
	if not character then
		return
	end

	task.defer(function()
		move_character_to_characters_folder(player, character)
	end)
end

local function on_player_added(player: Player): ()
	player.CharacterAdded:Connect(function(character: Model)
		on_character_added(player, character)
	end)

	local currentCharacter = player.Character

	if currentCharacter then
		on_character_added(player, currentCharacter)
	end
end

local function on_characters_folder_child_added(child: Instance): ()
	if not child:IsA("Model") then
		return
	end

	local ownerUserId = child:GetAttribute("OwnerUserId")

	if typeof(ownerUserId) == "number" and ownerUserId > 0 then
		return
	end

	mark_model_as_participant(child, nil)
	debug_log("Modelo " .. child.Name .. " registrado como participante sem Player.")
end

------------------//MAIN FUNCTIONS
local folder = ensure_characters_folder()

folder.ChildAdded:Connect(on_characters_folder_child_added)

for _, child in folder:GetChildren() do
	on_characters_folder_child_added(child)
end

for _, player in Players:GetPlayers() do
	on_player_added(player)
end

Players.PlayerAdded:Connect(on_player_added)

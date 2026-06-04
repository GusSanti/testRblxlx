------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService: RunService = game:GetService("RunService")
local StarterGui: StarterGui = game:GetService("StarterGui")
local TextChatService: TextChatService = game:GetService("TextChatService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))

local MAP_SELECTED_STROKE = Color3.fromRGB(245, 235, 120)
local MAP_NORMAL_STROKE = Color3.fromRGB(90, 90, 90)
local DEBUG_PREFIX = "[ChooseMapHud]"

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Warn = Color3.fromRGB(255, 218, 120),
	Error = Color3.fromRGB(255, 135, 135),
}

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local matchGui: ScreenGui = playerGui:WaitForChild("Match") :: ScreenGui

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local matchSessionRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.MATCH_SESSION_REMOTE_EVENT_NAME) :: RemoteEvent

local chooseMapFrame: GuiObject? = nil
local chooseMapHolder: GuiObject? = nil
local chooseMapTemplate: ImageButton? = nil
local chooseMapTimerLabel: TextLabel? = nil

local mapButtons: { [string]: ImageButton } = {}
local mapCatalog: { [string]: { id: string, image: string, displayName: string } } = {}
local mapOrder: { string } = {}
local mapVotes: { [string]: number } = {}
local mapCatalogSignature = ""

local mapVoteOpen = false
local mapVotePhase = ""
local mapVotePhaseEndsAt = 0
local myMapVote: string? = nil
local isMatchState = false

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

local function format_time(seconds: number): string
	local safeSeconds = math.max(0, math.floor(seconds))
	local minutes = math.floor(safeSeconds / 60)
	local remainingSeconds = safeSeconds % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function find_choose_map_ui(): ()
	local instance = matchGui:FindFirstChild("ChooseMap")

	if not instance then
		for _, descendant in matchGui:GetDescendants() do
			if descendant.Name == "ChooseMap" and descendant:IsA("GuiObject") then
				instance = descendant
				break
			end
		end
	end

	if not instance or not instance:IsA("GuiObject") then
		send_debug("ChooseMap nao encontrado.", "Error")
		return
	end

	chooseMapFrame = instance
	chooseMapFrame.Visible = false

	local holder = chooseMapFrame:FindFirstChild("Holder")
	if holder and holder:IsA("GuiObject") then
		chooseMapHolder = holder
	else
		send_debug("ChooseMap.Holder nao encontrado.", "Error")
	end

	local timer = chooseMapFrame:FindFirstChild("Timer")
	if timer and timer:IsA("TextLabel") then
		chooseMapTimerLabel = timer
	else
		send_debug("ChooseMap.Timer nao encontrado.", "Error")
	end

	if chooseMapHolder then
		local template = chooseMapHolder:FindFirstChild("Template")

		if template and template:IsA("ImageButton") then
			chooseMapTemplate = template
			chooseMapTemplate.Visible = false
		else
			send_debug("ChooseMap.Template nao encontrado ou invalido.", "Error")
		end
	end
end

local function clear_map_buttons(): ()
	if not chooseMapHolder or not chooseMapTemplate then
		return
	end

	for _, child in chooseMapHolder:GetChildren() do
		if child ~= chooseMapTemplate and not child:IsA("UIGridLayout") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	mapButtons = {}
end

local function set_button_selected(button: ImageButton, selected: boolean): ()
	local stroke = button:FindFirstChildOfClass("UIStroke")

	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = button
	end

	stroke.Color = if selected then MAP_SELECTED_STROKE else MAP_NORMAL_STROKE
	stroke.Thickness = if selected then 3 else 2
end

local function send_vote(mapId: string): ()
	matchSessionRemote:FireServer("VoteMap", {
		mapId = mapId,
	})

	send_debug("Voto enviado: " .. mapId, "Info")
end

local function get_or_create_map_button(mapId: string): ImageButton?
	local existing = mapButtons[mapId]

	if existing and existing.Parent then
		return existing
	end

	if not chooseMapHolder or not chooseMapTemplate then
		return nil
	end

	local mapData = mapCatalog[mapId]

	if not mapData then
		return nil
	end

	local button = chooseMapTemplate:Clone()
	button.Name = "Map_" .. mapId
	button.Visible = true
	button.Image = mapData.image
	button.Parent = chooseMapHolder

	button.MouseButton1Click:Connect(function()
		if not mapVoteOpen then
			return
		end

		send_vote(mapId)
	end)

	mapButtons[mapId] = button
	return button
end

local function refresh_map_buttons(): ()
	for _, mapId in mapOrder do
		local button = get_or_create_map_button(mapId)

		if button then
			local countLabel = button:FindFirstChild("Count")
			local voteCount = mapVotes[mapId] or 0

			if countLabel and countLabel:IsA("TextLabel") then
				countLabel.Text = tostring(voteCount)
			end

			set_button_selected(button, myMapVote == mapId)
		end
	end
end

local function refresh_visibility(): ()
	if not chooseMapFrame then
		return
	end

	chooseMapFrame.Visible = isMatchState and mapVoteOpen
end

local function update_timer_text(): ()
	if not chooseMapTimerLabel then
		return
	end

	if not mapVoteOpen then
		chooseMapTimerLabel.Text = "00:00"
		return
	end

	if mapVotePhase == "LoadingPlayers" then
		chooseMapTimerLabel.Text = "Waiting players load"
		return
	end

	if mapVotePhase ~= "MapVote" then
		chooseMapTimerLabel.Text = "00:00"
		return
	end

	chooseMapTimerLabel.Text = format_time(math.max(0, mapVotePhaseEndsAt - os.time()))
end

local function apply_maps_payload(mapsPayload: any): ()
	if typeof(mapsPayload) ~= "table" then
		return
	end

	local nextCatalog: { [string]: { id: string, image: string, displayName: string } } = {}
	local nextOrder: { string } = {}
	local signatureParts: { string } = {}

	for _, mapData in mapsPayload do
		if typeof(mapData) == "table" and typeof(mapData.id) == "string" and typeof(mapData.image) == "string" then
			local displayName = if typeof(mapData.displayName) == "string" then mapData.displayName else mapData.id

			nextCatalog[mapData.id] = {
				id = mapData.id,
				image = mapData.image,
				displayName = displayName,
			}

			table.insert(nextOrder, mapData.id)
			table.insert(signatureParts, mapData.id .. "|" .. mapData.image)
		end
	end

	local nextSignature = table.concat(signatureParts, ",")

	if nextSignature ~= mapCatalogSignature then
		mapCatalogSignature = nextSignature
		mapCatalog = nextCatalog
		mapOrder = nextOrder
		clear_map_buttons()
		send_debug("Catalogo de mapas atualizado: " .. tostring(#mapOrder), "Info")
		return
	end

	mapCatalog = nextCatalog
	mapOrder = nextOrder
end

local function apply_votes_payload(votesPayload: any): ()
	local nextVotes: { [string]: number } = {}

	for _, mapId in mapOrder do
		local count = 0

		if typeof(votesPayload) == "table" and typeof(votesPayload[mapId]) == "number" then
			count = math.max(0, math.floor(votesPayload[mapId]))
		end

		nextVotes[mapId] = count
	end

	mapVotes = nextVotes
end

local function apply_match_state(payload: any): ()
	if typeof(payload) ~= "table" then
		return
	end

	isMatchState = payload.isMatch == true
	mapVoteOpen = payload.mapVoteOpen == true
	mapVotePhase = if typeof(payload.phase) == "string" then payload.phase else ""
	mapVotePhaseEndsAt = if typeof(payload.phaseEndsAt) == "number" then payload.phaseEndsAt else 0
	myMapVote = if typeof(payload.myMapVote) == "string" then payload.myMapVote else nil

	apply_maps_payload(payload.maps)
	apply_votes_payload(payload.mapVotes)
	refresh_map_buttons()
	refresh_visibility()
	update_timer_text()
end

------------------//MAIN FUNCTIONS
matchSessionRemote.OnClientEvent:Connect(function(action: string, payload: any)
	if action ~= "State" then
		return
	end

	apply_match_state(payload)
end)

RunService.RenderStepped:Connect(function()
	update_timer_text()
end)

------------------//INIT
find_choose_map_ui()
refresh_visibility()
update_timer_text()
send_debug("Inicializado.", "Info")

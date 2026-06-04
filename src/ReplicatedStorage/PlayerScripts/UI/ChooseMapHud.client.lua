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
local MAP_SELECT_NAME = "MapSelect"
local MAP_TEMPLATE_NAME = "MapTemplate"
local PLAYERS_CONTAINER_NAME = "Players"
local FRIEND_TEMPLATE_NAME = "friend"
local ENEMY_TEMPLATE_NAME = "enemy"
local PREVIEW_NAME = "preview"
local NAME_LABEL_NAME = "NameMap"
local MAPS_CONTAINER_NAME = "Maps"
local TIME_CONTAINER_NAME = "Time"
local TIME_LABEL_NAME = "TextTime"

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Warn = Color3.fromRGB(255, 218, 120),
	Error = Color3.fromRGB(255, 135, 135),
}

------------------//VARIABLES
type MapCatalogEntry = {
	id: string,
	image: string,
	displayName: string,
}

type VoteVoterEntry = {
	userId: number,
	teamName: string?,
}

type MapCardRefs = {
	root: GuiObject,
	players: GuiObject,
	friendTemplate: GuiObject?,
	enemyTemplate: GuiObject?,
}

local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local matchGui: ScreenGui = playerGui:WaitForChild("Match") :: ScreenGui

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local matchSessionRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.MATCH_SESSION_REMOTE_EVENT_NAME) :: RemoteEvent

local mapSelectFrame: GuiObject? = nil
local mapsContainer: GuiObject? = nil
local mapTemplate: GuiObject? = nil
local timerTextLabel: TextLabel? = nil

local mapCards: { [string]: MapCardRefs } = {}
local mapCatalog: { [string]: MapCatalogEntry } = {}
local mapOrder: { string } = {}
local mapVotes: { [string]: number } = {}
local mapVoteVoters: { [string]: { VoteVoterEntry } } = {}
local thumbnailCache: { [number]: string } = {}

local mapCatalogSignature = ""
local mapVotersSignature = ""
local mapVoteOpen = false
local mapVotePhase = ""
local mapVotePhaseEndsAt = 0
local myMapVote: string? = nil
local myTeamName: string? = nil
local isMatchState = false
local matchGuiDescendantAddedConnection: RBXScriptConnection? = nil

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

local function get_or_fetch_thumbnail(userId: number): string
	local cached = thumbnailCache[userId]

	if cached then
		return cached
	end

	local content = ""
	local success = pcall(function()
		local image, _ = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		content = image
	end)

	if success and content ~= "" then
		thumbnailCache[userId] = content
		return content
	end

	return ""
end

local function split_path(path: string): { string }
	local parts: { string } = {}

	for piece in string.gmatch(path, "[^%.]+") do
		table.insert(parts, piece)
	end

	return parts
end

local function find_descendant_by_path(root: Instance, path: string): Instance?
	local current: Instance? = root

	for _, piece in split_path(path) do
		if not current then
			return nil
		end

		current = current:FindFirstChild(piece)
	end

	return current
end

local function is_map_select_candidate(instance: Instance?): boolean
	if not instance or not instance:IsA("GuiObject") then
		return false
	end

	local maps = instance:FindFirstChild(MAPS_CONTAINER_NAME)
	local time = instance:FindFirstChild(TIME_CONTAINER_NAME)

	if not maps or not maps:IsA("GuiObject") or not time or not time:IsA("GuiObject") then
		return false
	end

	local template = maps:FindFirstChild(MAP_TEMPLATE_NAME)
	local textTime = time:FindFirstChild(TIME_LABEL_NAME)

	return template ~= nil and template:IsA("GuiObject") and textTime ~= nil and textTime:IsA("TextLabel")
end

local function find_map_select_ui(): ()
	if mapSelectFrame and mapSelectFrame.Parent and mapsContainer and mapTemplate and timerTextLabel then
		return
	end

	local instance = matchGui:FindFirstChild(MAP_SELECT_NAME)

	if not is_map_select_candidate(instance) then
		for _, descendant in matchGui:GetDescendants() do
			if descendant.Name == MAP_SELECT_NAME and is_map_select_candidate(descendant) then
				instance = descendant
				break
			end
		end
	end

	if not instance or not instance:IsA("GuiObject") then
		send_debug("MapSelect nao encontrado.", "Error")
		return
	end

	mapSelectFrame = instance
	mapSelectFrame.Visible = false

	local mapsInstance = mapSelectFrame:FindFirstChild(MAPS_CONTAINER_NAME)
	local timeInstance = mapSelectFrame:FindFirstChild(TIME_CONTAINER_NAME)

	if mapsInstance and mapsInstance:IsA("GuiObject") then
		mapsContainer = mapsInstance
	end

	if timeInstance and timeInstance:IsA("GuiObject") then
		local textTime = timeInstance:FindFirstChild(TIME_LABEL_NAME)

		if textTime and textTime:IsA("TextLabel") then
			timerTextLabel = textTime
		end
	end

	if not mapsContainer then
		send_debug("MapSelect.Maps nao encontrado.", "Error")
		return
	end

	local template = mapsContainer:FindFirstChild(MAP_TEMPLATE_NAME)

	if not template or not template:IsA("GuiObject") then
		send_debug("MapSelect.Maps.MapTemplate nao encontrado.", "Error")
		return
	end

	mapTemplate = template
	mapTemplate.Visible = false
end

local function clear_container_children(container: Instance, keepNames: { [string]: boolean }): ()
	for _, child in container:GetChildren() do
		if not keepNames[child.Name] and not child:IsA("UIGridLayout") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function clear_map_cards(): ()
	if not mapsContainer or not mapTemplate then
		return
	end

	clear_container_children(mapsContainer, {
		[mapTemplate.Name] = true,
	})

	mapCards = {}
end

local function set_map_card_selected(cardRoot: GuiObject, selected: boolean): ()
	local stroke = cardRoot:FindFirstChildOfClass("UIStroke")

	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = cardRoot
	end

	stroke.Color = if selected then MAP_SELECTED_STROKE else MAP_NORMAL_STROKE
	stroke.Thickness = if selected then 3 else 2
end

local function send_vote(mapId: string): ()
	matchSessionRemote:FireServer("VoteMap", {
		mapId = mapId,
	})
end

local function connect_vote_action(target: GuiObject, mapId: string): ()
	if target:IsA("GuiButton") then
		target.Activated:Connect(function()
			if not mapVoteOpen then
				return
			end

			send_vote(mapId)
		end)
		return
	end

	target.InputBegan:Connect(function(input: InputObject)
		if not mapVoteOpen then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			send_vote(mapId)
		end
	end)
end

local function get_or_create_map_card(mapId: string): MapCardRefs?
	local existing = mapCards[mapId]

	if existing and existing.root.Parent then
		return existing
	end

	if not mapsContainer or not mapTemplate then
		return nil
	end

	local mapData = mapCatalog[mapId]

	if not mapData then
		return nil
	end

	local cardRoot = mapTemplate:Clone()
	cardRoot.Name = "Map_" .. mapId
	cardRoot.Visible = true
	cardRoot.Parent = mapsContainer

	local preview = cardRoot:FindFirstChild(PREVIEW_NAME, true)
	if preview and preview:IsA("ImageLabel") then
		preview.Image = mapData.image
	elseif preview and preview:IsA("ImageButton") then
		preview.Image = mapData.image
	end

	local nameLabel = cardRoot:FindFirstChild(NAME_LABEL_NAME, true)
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = mapData.displayName
	elseif nameLabel and nameLabel:IsA("TextButton") then
		nameLabel.Text = mapData.displayName
	end

	local playersContainer = cardRoot:FindFirstChild(PLAYERS_CONTAINER_NAME, true)
	if not playersContainer or not playersContainer:IsA("GuiObject") then
		cardRoot:Destroy()
		return nil
	end

	local friendTemplate = playersContainer:FindFirstChild(FRIEND_TEMPLATE_NAME)
	local enemyTemplate = playersContainer:FindFirstChild(ENEMY_TEMPLATE_NAME)

	if friendTemplate and friendTemplate:IsA("GuiObject") then
		friendTemplate.Visible = false
	end

	if enemyTemplate and enemyTemplate:IsA("GuiObject") then
		enemyTemplate.Visible = false
	end

	connect_vote_action(cardRoot, mapId)

	if preview and preview:IsA("GuiButton") then
		connect_vote_action(preview, mapId)
	end

	local refs: MapCardRefs = {
		root = cardRoot,
		players = playersContainer,
		friendTemplate = if friendTemplate and friendTemplate:IsA("GuiObject") then friendTemplate else nil,
		enemyTemplate = if enemyTemplate and enemyTemplate:IsA("GuiObject") then enemyTemplate else nil,
	}

	mapCards[mapId] = refs
	return refs
end

local function clear_viewport(viewport: ViewportFrame): ()
	for _, child in viewport:GetChildren() do
		child:Destroy()
	end

	viewport.CurrentCamera = nil
end

local function build_character_clone_for_viewport(userId: number): Model?
	local targetPlayer = Players:GetPlayerByUserId(userId)

	if not targetPlayer then
		return nil
	end

	local character = targetPlayer.Character

	if not character or not character:IsA("Model") then
		return nil
	end

	local originalArchivable = character.Archivable
	character.Archivable = true

	local success, cloneResult = pcall(function()
		return character:Clone()
	end)

	character.Archivable = originalArchivable

	if not success or not cloneResult or not cloneResult:IsA("Model") then
		return nil
	end

	local clone = cloneResult
	local humanoid = clone:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	return clone
end

local function render_player_viewport(viewport: ViewportFrame, userId: number): boolean
	clear_viewport(viewport)

	local characterClone = build_character_clone_for_viewport(userId)

	if not characterClone then
		return false
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	characterClone.Parent = worldModel

	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local head = characterClone:FindFirstChild("Head")
	local humanoidRootPart = characterClone:FindFirstChild("HumanoidRootPart")

	if head and head:IsA("BasePart") then
		local faceFocus = head.Position + Vector3.new(0, 0.05, 0)
		local faceDirection = head.CFrame.LookVector

		if faceDirection.Magnitude < 0.001 then
			faceDirection = Vector3.new(0, 0, -1)
		end

		local cameraDistance = math.max(head.Size.Y * 3.2, 1.9)
		local cameraHeightOffset = head.Size.Y * 0.08
		local cameraPosition = faceFocus + faceDirection.Unit * cameraDistance + Vector3.new(0, cameraHeightOffset, 0)

		camera.FieldOfView = 23
		camera.CFrame = CFrame.lookAt(cameraPosition, faceFocus)
		return true
	end

	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		local focusPosition = humanoidRootPart.Position + Vector3.new(0, 1.45, 0)
		camera.FieldOfView = 28
		camera.CFrame = CFrame.lookAt(focusPosition + Vector3.new(0, 0.05, 2.4), focusPosition)
		return true
	end

	return true
end

local function apply_vote_badge_visuals(badge: GuiObject, userId: number): ()
	if badge:IsA("ImageLabel") or badge:IsA("ImageButton") then
		local currentImage = badge.Image

		if currentImage == "" then
			local thumbnail = get_or_fetch_thumbnail(userId)

			if thumbnail ~= "" then
				badge.Image = thumbnail
			end
		end
	end

	local viewport = badge:FindFirstChildOfClass("ViewportFrame") or find_descendant_by_path(badge, "ViewportFrame")

	if viewport and viewport:IsA("ViewportFrame") then
		local rendered = render_player_viewport(viewport, userId)

		if not rendered then
			viewport.Visible = false
		else
			viewport.Visible = true
		end
	end
end

local function clear_vote_badges(card: MapCardRefs): ()
	if not card.players then
		return
	end

	local keepNames: { [string]: boolean } = {}

	if card.friendTemplate then
		keepNames[card.friendTemplate.Name] = true
	end

	if card.enemyTemplate then
		keepNames[card.enemyTemplate.Name] = true
	end

	clear_container_children(card.players, keepNames)
end

local function get_sorted_voters(voters: { VoteVoterEntry }): { VoteVoterEntry }
	local sorted: { VoteVoterEntry } = {}

	for _, voter in voters do
		table.insert(sorted, voter)
	end

	table.sort(sorted, function(a: VoteVoterEntry, b: VoteVoterEntry): boolean
		local rankA = 3
		local rankB = 3

		if a.userId == player.UserId then
			rankA = 1
		elseif myTeamName ~= nil and a.teamName == myTeamName then
			rankA = 2
		end

		if b.userId == player.UserId then
			rankB = 1
		elseif myTeamName ~= nil and b.teamName == myTeamName then
			rankB = 2
		end

		if rankA ~= rankB then
			return rankA < rankB
		end

		return a.userId < b.userId
	end)

	return sorted
end

local function render_vote_badges_for_map(mapId: string): ()
	local card = mapCards[mapId]

	if not card or not card.root.Parent then
		return
	end

	clear_vote_badges(card)

	local voters = get_sorted_voters(mapVoteVoters[mapId] or {})

	for index, voter in voters do
		local useFriendTemplate = voter.userId == player.UserId
			or (myTeamName ~= nil and voter.teamName == myTeamName)

		local sourceTemplate = if useFriendTemplate then card.friendTemplate else card.enemyTemplate

		if sourceTemplate then
			local badge = sourceTemplate:Clone()
			badge.Name = sourceTemplate.Name .. "_" .. tostring(voter.userId)
			badge.LayoutOrder = index
			badge.Visible = true
			badge.Parent = card.players
			apply_vote_badge_visuals(badge, voter.userId)
		end
	end
end

local function refresh_map_cards(): ()
	for _, mapId in mapOrder do
		local card = get_or_create_map_card(mapId)

		if card then
			set_map_card_selected(card.root, myMapVote == mapId)
			render_vote_badges_for_map(mapId)
		end
	end
end

local function refresh_visibility(): ()
	if not mapSelectFrame then
		return
	end

	mapSelectFrame.Visible = isMatchState and mapVoteOpen
end

local function update_timer_text(): ()
	if not timerTextLabel then
		return
	end

	if not mapVoteOpen or (mapVotePhase ~= "LoadingPlayers" and mapVotePhase ~= "MapVote") then
		timerTextLabel.Text = "00:00"
		return
	end

	timerTextLabel.Text = format_time(math.max(0, mapVotePhaseEndsAt - os.time()))
end

local function apply_maps_payload(mapsPayload: any): ()
	if typeof(mapsPayload) ~= "table" then
		return false
	end

	local nextCatalog: { [string]: MapCatalogEntry } = {}
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
			table.insert(signatureParts, mapData.id .. "|" .. mapData.image .. "|" .. displayName)
		end
	end

	local nextSignature = table.concat(signatureParts, ",")
	local didChangeCatalog = nextSignature ~= mapCatalogSignature

	mapCatalog = nextCatalog
	mapOrder = nextOrder

	if didChangeCatalog then
		mapCatalogSignature = nextSignature
		clear_map_cards()
	end

	return didChangeCatalog
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

local function build_voters_signature(votersPayload: any): string
	if typeof(votersPayload) ~= "table" then
		return ""
	end

	local parts: { string } = {}

	for _, mapId in mapOrder do
		local mapParts: { string } = {}
		local voterList = votersPayload[mapId]

		if typeof(voterList) == "table" then
			for _, voter in voterList do
				if typeof(voter) == "table" and typeof(voter.userId) == "number" then
					local teamName = if typeof(voter.teamName) == "string" then voter.teamName else ""
					table.insert(mapParts, tostring(math.floor(voter.userId)) .. ":" .. teamName)
				end
			end
		end

		table.sort(mapParts)
		table.insert(parts, mapId .. "=" .. table.concat(mapParts, "|"))
	end

	return table.concat(parts, ";")
end

local function apply_vote_voters_payload(votersPayload: any): ()
	local nextVoters: { [string]: { VoteVoterEntry } } = {}

	for _, mapId in mapOrder do
		local entries: { VoteVoterEntry } = {}
		local voterList = typeof(votersPayload) == "table" and votersPayload[mapId] or nil

		if typeof(voterList) == "table" then
			for _, voter in voterList do
				if typeof(voter) == "table" and typeof(voter.userId) == "number" then
					table.insert(entries, {
						userId = math.floor(voter.userId),
						teamName = if typeof(voter.teamName) == "string" then voter.teamName else nil,
					})
				end
			end
		end

		nextVoters[mapId] = entries
	end

	mapVoteVoters = nextVoters
end

local function apply_match_state(payload: any): ()
	if typeof(payload) ~= "table" then
		return
	end

	local previousMyMapVote = myMapVote
	local previousMyTeamName = myTeamName

	isMatchState = payload.isMatch == true
	mapVoteOpen = payload.mapVoteOpen == true
	mapVotePhase = if typeof(payload.phase) == "string" then payload.phase else ""
	mapVotePhaseEndsAt = if typeof(payload.phaseEndsAt) == "number" then payload.phaseEndsAt else 0
	myMapVote = if typeof(payload.myMapVote) == "string" then payload.myMapVote else nil
	myTeamName = if typeof(payload.myTeamName) == "string" then payload.myTeamName else nil

	local didCatalogChange = apply_maps_payload(payload.maps)
	apply_votes_payload(payload.mapVotes)

	local nextVoterSignature = build_voters_signature(payload.mapVoteVoters)
	local didVotersChange = nextVoterSignature ~= mapVotersSignature
	local didMyVoteChange = previousMyMapVote ~= myMapVote
	local didMyTeamChange = previousMyTeamName ~= myTeamName

	apply_vote_voters_payload(payload.mapVoteVoters)

	if didVotersChange then
		mapVotersSignature = nextVoterSignature
	end

	if didCatalogChange or didVotersChange or didMyTeamChange then
		refresh_map_cards()
	else
		for _, mapId in mapOrder do
			local card = mapCards[mapId]

			if card then
				set_map_card_selected(card.root, myMapVote == mapId)
			end
		end
	end

	if didMyVoteChange and not (didCatalogChange or didVotersChange or didMyTeamChange) then
		for _, mapId in mapOrder do
			local card = mapCards[mapId]

			if card then
				set_map_card_selected(card.root, myMapVote == mapId)
			end
		end
	end

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
find_map_select_ui()

if matchGuiDescendantAddedConnection then
	matchGuiDescendantAddedConnection:Disconnect()
end

matchGuiDescendantAddedConnection = matchGui.DescendantAdded:Connect(function(descendant: Instance)
	if mapSelectFrame and mapSelectFrame.Parent and mapsContainer and mapTemplate and timerTextLabel then
		return
	end

	if descendant.Name == MAP_SELECT_NAME or descendant.Name == MAPS_CONTAINER_NAME or descendant.Name == MAP_TEMPLATE_NAME or descendant.Name == TIME_LABEL_NAME then
		task.defer(function()
			find_map_select_ui()
			refresh_map_cards()
			refresh_visibility()
			update_timer_text()
		end)
	end
end)

refresh_visibility()
update_timer_text()

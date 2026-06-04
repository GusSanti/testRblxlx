------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui: StarterGui = game:GetService("StarterGui")
local TextChatService: TextChatService = game:GetService("TextChatService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local PartyClientService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("PartyClientService"))
local PagesClientService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("PagesClientService"))

local INVITE_GREEN = Color3.fromRGB(64, 170, 105)
local INVITE_RED = Color3.fromRGB(186, 70, 70)
local INVITE_YELLOW = Color3.fromRGB(210, 170, 70)
local INVITE_DISABLED = Color3.fromRGB(72, 72, 72)

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Success = Color3.fromRGB(130, 255, 175),
	Warn = Color3.fromRGB(255, 218, 120),
	Error = Color3.fromRGB(255, 135, 135),
}

local DEBUG_PREFIX = "[PartyHud]"
local PARTY_ROLE_OWNER = "Owner"
local PARTY_ROLE_MEMBER = "Member"
local PARTY_ROLE_NONE = "None"
local PLAYER_LIST_PAGE_NAME = "PlayerList"

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local lobbyFrame: ScreenGui = playerGui:WaitForChild("Lobby") :: ScreenGui
local pagesFrame: ScreenGui = playerGui:WaitForChild("Pages") :: ScreenGui

local lobbyHolder: GuiObject? = nil
local inviteFrame: GuiObject? = nil

local playerListPage: GuiObject? = nil
local playerListContainer: GuiObject? = nil
local playerTemplate: Frame? = nil
local playerListToggle: GuiButton? = nil

local inviteList: GuiObject? = nil
local inviteTemplate: Frame? = nil

local yourPartyFrame: Frame? = nil
local leaveButton: GuiButton? = nil
local partyMemberTemplate: ImageButton? = nil

local removeSnapshotListener: (() -> ())? = nil
local removeDebugListener: (() -> ())? = nil

local thumbnailCache: { [number]: string } = {}
local isPlayerListVisible = true

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

local function send_system_message(message: string, colorName: string?): ()
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

local function clear_children(container: Instance, keepNames: { [string]: boolean }): ()
	for _, child in container:GetChildren() do
		if not keepNames[child.Name] and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
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

local function apply_thumbnail(imageObject: ImageLabel | ImageButton, userId: number): ()
	local cached = thumbnailCache[userId]

	if cached then
		imageObject.Image = cached
		return
	end

	task.spawn(function()
		local image = get_or_fetch_thumbnail(userId)

		if image ~= "" and imageObject.Parent then
			imageObject.Image = image
		end
	end)
end

local function get_local_party_role(snapshot: PartyClientService.SnapshotState): string
	local partyId = snapshot.party.partyId

	if not partyId then
		return PARTY_ROLE_NONE
	end

	if snapshot.party.ownerUserId == player.UserId then
		return PARTY_ROLE_OWNER
	end

	return PARTY_ROLE_MEMBER
end

local function get_player_party_lookup(snapshot: PartyClientService.SnapshotState): { [number]: PartyClientService.PlayerPartyState }
	local lookup: { [number]: PartyClientService.PlayerPartyState } = {}

	for _, playerState in snapshot.players do
		lookup[playerState.userId] = playerState
	end

	return lookup
end

local function has_template(instance: Instance?): boolean
	if not instance then
		return false
	end

	return instance:FindFirstChild("Template") ~= nil
end

local function is_player_list_container(instance: Instance?): boolean
	if not instance or not instance:IsA("GuiObject") then
		return false
	end

	local template = instance:FindFirstChild("Template")
	return template ~= nil and template:IsA("Frame")
end

local function is_player_list_page_candidate(instance: Instance?): boolean
	if not instance or not instance:IsA("GuiObject") then
		return false
	end

	if is_player_list_container(instance) then
		return true
	end

	local scrollingFrame = instance:FindFirstChild("ScrollingFrame")
	return is_player_list_container(scrollingFrame)
end

local function is_invite_list_container(instance: Instance?): boolean
	if not instance or not instance:IsA("GuiObject") then
		return false
	end

	local template = instance:FindFirstChild("Template")

	if not template or not template:IsA("Frame") then
		return false
	end

	return template:FindFirstChild("Accept") ~= nil and template:FindFirstChild("Denny") ~= nil
end

local function is_your_party_container(instance: Instance?): boolean
	if not instance or not instance:IsA("Frame") then
		return false
	end

	local leave = instance:FindFirstChild("Leave")
	local templatePlayer = instance:FindFirstChild("TemplatePlayer")
	return leave ~= nil and templatePlayer ~= nil and templatePlayer:IsA("ImageButton")
end

local function find_player_list_page(): GuiObject?
	local candidates: { Instance? } = {}

	table.insert(candidates, pagesFrame:FindFirstChild("PlayerList"))
	table.insert(candidates, inviteFrame and inviteFrame:FindFirstChild("PlayerList") or nil)
	table.insert(candidates, lobbyFrame:FindFirstChild("PlayerList"))
	table.insert(candidates, lobbyHolder and lobbyHolder:FindFirstChild("PlayerList") or nil)

	for _, candidate in candidates do
		if is_player_list_page_candidate(candidate) then
			return candidate :: GuiObject
		end
	end

	for _, descendant in lobbyFrame:GetDescendants() do
		if descendant.Name == "PlayerList" and is_player_list_page_candidate(descendant) then
			return descendant :: GuiObject
		end
	end

	return nil
end

local function resolve_player_list_container(pageObject: GuiObject): GuiObject?
	local scrollingFrame = pageObject:FindFirstChild("ScrollingFrame")
	if is_player_list_container(scrollingFrame) then
		return scrollingFrame :: GuiObject
	end

	if is_player_list_container(pageObject) then
		return pageObject
	end

	return nil
end

local function find_invite_list_container(): GuiObject?
	local candidates: { Instance? } = {}

	table.insert(candidates, inviteFrame and inviteFrame:FindFirstChild("InviteList") or nil)
	table.insert(candidates, lobbyFrame:FindFirstChild("InviteList"))

	for _, candidate in candidates do
		if is_invite_list_container(candidate) then
			return candidate :: GuiObject
		end
	end

	for _, descendant in lobbyFrame:GetDescendants() do
		if descendant.Name == "InviteList" and is_invite_list_container(descendant) then
			return descendant :: GuiObject
		end
	end

	return nil
end

local function find_your_party_container(): Frame?
	local candidates: { Instance? } = {}

	table.insert(candidates, inviteFrame and inviteFrame:FindFirstChild("YourParty") or nil)
	table.insert(candidates, lobbyFrame:FindFirstChild("YourParty"))

	for _, candidate in candidates do
		if is_your_party_container(candidate) then
			return candidate :: Frame
		end
	end

	for _, descendant in lobbyFrame:GetDescendants() do
		if descendant.Name == "YourParty" and is_your_party_container(descendant) then
			return descendant :: Frame
		end
	end

	return nil
end

local function find_player_list_toggle(): GuiButton?
	if lobbyHolder then
		local holderPlayerList = lobbyHolder:FindFirstChild("PlayerList")

		if holderPlayerList and holderPlayerList:IsA("GuiButton") and not has_template(holderPlayerList) then
			return holderPlayerList
		end
	end

	local fallback = lobbyFrame:FindFirstChild("PlayerListButton", true)

	if fallback and fallback:IsA("GuiButton") then
		return fallback
	end

	return nil
end

local function style_invite_button(
	button: GuiButton,
	localRole: string,
	localPartyId: string?,
	targetUserId: number,
	lookup: { [number]: PartyClientService.PlayerPartyState }
): ()
	local targetState = lookup[targetUserId]
	local canClick = true
	local color = INVITE_GREEN

	if targetUserId == player.UserId then
		canClick = false
		color = INVITE_DISABLED
	elseif localRole == PARTY_ROLE_MEMBER then
		canClick = false
		color = INVITE_RED
	elseif targetState and targetState.partyId and targetState.partyId ~= localPartyId then
		color = INVITE_YELLOW
	end

	if button:IsA("TextButton") or button:IsA("ImageButton") then
		button.Active = canClick
		button.AutoButtonColor = canClick
	end

	if button:IsA("TextButton") then
		button.BackgroundColor3 = color
	end
end

local function set_player_list_visible(visible: boolean): ()
	if visible then
		PagesClientService.open_page(PLAYER_LIST_PAGE_NAME)
		return
	end

	PagesClientService.close_page(PLAYER_LIST_PAGE_NAME)
end

local function render_player_list(snapshot: PartyClientService.SnapshotState): ()
	if not playerListContainer or not playerTemplate then
		return
	end

	clear_children(playerListContainer, {
		[playerTemplate.Name] = true,
	})

	playerTemplate.Visible = false

	local localRole = get_local_party_role(snapshot)
	local localPartyId = snapshot.party.partyId
	local lookup = get_player_party_lookup(snapshot)

	for _, playerState in snapshot.players do
		local row = playerTemplate:Clone()
		row.Visible = true
		row.Name = "Player_" .. tostring(playerState.userId)
		row.Parent = playerListContainer

		local nameLabel = row:FindFirstChild("PlayerName")
		local picLabel = row:FindFirstChild("PlayerPic")
		local inviteButton = row:FindFirstChild("Invite")

		if not nameLabel or not nameLabel:IsA("TextLabel") or not picLabel or not picLabel:IsA("ImageLabel") or not inviteButton or not inviteButton:IsA("GuiButton") then
			row:Destroy()
			continue
		end

		nameLabel.Text = playerState.name
		apply_thumbnail(picLabel, playerState.userId)
		style_invite_button(inviteButton, localRole, localPartyId, playerState.userId, lookup)

		inviteButton.MouseButton1Click:Connect(function()
			if not inviteButton.Active then
				return
			end

			PartyClientService.request_invite(playerState.userId)
		end)
	end
end

local function render_invite_list(snapshot: PartyClientService.SnapshotState): ()
	if not inviteList or not inviteTemplate then
		return
	end

	clear_children(inviteList, {
		[inviteTemplate.Name] = true,
	})

	inviteTemplate.Visible = false
	local now = os.time()

	for _, inviteState in snapshot.invites do
		if inviteState.expiresAt <= now then
			continue
		end

		local row = inviteTemplate:Clone()
		row.Visible = true
		row.Name = "Invite_" .. inviteState.inviteId
		row.Parent = inviteList

		local nameLabel = row:FindFirstChild("PlayerName")
		local picLabel = row:FindFirstChild("PlayerPic")
		local acceptButton = row:FindFirstChild("Accept")
		local denyButton = row:FindFirstChild("Denny")

		if not nameLabel or not nameLabel:IsA("TextLabel") or not picLabel or not picLabel:IsA("ImageLabel") or not acceptButton or not acceptButton:IsA("GuiButton") or not denyButton or not denyButton:IsA("GuiButton") then
			row:Destroy()
			continue
		end

		nameLabel.Text = inviteState.fromName
		apply_thumbnail(picLabel, inviteState.fromUserId)

		acceptButton.MouseButton1Click:Connect(function()
			PartyClientService.request_accept(inviteState.inviteId)
		end)

		denyButton.MouseButton1Click:Connect(function()
			PartyClientService.request_deny(inviteState.inviteId)
		end)
	end
end

local function render_your_party(snapshot: PartyClientService.SnapshotState): ()
	if not yourPartyFrame or not partyMemberTemplate then
		return
	end

	local hasParty = snapshot.party.partyId ~= nil and #snapshot.party.members > 0
	yourPartyFrame.Visible = hasParty

	if not hasParty then
		clear_children(yourPartyFrame, {
			[partyMemberTemplate.Name] = true,
			[leaveButton and leaveButton.Name or "Leave"] = true,
		})
		partyMemberTemplate.Visible = false
		return
	end

	clear_children(yourPartyFrame, {
		[partyMemberTemplate.Name] = true,
		[leaveButton and leaveButton.Name or "Leave"] = true,
	})

	partyMemberTemplate.Visible = false

	local localRole = get_local_party_role(snapshot)
	local isOwner = localRole == PARTY_ROLE_OWNER
	local members = table.clone(snapshot.party.members)

	table.sort(members, function(a: PartyClientService.PartyMember, b: PartyClientService.PartyMember): boolean
		return string.lower(a.name) < string.lower(b.name)
	end)

	for _, member in members do
		local memberButton = partyMemberTemplate:Clone()
		memberButton.Visible = true
		memberButton.Name = "Member_" .. tostring(member.userId)
		memberButton.Parent = yourPartyFrame
		apply_thumbnail(memberButton, member.userId)

		local removeLabel = memberButton:FindFirstChild("Remove")

		if removeLabel and removeLabel:IsA("TextLabel") then
			removeLabel.Visible = false
		end

		memberButton.MouseEnter:Connect(function()
			if not isOwner or member.userId == player.UserId then
				return
			end

			if removeLabel and removeLabel:IsA("TextLabel") then
				removeLabel.Visible = true
			end
		end)

		memberButton.MouseLeave:Connect(function()
			if removeLabel and removeLabel:IsA("TextLabel") then
				removeLabel.Visible = false
			end
		end)

		memberButton.MouseButton1Click:Connect(function()
			if not isOwner or member.userId == player.UserId then
				return
			end

			PartyClientService.request_kick(member.userId)
		end)
	end
end

local function refresh_all(snapshot: PartyClientService.SnapshotState): ()
	render_player_list(snapshot)
	render_invite_list(snapshot)
	render_your_party(snapshot)
end

local function configure_ui(): ()
	local holderInstance = lobbyFrame:FindFirstChild("Holder")
	local inviteInstance = lobbyFrame:FindFirstChild("Invite")

	if holderInstance and holderInstance:IsA("GuiObject") then
		lobbyHolder = holderInstance
	end

	if inviteInstance and inviteInstance:IsA("GuiObject") then
		inviteFrame = inviteInstance
	end

	playerListPage = find_player_list_page()
	inviteList = find_invite_list_container()
	yourPartyFrame = find_your_party_container()
	playerListToggle = find_player_list_toggle()

	if playerListPage then
		playerListContainer = resolve_player_list_container(playerListPage)
		local template = playerListContainer and playerListContainer:FindFirstChild("Template") or nil

		if playerListContainer and template and template:IsA("Frame") then
			playerTemplate = template
			playerTemplate.Visible = false
			PagesClientService.register_page(PLAYER_LIST_PAGE_NAME, playerListPage)
			playerListPage:GetPropertyChangedSignal("Visible"):Connect(function()
				if playerListPage then
					isPlayerListVisible = playerListPage.Visible
				end
			end)

			if playerListPage.Visible then
				PagesClientService.open_page(PLAYER_LIST_PAGE_NAME)
			else
				PagesClientService.close_page(PLAYER_LIST_PAGE_NAME)
			end

			isPlayerListVisible = PagesClientService.is_page_open(PLAYER_LIST_PAGE_NAME)
			send_system_message("PlayerList conectado: " .. playerListPage:GetFullName(), "Info")
		else
			send_system_message("PlayerList encontrado sem Template valido.", "Error")
		end
	else
		send_system_message("PlayerList nao encontrado.", "Error")
	end

	if inviteList then
		local template = inviteList:FindFirstChild("Template")

		if template and template:IsA("Frame") then
			inviteTemplate = template
			inviteTemplate.Visible = false
			send_system_message("InviteList conectado: " .. inviteList:GetFullName(), "Info")
		end
	else
		send_system_message("InviteList nao encontrado.", "Error")
	end

	if yourPartyFrame then
		local leave = yourPartyFrame:FindFirstChild("Leave")
		local templatePlayer = yourPartyFrame:FindFirstChild("TemplatePlayer")

		if leave and leave:IsA("GuiButton") then
			leaveButton = leave
		end

		if templatePlayer and templatePlayer:IsA("ImageButton") then
			partyMemberTemplate = templatePlayer
			partyMemberTemplate.Visible = false
		end

		send_system_message("YourParty conectado: " .. yourPartyFrame:GetFullName(), "Info")
	else
		send_system_message("YourParty nao encontrado.", "Error")
	end

	if leaveButton then
		leaveButton.MouseButton1Click:Connect(function()
			PartyClientService.request_leave_party()
		end)
	end

	if playerListToggle then
		playerListToggle.MouseButton1Click:Connect(function()
			PagesClientService.toggle_page(PLAYER_LIST_PAGE_NAME)
			isPlayerListVisible = PagesClientService.is_page_open(PLAYER_LIST_PAGE_NAME)
		end)

		send_system_message("Botao toggle PlayerList conectado: " .. playerListToggle:GetFullName(), "Info")
	else
		send_system_message("Botao toggle PlayerList nao encontrado em Lobby.Holder.PlayerList.", "Warn")
	end
end

------------------//INIT
configure_ui()

removeSnapshotListener = PartyClientService.on_snapshot_changed(function(snapshot: PartyClientService.SnapshotState)
	refresh_all(snapshot)
end)

removeDebugListener = PartyClientService.on_debug(function(payload: PartyClientService.DebugPayload)
	send_system_message(payload.message, payload.colorName)
end)

PartyClientService.start()
refresh_all(PartyClientService.get_snapshot())
PartyClientService.request_sync()
send_system_message("Inicializado.", "Info")

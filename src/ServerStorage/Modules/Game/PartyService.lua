------------------//SERVICES
local Players: Players = game:GetService("Players")
local HttpService: HttpService = game:GetService("HttpService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local PartyService = {}

local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))

local PARTY_MAX_MEMBERS = MatchmakingDictionary.PARTY_MAX_MEMBERS
local INVITE_DURATION = MatchmakingDictionary.PARTY_INVITE_DURATION
local ACTION_COOLDOWN = 0.2

------------------//VARIABLES
type Party = {
	partyId: string,
	ownerUserId: number,
	members: { number },
}

type Invite = {
	inviteId: string,
	partyId: string,
	fromOwnerUserId: number,
	toUserId: number,
	expiresAt: number,
}

type QueueGroupContext = {
	groupId: string,
	partyId: string?,
	leaderUserId: number,
	userIds: { number },
	behavior: string,
}

local remoteEvent: RemoteEvent? = nil
local started = false

local partiesById: { [string]: Party } = {}
local playerPartyId: { [number]: string } = {}
local invitesByTarget: { [number]: { [string]: Invite } } = {}
local ownerTargetInviteKey: { [string]: string } = {}
local lastActionAt: { [number]: number } = {}

------------------//FUNCTIONS
local function debug_log(message: string): ()
	print("[Party] " .. message)
end

local function get_player(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function get_owner_target_key(ownerUserId: number, targetUserId: number): string
	return tostring(ownerUserId) .. ":" .. tostring(targetUserId)
end

local function remove_owner_target_mapping(ownerUserId: number, targetUserId: number): ()
	ownerTargetInviteKey[get_owner_target_key(ownerUserId, targetUserId)] = nil
end

local function send_debug(player: Player, message: string, colorName: string?): ()
	if not remoteEvent then
		return
	end

	remoteEvent:FireClient(player, "Debug", {
		message = message,
		colorName = colorName or "Info",
	})
end

local function get_party_by_player_user_id(userId: number): Party?
	local partyId = playerPartyId[userId]

	if not partyId then
		return nil
	end

	return partiesById[partyId]
end

local function set_player_party_attributes(player: Player): ()
	local party = get_party_by_player_user_id(player.UserId)

	if not party then
		player:SetAttribute("PartyId", nil)
		player:SetAttribute("PartyOwnerUserId", nil)
		player:SetAttribute("PartySize", 0)
		player:SetAttribute("PartyRole", "None")
		return
	end

	player:SetAttribute("PartyId", party.partyId)
	player:SetAttribute("PartyOwnerUserId", party.ownerUserId)
	player:SetAttribute("PartySize", #party.members)

	if party.ownerUserId == player.UserId then
		player:SetAttribute("PartyRole", "Owner")
		return
	end

	player:SetAttribute("PartyRole", "Member")
end

local function refresh_party_member_attributes(party: Party): ()
	for _, memberUserId in party.members do
		local memberPlayer = get_player(memberUserId)

		if memberPlayer then
			set_player_party_attributes(memberPlayer)
		end
	end
end

local function broadcast_snapshot(): ()
	if not remoteEvent then
		return
	end

	for _, player in Players:GetPlayers() do
		PartyService.send_snapshot(player)
	end
end

local function remove_invite(invite: Invite): ()
	local targetInvites = invitesByTarget[invite.toUserId]

	if targetInvites then
		targetInvites[invite.inviteId] = nil

		local hasAny = false

		for _ in targetInvites do
			hasAny = true
			break
		end

		if not hasAny then
			invitesByTarget[invite.toUserId] = nil
		end
	end

	remove_owner_target_mapping(invite.fromOwnerUserId, invite.toUserId)
end

local function clear_invites_for_target(targetUserId: number): ()
	local targetInvites = invitesByTarget[targetUserId]

	if not targetInvites then
		return
	end

	local toRemove: { Invite } = {}

	for _, invite in targetInvites do
		table.insert(toRemove, invite)
	end

	for _, invite in toRemove do
		remove_invite(invite)
	end
end

local function clear_outgoing_invites_for_owner(ownerUserId: number): ()
	local allInvites: { Invite } = {}

	for _, targetInvites in invitesByTarget do
		for _, invite in targetInvites do
			if invite.fromOwnerUserId == ownerUserId then
				table.insert(allInvites, invite)
			end
		end
	end

	for _, invite in allInvites do
		remove_invite(invite)
	end
end

local function destroy_party(party: Party): ()
	for _, memberUserId in party.members do
		playerPartyId[memberUserId] = nil
		local memberPlayer = get_player(memberUserId)

		if memberPlayer then
			set_player_party_attributes(memberPlayer)
		end
	end

	clear_outgoing_invites_for_owner(party.ownerUserId)
	partiesById[party.partyId] = nil
end

local function remove_member_from_party(party: Party, memberUserId: number): ()
	local removeIndex = table.find(party.members, memberUserId)

	if not removeIndex then
		return
	end

	table.remove(party.members, removeIndex)
	playerPartyId[memberUserId] = nil

	local memberPlayer = get_player(memberUserId)

	if memberPlayer then
		set_player_party_attributes(memberPlayer)
	end

	if #party.members == 0 then
		partiesById[party.partyId] = nil
		return
	end

	if party.ownerUserId == memberUserId then
		destroy_party(party)
		return
	end

	refresh_party_member_attributes(party)
end

local function ensure_owner_party(ownerPlayer: Player): Party
	local current = get_party_by_player_user_id(ownerPlayer.UserId)

	if current then
		return current
	end

	local partyId = HttpService:GenerateGUID(false)
	local party: Party = {
		partyId = partyId,
		ownerUserId = ownerPlayer.UserId,
		members = { ownerPlayer.UserId },
	}

	partiesById[partyId] = party
	playerPartyId[ownerPlayer.UserId] = partyId
	set_player_party_attributes(ownerPlayer)
	return party
end

local function cleanup_expired_invites(): ()
	local now = os.time()
	local expired: { Invite } = {}

	for _, targetInvites in invitesByTarget do
		for _, invite in targetInvites do
			if invite.expiresAt <= now then
				table.insert(expired, invite)
			end
		end
	end

	if #expired == 0 then
		return
	end

	for _, invite in expired do
		remove_invite(invite)

		local ownerPlayer = get_player(invite.fromOwnerUserId)

		if ownerPlayer then
			send_debug(ownerPlayer, "Convite para " .. tostring(invite.toUserId) .. " expirou.", "Warn")
		end
	end

	broadcast_snapshot()
end

local function can_process_action(player: Player): boolean
	local now = os.clock()
	local lastAction = lastActionAt[player.UserId] or 0

	if now - lastAction < ACTION_COOLDOWN then
		return false
	end

	lastActionAt[player.UserId] = now
	return true
end

local function get_player_name(userId: number): string
	local player = get_player(userId)

	if player then
		return player.Name
	end

	return tostring(userId)
end

local function is_player_matchmaking_locked(player: Player): boolean
	return player:GetAttribute("IsMatchmakingQueued") == true
end

local function sort_members_by_name(members: { number }): ()
	table.sort(members, function(a: number, b: number): boolean
		return string.lower(get_player_name(a)) < string.lower(get_player_name(b))
	end)
end

local function build_party_payload(party: Party?): { [string]: any }
	local payload = {
		partyId = nil :: string?,
		ownerUserId = nil :: number?,
		members = {} :: { [number]: { [string]: any } },
	}

	if not party then
		return payload
	end

	payload.partyId = party.partyId
	payload.ownerUserId = party.ownerUserId

	local members = table.clone(party.members)
	sort_members_by_name(members)

	for _, memberUserId in members do
		table.insert(payload.members, {
			userId = memberUserId,
			name = get_player_name(memberUserId),
		})
	end

	return payload
end

local function build_invites_payload(targetUserId: number): { [number]: { [string]: any } }
	local payload: { [number]: { [string]: any } } = {}
	local targetInvites = invitesByTarget[targetUserId]

	if not targetInvites then
		return payload
	end

	local invites: { Invite } = {}

	for _, invite in targetInvites do
		if invite.expiresAt > os.time() then
			table.insert(invites, invite)
		end
	end

	table.sort(invites, function(a: Invite, b: Invite): boolean
		return a.expiresAt < b.expiresAt
	end)

	for _, invite in invites do
		table.insert(payload, {
			inviteId = invite.inviteId,
			fromUserId = invite.fromOwnerUserId,
			fromName = get_player_name(invite.fromOwnerUserId),
			expiresAt = invite.expiresAt,
		})
	end

	return payload
end

local function build_players_payload(): { [number]: { [string]: any } }
	local payload: { [number]: { [string]: any } } = {}
	local players = Players:GetPlayers()

	table.sort(players, function(a: Player, b: Player): boolean
		return string.lower(a.Name) < string.lower(b.Name)
	end)

	for _, player in players do
		local party = get_party_by_player_user_id(player.UserId)
		local partyId = if party then party.partyId else nil
		local partyOwnerUserId = if party then party.ownerUserId else nil
		local partySize = if party then #party.members else 0

		table.insert(payload, {
			userId = player.UserId,
			name = player.Name,
			partyId = partyId,
			partyOwnerUserId = partyOwnerUserId,
			partySize = partySize,
		})
	end

	return payload
end

local function on_invite(player: Player, targetUserId: number): ()
	if is_player_matchmaking_locked(player) then
		send_debug(player, "Saia da fila antes de mexer na party.", "Warn")
		return
	end

	if typeof(targetUserId) ~= "number" then
		send_debug(player, "Jogador invalido para convite.", "Error")
		return
	end

	if targetUserId == player.UserId then
		send_debug(player, "Voce nao pode convidar voce mesmo.", "Warn")
		return
	end

	local targetPlayer = get_player(targetUserId)

	if not targetPlayer then
		send_debug(player, "Jogador nao encontrado.", "Warn")
		return
	end

	if is_player_matchmaking_locked(targetPlayer) then
		send_debug(player, targetPlayer.Name .. " esta em fila de matchmaking.", "Warn")
		return
	end

	local currentParty = get_party_by_player_user_id(player.UserId)

	if currentParty and currentParty.ownerUserId ~= player.UserId then
		send_debug(player, "Somente o dono da party pode enviar convites.", "Warn")
		return
	end

	local ownerParty = ensure_owner_party(player)

	if #ownerParty.members >= PARTY_MAX_MEMBERS then
		send_debug(player, "Party cheia (" .. tostring(PARTY_MAX_MEMBERS) .. ").", "Warn")
		return
	end

	if table.find(ownerParty.members, targetUserId) then
		send_debug(player, targetPlayer.Name .. " ja esta na sua party.", "Info")
		return
	end

	local existingInviteId = ownerTargetInviteKey[get_owner_target_key(player.UserId, targetUserId)]

	if existingInviteId then
		local targetInvites = invitesByTarget[targetUserId]
		local existingInvite = targetInvites and targetInvites[existingInviteId]

		if existingInvite and existingInvite.expiresAt > os.time() then
			send_debug(player, "Ja existe convite pendente para " .. targetPlayer.Name .. ".", "Warn")
			return
		end
	end

	local inviteId = HttpService:GenerateGUID(false)
	local invite: Invite = {
		inviteId = inviteId,
		partyId = ownerParty.partyId,
		fromOwnerUserId = player.UserId,
		toUserId = targetUserId,
		expiresAt = os.time() + INVITE_DURATION,
	}

	local targetInvites = invitesByTarget[targetUserId]

	if not targetInvites then
		targetInvites = {}
		invitesByTarget[targetUserId] = targetInvites
	end

	targetInvites[inviteId] = invite
	ownerTargetInviteKey[get_owner_target_key(player.UserId, targetUserId)] = inviteId

	send_debug(player, "Convite enviado para " .. targetPlayer.Name .. ".", "Success")
	send_debug(targetPlayer, player.Name .. " enviou convite de party.", "Info")
	broadcast_snapshot()
end

local function accept_invite(player: Player, inviteId: string): ()
	if is_player_matchmaking_locked(player) then
		send_debug(player, "Saia da fila antes de aceitar convite.", "Warn")
		return
	end

	local targetInvites = invitesByTarget[player.UserId]

	if not targetInvites then
		send_debug(player, "Convite nao encontrado.", "Warn")
		return
	end

	local invite = targetInvites[inviteId]

	if not invite then
		send_debug(player, "Convite nao encontrado.", "Warn")
		return
	end

	if invite.expiresAt <= os.time() then
		remove_invite(invite)
		send_debug(player, "Convite expirado.", "Warn")
		broadcast_snapshot()
		return
	end

	local sourceParty = partiesById[invite.partyId]

	if not sourceParty or sourceParty.ownerUserId ~= invite.fromOwnerUserId then
		remove_invite(invite)
		send_debug(player, "Party de origem nao esta mais disponivel.", "Warn")
		broadcast_snapshot()
		return
	end

	if #sourceParty.members >= PARTY_MAX_MEMBERS then
		remove_invite(invite)
		send_debug(player, "Party de origem esta cheia.", "Warn")
		broadcast_snapshot()
		return
	end

	if table.find(sourceParty.members, player.UserId) then
		clear_invites_for_target(player.UserId)
		send_debug(player, "Voce ja esta nessa party.", "Info")
		broadcast_snapshot()
		return
	end

	local currentParty = get_party_by_player_user_id(player.UserId)

	if currentParty then
		if currentParty.ownerUserId == player.UserId then
			destroy_party(currentParty)
		else
			remove_member_from_party(currentParty, player.UserId)
		end
	end

	playerPartyId[player.UserId] = sourceParty.partyId
	table.insert(sourceParty.members, player.UserId)
	refresh_party_member_attributes(sourceParty)
	set_player_party_attributes(player)

	clear_invites_for_target(player.UserId)
	send_debug(player, "Voce entrou na party de " .. get_player_name(sourceParty.ownerUserId) .. ".", "Success")
	broadcast_snapshot()
end

local function deny_invite(player: Player, inviteId: string): ()
	local targetInvites = invitesByTarget[player.UserId]

	if not targetInvites then
		return
	end

	local invite = targetInvites[inviteId]

	if not invite then
		return
	end

	remove_invite(invite)
	send_debug(player, "Convite recusado.", "Warn")

	local ownerPlayer = get_player(invite.fromOwnerUserId)

	if ownerPlayer then
		send_debug(ownerPlayer, player.Name .. " recusou o convite.", "Warn")
	end

	broadcast_snapshot()
end

local function leave_party(player: Player): ()
	if is_player_matchmaking_locked(player) then
		send_debug(player, "Saia da fila antes de sair da party.", "Warn")
		return
	end

	local party = get_party_by_player_user_id(player.UserId)

	if not party then
		send_debug(player, "Voce nao esta em uma party.", "Warn")
		return
	end

	if party.ownerUserId == player.UserId then
		destroy_party(party)
		send_debug(player, "Party desfeita.", "Warn")
		broadcast_snapshot()
		return
	end

	remove_member_from_party(party, player.UserId)
	send_debug(player, "Voce saiu da party.", "Warn")
	broadcast_snapshot()
end

local function kick_member(player: Player, targetUserId: number): ()
	if is_player_matchmaking_locked(player) then
		send_debug(player, "Saia da fila antes de remover membros.", "Warn")
		return
	end

	local party = get_party_by_player_user_id(player.UserId)

	if not party then
		send_debug(player, "Voce nao esta em uma party.", "Warn")
		return
	end

	if party.ownerUserId ~= player.UserId then
		send_debug(player, "Somente o dono pode remover membros.", "Warn")
		return
	end

	if targetUserId == player.UserId then
		send_debug(player, "Use Leave para sair da party.", "Warn")
		return
	end

	if not table.find(party.members, targetUserId) then
		send_debug(player, "Jogador nao esta na sua party.", "Warn")
		return
	end

	local targetPlayer = get_player(targetUserId)

	if targetPlayer and is_player_matchmaking_locked(targetPlayer) then
		send_debug(player, targetPlayer.Name .. " esta em fila de matchmaking.", "Warn")
		return
	end

	remove_member_from_party(party, targetUserId)
	send_debug(player, "Jogador removido da party.", "Warn")

	if targetPlayer then
		send_debug(targetPlayer, "Voce foi removido da party.", "Warn")
	end

	broadcast_snapshot()
end

local function on_player_removing(player: Player): ()
	lastActionAt[player.UserId] = nil
	clear_invites_for_target(player.UserId)

	local party = get_party_by_player_user_id(player.UserId)

	if party then
		if party.ownerUserId == player.UserId then
			destroy_party(party)
		else
			remove_member_from_party(party, player.UserId)
		end
	end

	broadcast_snapshot()
end

local function on_remote_event(player: Player, action: string, payload: any): ()
	if not can_process_action(player) then
		return
	end

	if action == "Sync" then
		PartyService.send_snapshot(player)
		return
	end

	if action == "Invite" then
		on_invite(player, payload)
		return
	end

	if action == "Accept" and typeof(payload) == "string" then
		accept_invite(player, payload)
		return
	end

	if action == "Deny" and typeof(payload) == "string" then
		deny_invite(player, payload)
		return
	end

	if action == "LeaveParty" then
		leave_party(player)
		return
	end

	if action == "Kick" and typeof(payload) == "number" then
		kick_member(player, payload)
	end
end

------------------//MAIN FUNCTIONS
function PartyService.start(remote: RemoteEvent): ()
	if started then
		return
	end

	started = true
	remoteEvent = remote

	for _, player in Players:GetPlayers() do
		set_player_party_attributes(player)
	end

	remote.OnServerEvent:Connect(on_remote_event)
	Players.PlayerRemoving:Connect(on_player_removing)
	Players.PlayerAdded:Connect(function(player: Player)
		set_player_party_attributes(player)
		broadcast_snapshot()
	end)

	task.spawn(function()
		while started do
			task.wait(1)
			cleanup_expired_invites()
		end
	end)
end

function PartyService.send_snapshot(player: Player): ()
	if not remoteEvent then
		return
	end

	local party = get_party_by_player_user_id(player.UserId)
	local snapshot = {
		party = build_party_payload(party),
		invites = build_invites_payload(player.UserId),
		players = build_players_payload(),
	}

	remoteEvent:FireClient(player, "Snapshot", snapshot)
end

function PartyService.get_player_party_owner_user_id(userId: number): number?
	local party = get_party_by_player_user_id(userId)

	if not party then
		return nil
	end

	return party.ownerUserId
end

function PartyService.get_queue_group_for_player(player: Player, modeConfig: any): (boolean, QueueGroupContext?, string?)
	local party = get_party_by_player_user_id(player.UserId)

	if not party then
		return true, {
			groupId = "solo_" .. tostring(player.UserId),
			partyId = nil,
			leaderUserId = player.UserId,
			userIds = { player.UserId },
			behavior = "Solo",
		}, nil
	end

	if party.ownerUserId ~= player.UserId then
		return false, nil, "Somente o dono da party pode entrar na fila."
	end

	local userIds = table.clone(party.members)
	local partySize = #userIds

	if partySize > modeConfig.playersRequired then
		return false, nil, "Party maior que o modo " .. modeConfig.mode .. "."
	end

	if modeConfig.mode == "1v1" then
		if partySize == 1 then
			return true, {
				groupId = party.partyId,
				partyId = party.partyId,
				leaderUserId = player.UserId,
				userIds = userIds,
				behavior = "Solo",
			}, nil
		end

		if partySize == 2 then
			return true, {
				groupId = party.partyId,
				partyId = party.partyId,
				leaderUserId = player.UserId,
				userIds = userIds,
				behavior = "SplitDuel",
			}, nil
		end

		return false, nil, "No modo 1v1, party precisa ter 1 ou 2 jogadores."
	end

	if partySize > modeConfig.teamSize then
		return false, nil, "Party maior que o tamanho de time do modo " .. modeConfig.mode .. "."
	end

	return true, {
		groupId = party.partyId,
		partyId = party.partyId,
		leaderUserId = player.UserId,
		userIds = userIds,
		behavior = "SameTeam",
	}, nil
end

function PartyService.get_party_member_user_ids(userId: number): { number }
	local party = get_party_by_player_user_id(userId)

	if not party then
		return {}
	end

	return table.clone(party.members)
end

function PartyService.remove_player_from_party_for_queue(userId: number): ()
	local player = get_player(userId)

	if not player then
		return
	end

	local party = get_party_by_player_user_id(userId)

	if not party then
		return
	end

	if party.ownerUserId == userId then
		destroy_party(party)
		broadcast_snapshot()
		return
	end

	remove_member_from_party(party, userId)
	broadcast_snapshot()
end

return PartyService

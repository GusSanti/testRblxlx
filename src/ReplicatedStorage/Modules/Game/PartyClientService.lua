------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))

------------------//VARIABLES
local PartyClientService = {}

export type PartyMember = {
	userId: number,
	name: string,
}

export type PartyState = {
	partyId: string?,
	ownerUserId: number?,
	members: { PartyMember },
}

export type InviteState = {
	inviteId: string,
	fromUserId: number,
	fromName: string,
	expiresAt: number,
}

export type PlayerPartyState = {
	userId: number,
	name: string,
	partyId: string?,
	partyOwnerUserId: number?,
	partySize: number,
}

export type SnapshotState = {
	party: PartyState,
	invites: { InviteState },
	players: { PlayerPartyState },
}

export type DebugPayload = {
	message: string,
	colorName: string?,
}

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local remoteEvent: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.PARTY_REMOTE_EVENT_NAME) :: RemoteEvent

local started = false
local remoteConnection: RBXScriptConnection? = nil

local currentSnapshot: SnapshotState = {
	party = {
		partyId = nil,
		ownerUserId = nil,
		members = {},
	},
	invites = {},
	players = {},
}

local snapshotListeners: { (SnapshotState) -> () } = {}
local debugListeners: { (DebugPayload) -> () } = {}

------------------//FUNCTIONS
local function clone_members(members: { PartyMember }): { PartyMember }
	local cloned: { PartyMember } = {}

	for _, member in members do
		table.insert(cloned, {
			userId = member.userId,
			name = member.name,
		})
	end

	return cloned
end

local function clone_invites(invites: { InviteState }): { InviteState }
	local cloned: { InviteState } = {}

	for _, invite in invites do
		table.insert(cloned, {
			inviteId = invite.inviteId,
			fromUserId = invite.fromUserId,
			fromName = invite.fromName,
			expiresAt = invite.expiresAt,
		})
	end

	return cloned
end

local function clone_players(players: { PlayerPartyState }): { PlayerPartyState }
	local cloned: { PlayerPartyState } = {}

	for _, playerState in players do
		table.insert(cloned, {
			userId = playerState.userId,
			name = playerState.name,
			partyId = playerState.partyId,
			partyOwnerUserId = playerState.partyOwnerUserId,
			partySize = playerState.partySize,
		})
	end

	return cloned
end

local function clone_snapshot(snapshot: SnapshotState): SnapshotState
	return {
		party = {
			partyId = snapshot.party.partyId,
			ownerUserId = snapshot.party.ownerUserId,
			members = clone_members(snapshot.party.members),
		},
		invites = clone_invites(snapshot.invites),
		players = clone_players(snapshot.players),
	}
end

local function normalize_member(value: any): PartyMember?
	if typeof(value) ~= "table" then
		return nil
	end

	if typeof(value.userId) ~= "number" then
		return nil
	end

	if typeof(value.name) ~= "string" then
		return nil
	end

	return {
		userId = value.userId,
		name = value.name,
	}
end

local function normalize_invite(value: any): InviteState?
	if typeof(value) ~= "table" then
		return nil
	end

	if typeof(value.inviteId) ~= "string" then
		return nil
	end

	if typeof(value.fromUserId) ~= "number" then
		return nil
	end

	if typeof(value.fromName) ~= "string" then
		return nil
	end

	if typeof(value.expiresAt) ~= "number" then
		return nil
	end

	return {
		inviteId = value.inviteId,
		fromUserId = value.fromUserId,
		fromName = value.fromName,
		expiresAt = value.expiresAt,
	}
end

local function normalize_player(value: any): PlayerPartyState?
	if typeof(value) ~= "table" then
		return nil
	end

	if typeof(value.userId) ~= "number" then
		return nil
	end

	if typeof(value.name) ~= "string" then
		return nil
	end

	local partyId = if typeof(value.partyId) == "string" then value.partyId else nil
	local partyOwnerUserId = if typeof(value.partyOwnerUserId) == "number" then value.partyOwnerUserId else nil
	local partySize = if typeof(value.partySize) == "number" then math.max(0, math.floor(value.partySize)) else 0

	return {
		userId = value.userId,
		name = value.name,
		partyId = partyId,
		partyOwnerUserId = partyOwnerUserId,
		partySize = partySize,
	}
end

local function normalize_snapshot(payload: any): SnapshotState
	local normalized: SnapshotState = {
		party = {
			partyId = nil,
			ownerUserId = nil,
			members = {},
		},
		invites = {},
		players = {},
	}

	if typeof(payload) ~= "table" then
		return normalized
	end

	if typeof(payload.party) == "table" then
		local party = payload.party
		normalized.party.partyId = if typeof(party.partyId) == "string" then party.partyId else nil
		normalized.party.ownerUserId = if typeof(party.ownerUserId) == "number" then party.ownerUserId else nil

		if typeof(party.members) == "table" then
			for _, value in party.members do
				local member = normalize_member(value)

				if member then
					table.insert(normalized.party.members, member)
				end
			end
		end
	end

	if typeof(payload.invites) == "table" then
		for _, value in payload.invites do
			local invite = normalize_invite(value)

			if invite then
				table.insert(normalized.invites, invite)
			end
		end
	end

	if typeof(payload.players) == "table" then
		for _, value in payload.players do
			local playerState = normalize_player(value)

			if playerState then
				table.insert(normalized.players, playerState)
			end
		end
	end

	return normalized
end

local function emit_snapshot(snapshot: SnapshotState): ()
	local cloned = clone_snapshot(snapshot)

	for _, callback in snapshotListeners do
		callback(cloned)
	end
end

local function emit_debug(payload: DebugPayload): ()
	for _, callback in debugListeners do
		callback(payload)
	end
end

local function on_remote_event(action: string, payload: any): ()
	if action == "Snapshot" then
		currentSnapshot = normalize_snapshot(payload)
		emit_snapshot(currentSnapshot)
		return
	end

	if action == "Debug" then
		local message = if typeof(payload) == "table" and payload.message ~= nil then tostring(payload.message) else ""
		local colorName = if typeof(payload) == "table" and typeof(payload.colorName) == "string" then payload.colorName else nil

		emit_debug({
			message = message,
			colorName = colorName,
		})
	end
end

local function remove_snapshot_listener(callback: (SnapshotState) -> ()): ()
	for index, listener in snapshotListeners do
		if listener == callback then
			table.remove(snapshotListeners, index)
			return
		end
	end
end

local function remove_debug_listener(callback: (DebugPayload) -> ()): ()
	for index, listener in debugListeners do
		if listener == callback then
			table.remove(debugListeners, index)
			return
		end
	end
end

------------------//MAIN FUNCTIONS
function PartyClientService.start(): ()
	if started then
		return
	end

	started = true
	remoteConnection = remoteEvent.OnClientEvent:Connect(on_remote_event)
	remoteEvent:FireServer("Sync")
end

function PartyClientService.stop(): ()
	if remoteConnection then
		remoteConnection:Disconnect()
		remoteConnection = nil
	end

	started = false
end

function PartyClientService.get_snapshot(): SnapshotState
	return clone_snapshot(currentSnapshot)
end

function PartyClientService.request_sync(): ()
	remoteEvent:FireServer("Sync")
end

function PartyClientService.request_invite(targetUserId: number): ()
	remoteEvent:FireServer("Invite", targetUserId)
end

function PartyClientService.request_accept(inviteId: string): ()
	remoteEvent:FireServer("Accept", inviteId)
end

function PartyClientService.request_deny(inviteId: string): ()
	remoteEvent:FireServer("Deny", inviteId)
end

function PartyClientService.request_leave_party(): ()
	remoteEvent:FireServer("LeaveParty")
end

function PartyClientService.request_kick(targetUserId: number): ()
	remoteEvent:FireServer("Kick", targetUserId)
end

function PartyClientService.on_snapshot_changed(callback: (SnapshotState) -> ()): (() -> ())
	table.insert(snapshotListeners, callback)

	return function()
		remove_snapshot_listener(callback)
	end
end

function PartyClientService.on_debug(callback: (DebugPayload) -> ()): (() -> ())
	table.insert(debugListeners, callback)

	return function()
		remove_debug_listener(callback)
	end
end

return PartyClientService

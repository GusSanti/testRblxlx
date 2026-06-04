------------------//SERVICES
local TeleportService: TeleportService = game:GetService("TeleportService")
local HttpService: HttpService = game:GetService("HttpService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))

------------------//VARIABLES
type ModeConfig = MatchmakingDictionary.ModeConfig

type ReservedMatchPackage = {
	matchId: string,
	mode: string,
	teamSize: number,
	playersRequired: number,
	placeId: number,
	reservedServerAccessCode: string,
	privateServerId: string,
	users: { number },
	teamByUserId: { [string]: string },
	groupBehaviorById: { [string]: string },
	createdAt: number,
}

------------------//FUNCTIONS
local function clone_users(users: { number }): { number }
	local cloned: { number } = {}

	for _, userId in users do
		table.insert(cloned, userId)
	end

	return cloned
end

local function build_team_by_user_string_map(teamByUserId: { [number]: string }): { [string]: string }
	local payload: { [string]: string } = {}

	for userId, teamName in teamByUserId do
		payload[tostring(userId)] = teamName
	end

	return payload
end

local function clone_behavior_map(groupBehaviorById: { [string]: string }?): { [string]: string }
	local payload: { [string]: string } = {}

	if not groupBehaviorById then
		return payload
	end

	for groupId, behavior in groupBehaviorById do
		payload[groupId] = behavior
	end

	return payload
end

------------------//MAIN FUNCTIONS
local MatchCreationService = {}

function MatchCreationService.create_reserved_match(
	modeConfig: ModeConfig,
	users: { number },
	teamByUserId: { [number]: string },
	groupBehaviorById: { [string]: string }?
): (boolean, ReservedMatchPackage | string)
	local success, accessCode, privateServerId = pcall(function()
		return TeleportService:ReserveServerAsync(MatchmakingDictionary.DESTINATION_PLACE_ID)
	end)

	if not success then
		return false, tostring(accessCode)
	end

	local package: ReservedMatchPackage = {
		matchId = HttpService:GenerateGUID(false),
		mode = modeConfig.mode,
		teamSize = modeConfig.teamSize,
		playersRequired = modeConfig.playersRequired,
		placeId = MatchmakingDictionary.DESTINATION_PLACE_ID,
		reservedServerAccessCode = accessCode,
		privateServerId = privateServerId,
		users = clone_users(users),
		teamByUserId = build_team_by_user_string_map(teamByUserId),
		groupBehaviorById = clone_behavior_map(groupBehaviorById),
		createdAt = os.time(),
	}

	return true, package
end

function MatchCreationService.build_teleport_options(
	matchPackage: ReservedMatchPackage,
	extraTeleportData: { [string]: any }?
): TeleportOptions
	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ReservedServerAccessCode = matchPackage.reservedServerAccessCode

	local teleportData = {
		mode = matchPackage.mode,
		teamSize = matchPackage.teamSize,
		playersRequired = matchPackage.playersRequired,
		matchId = matchPackage.matchId,
		privateServerId = matchPackage.privateServerId,
		userIds = clone_users(matchPackage.users),
		teamByUserId = matchPackage.teamByUserId,
		groupBehaviorById = matchPackage.groupBehaviorById,
	}

	if extraTeleportData then
		for key, value in extraTeleportData do
			teleportData[key] = value
		end
	end

	teleportOptions:SetTeleportData(teleportData)
	return teleportOptions
end

function MatchCreationService.teleport_players(
	playersToTeleport: { Player },
	matchPackage: ReservedMatchPackage,
	extraTeleportData: { [string]: any }?
): (boolean, any)
	local teleportOptions = MatchCreationService.build_teleport_options(matchPackage, extraTeleportData)

	local success, result = pcall(function()
		return TeleportService:TeleportAsync(matchPackage.placeId, playersToTeleport, teleportOptions)
	end)

	if success then
		return true, result
	end

	return false, result
end

return MatchCreationService

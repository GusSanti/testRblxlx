------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local DailyRewardDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("DailyRewardDictionary"))
local ItemsDataDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("ItemsDataDictionary"))

local modulesFolder: Folder = ReplicatedStorage:WaitForChild("Modules") :: Folder
local utilityFolder: Folder = modulesFolder:WaitForChild("Utility") :: Folder
local DataUtility = require(utilityFolder:WaitForChild("DataUtility"))

local DAILY_DATA_PATH = "DailyRewards"
local TOTAL_DAYS = DailyRewardDictionary.TOTAL_DAYS
local CLAIM_REFRESH_INTERVAL = 60

------------------//VARIABLES
local remotesFolderInstance: Folder? = ReplicatedStorage:FindFirstChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder?

if not remotesFolderInstance then
	remotesFolderInstance = Instance.new("Folder")
	remotesFolderInstance.Name = MatchmakingDictionary.REMOTE_FOLDER_NAME
	remotesFolderInstance.Parent = ReplicatedStorage
end

local remotesFolder: Folder = remotesFolderInstance :: Folder
local dailyRemoteInstance: RemoteEvent? = remotesFolder:FindFirstChild(MatchmakingDictionary.DAILY_REWARD_REMOTE_EVENT_NAME) :: RemoteEvent?

if not dailyRemoteInstance then
	dailyRemoteInstance = Instance.new("RemoteEvent")
	dailyRemoteInstance.Name = MatchmakingDictionary.DAILY_REWARD_REMOTE_EVENT_NAME
	dailyRemoteInstance.Parent = remotesFolder
end

local dailyRemote: RemoteEvent = dailyRemoteInstance :: RemoteEvent
local refreshTokensByUserId: { [number]: {} } = {}
local claimLocks: { [number]: boolean } = {}

------------------//FUNCTIONS
local function get_current_day_stamp(): number
	return math.floor(os.time() / 86400)
end

local function get_number_value(player: Player, path: string, fallback: number): number
	local value = DataUtility.server.get(player, path)

	if typeof(value) ~= "number" then
		return fallback
	end

	return value
end

local function set_if_changed(player: Player, path: string, value: any): ()
	local currentValue = DataUtility.server.get(player, path)

	if currentValue == value then
		return
	end

	DataUtility.server.set(player, path, value)
end

local function has_weapon(ownedWeapons: { string }, weaponName: string): boolean
	for _, ownedWeaponName in ownedWeapons do
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

local function get_player_coins(player: Player): number
	local value = DataUtility.server.get(player, "Coins")

	if typeof(value) ~= "number" then
		return 0
	end

	return math.max(0, math.floor(value))
end

local function ensure_daily_profile_defaults(player: Player): (number, number, number)
	local currentDayStamp = get_current_day_stamp()
	local startDayStamp = math.floor(get_number_value(player, DAILY_DATA_PATH .. ".StartDayStamp", 0))
	local claimedDays = math.floor(get_number_value(player, DAILY_DATA_PATH .. ".ClaimedDays", 0))
	local lastClaimedAt = math.floor(get_number_value(player, DAILY_DATA_PATH .. ".LastClaimedAt", 0))

	if startDayStamp <= 0 or startDayStamp > currentDayStamp then
		startDayStamp = currentDayStamp
		set_if_changed(player, DAILY_DATA_PATH .. ".StartDayStamp", startDayStamp)
	end

	claimedDays = math.clamp(claimedDays, 0, TOTAL_DAYS)
	set_if_changed(player, DAILY_DATA_PATH .. ".ClaimedDays", claimedDays)

	if lastClaimedAt < 0 then
		lastClaimedAt = 0
		set_if_changed(player, DAILY_DATA_PATH .. ".LastClaimedAt", lastClaimedAt)
	end

	return currentDayStamp, startDayStamp, claimedDays
end

local function refresh_daily_state(player: Player): ()
	if player.Parent ~= Players then
		return
	end

	local currentDayStamp, startDayStamp, claimedDays = ensure_daily_profile_defaults(player)
	local availableDays = math.clamp((currentDayStamp - startDayStamp) + 1, 1, TOTAL_DAYS)
	local claimableDays = math.max(0, availableDays - claimedDays)

	set_if_changed(player, DAILY_DATA_PATH .. ".CurrentDayStamp", currentDayStamp)
	set_if_changed(player, DAILY_DATA_PATH .. ".AvailableDays", availableDays)
	set_if_changed(player, DAILY_DATA_PATH .. ".ClaimableDays", claimableDays)
end

local function build_claim_message(claimedDays: { number }, coinsGranted: number, weaponsGranted: { string }): string
	local parts: { string } = {
		"Claimed " .. tostring(#claimedDays) .. " daily reward" .. (if #claimedDays == 1 then "" else "s") .. ".",
	}

	if coinsGranted > 0 then
		table.insert(parts, "+" .. tostring(coinsGranted) .. " coins")
	end

	if #weaponsGranted > 0 then
		table.insert(parts, "Weapon: " .. table.concat(weaponsGranted, ", "))
	end

	return table.concat(parts, " ")
end

local function claim_all_rewards(player: Player): (boolean, string, { [string]: any }?)
	refresh_daily_state(player)

	local claimedDays = math.floor(get_number_value(player, DAILY_DATA_PATH .. ".ClaimedDays", 0))
	local availableDays = math.floor(get_number_value(player, DAILY_DATA_PATH .. ".AvailableDays", 0))
	local claimableDays = math.floor(get_number_value(player, DAILY_DATA_PATH .. ".ClaimableDays", 0))

	if claimableDays <= 0 or availableDays <= claimedDays then
		return false, "No daily rewards available right now.", nil
	end

	local nextCoins = get_player_coins(player)
	local ownedWeapons = normalize_owned_weapons(
		DataUtility.server.get(player, "WeaponsOwned"),
		DataUtility.server.get(player, "Skins")
	)
	local grantedCoins = 0
	local grantedWeapons: { string } = {}
	local claimedDayList: { number } = {}
	local nextClaimedDays = claimedDays

	for day = claimedDays + 1, availableDays do
		local reward = DailyRewardDictionary.get_reward(day)

		if reward then
			table.insert(claimedDayList, day)

			if reward.rewardType == DailyRewardDictionary.REWARD_TYPES.Coins then
				local rewardAmount = math.max(0, math.floor(reward.amount))
				nextCoins += rewardAmount
				grantedCoins += rewardAmount
			elseif reward.rewardType == DailyRewardDictionary.REWARD_TYPES.Weapon then
				local weaponName = reward.weaponName

				if typeof(weaponName) == "string" and ItemsDataDictionary.is_valid_weapon(weaponName) then
					if not has_weapon(ownedWeapons, weaponName) then
						table.insert(ownedWeapons, weaponName)
					end

					if not table.find(grantedWeapons, weaponName) then
						table.insert(grantedWeapons, weaponName)
					end
				end
			end

			nextClaimedDays += 1
		end
	end

	DataUtility.server.set(player, "Coins", nextCoins)
	DataUtility.server.set(player, "WeaponsOwned", normalize_owned_weapons(ownedWeapons, DataUtility.server.get(player, "Skins")))
	DataUtility.server.set(player, DAILY_DATA_PATH .. ".ClaimedDays", math.clamp(nextClaimedDays, 0, TOTAL_DAYS))
	DataUtility.server.set(player, DAILY_DATA_PATH .. ".LastClaimedAt", os.time())

	refresh_daily_state(player)

	return true, build_claim_message(claimedDayList, grantedCoins, grantedWeapons), {
		claimedDays = claimedDayList,
		coinsGranted = grantedCoins,
		weaponsGranted = grantedWeapons,
	}
end

local function start_refresh_loop(player: Player): ()
	local token = {}
	refreshTokensByUserId[player.UserId] = token

	task.spawn(function()
		local lastDayStamp = -1

		while refreshTokensByUserId[player.UserId] == token and player.Parent == Players do
			local currentDayStamp = get_current_day_stamp()

			if currentDayStamp ~= lastDayStamp then
				lastDayStamp = currentDayStamp
				refresh_daily_state(player)
			end

			task.wait(CLAIM_REFRESH_INTERVAL)
		end
	end)
end

local function on_player_added(player: Player): ()
	refresh_daily_state(player)
	start_refresh_loop(player)
end

local function on_player_removing(player: Player): ()
	refreshTokensByUserId[player.UserId] = nil
	claimLocks[player.UserId] = nil
end

local function on_daily_remote_event(player: Player, action: string): ()
	if action == "Sync" then
		refresh_daily_state(player)
		return
	end

	if action ~= "ClaimAll" then
		return
	end

	if claimLocks[player.UserId] then
		dailyRemote:FireClient(player, "ClaimResult", {
			success = false,
			message = "Your last claim is still being processed.",
		})
		return
	end

	claimLocks[player.UserId] = true

	local success, didClaim, message, payload = pcall(function()
		local claimSuccess, claimMessage, claimPayload = claim_all_rewards(player)
		return claimSuccess, claimMessage, claimPayload
	end)

	claimLocks[player.UserId] = nil

	if not success then
		warn("[DailyReward] Falha ao processar claim de " .. player.Name .. ": " .. tostring(didClaim))
		dailyRemote:FireClient(player, "ClaimResult", {
			success = false,
			message = "Daily reward claim failed. Try again.",
		})
		return
	end

	dailyRemote:FireClient(player, "ClaimResult", {
		success = didClaim,
		message = message,
		claimedDays = payload and payload.claimedDays or {},
		coinsGranted = payload and payload.coinsGranted or 0,
		weaponsGranted = payload and payload.weaponsGranted or {},
	})
end

------------------//MAIN FUNCTIONS
DataUtility.server.ensure_remotes()
dailyRemote.OnServerEvent:Connect(on_daily_remote_event)
Players.PlayerAdded:Connect(on_player_added)
Players.PlayerRemoving:Connect(on_player_removing)

for _, player in Players:GetPlayers() do
	task.spawn(function()
		on_player_added(player)
	end)
end

------------------//INIT

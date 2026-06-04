------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService: RunService = game:GetService("RunService")

------------------//CONSTANTS
local STORE_NAME: string = RunService:IsStudio() and "StudioData.01" or "Released_Data.01"

------------------//VARIABLES
local ProfileStore = require(script:WaitForChild("ProfileStore"))
local ProfileTemplate = require(script:WaitForChild("ProfileTemplate"))
local DataUtility = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utility"):WaitForChild("DataUtility"))

local store = ProfileStore.New(STORE_NAME, ProfileTemplate)

local profilesByUserId: {[number]: any} = {}
local joinTimesByUserId: {[number]: number} = {}

------------------//FUNCTIONS
local function add_session_time(player: Player): ()
	local profile = profilesByUserId[player.UserId]
	if not profile then
		return
	end

	local joinTime = joinTimesByUserId[player.UserId]
	if not joinTime then
		return
	end

	local sessionTime = math.max(0, math.floor(os.time() - joinTime))

	profile.Data.TimePlayed = (profile.Data.TimePlayed or 0) + sessionTime

	joinTimesByUserId[player.UserId] = nil
end

local function attach_player_profile(player: Player): ()
	local profile = store:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not profile then
		warn("Falha ao iniciar sessão do perfil para " .. player.Name)
		player:Kick("Não foi possível carregar seus dados. Tente entrar novamente.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profilesByUserId[player.UserId] = profile
	joinTimesByUserId[player.UserId] = os.time()

	DataUtility.server.attach_profile(player, profile)

	profile.OnSessionEnd:Connect(function()
		DataUtility.server.detach_profile(player)

		profilesByUserId[player.UserId] = nil
		joinTimesByUserId[player.UserId] = nil

		if player.Parent == Players then
			player:Kick("Sua sessão de dados foi encerrada. Entre novamente.")
		end
	end)
end

local function release_player_profile(player: Player): ()
	local profile = profilesByUserId[player.UserId]
	if not profile then
		return
	end

	add_session_time(player)

	profile:EndSession()

	profilesByUserId[player.UserId] = nil
	joinTimesByUserId[player.UserId] = nil
end

------------------//MAIN FUNCTIONS
local function on_player_added(player: Player): ()
	attach_player_profile(player)
end

local function on_player_removing(player: Player): ()
	release_player_profile(player)
end

------------------//INIT
DataUtility.server.ensure_remotes()

for _, player in Players:GetPlayers() do
	task.spawn(on_player_added, player)
end

Players.PlayerAdded:Connect(on_player_added)
Players.PlayerRemoving:Connect(on_player_removing)

ProfileStore.OnError:Connect(function(msg: string, storeName: string, key: string)
	warn(("[ProfileStore:%s %s] %s"):format(storeName, key, msg))
end)
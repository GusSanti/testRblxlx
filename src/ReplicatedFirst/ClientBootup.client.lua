------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local PLAYER_SCRIPTS_FOLDER_NAME: string = "PlayerScripts"

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerScripts: PlayerScripts = player:WaitForChild("PlayerScripts") :: PlayerScripts
local replicatedPlayerScripts: Folder = ReplicatedStorage:WaitForChild(PLAYER_SCRIPTS_FOLDER_NAME) :: Folder

------------------//FUNCTIONS
local function move_player_scripts(): ()
	local scripts = replicatedPlayerScripts:GetChildren()
	for _, scriptObject in scripts do
		if not playerScripts:FindFirstChild(scriptObject.Name) then
			scriptObject.Parent = playerScripts
		end
	end
end

------------------//INIT
move_player_scripts()

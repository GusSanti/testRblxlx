------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local PartyService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("PartyService"))

------------------//VARIABLES
local remotesFolderInstance: Folder? = ReplicatedStorage:FindFirstChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder?

if not remotesFolderInstance then
	remotesFolderInstance = Instance.new("Folder")
	remotesFolderInstance.Name = MatchmakingDictionary.REMOTE_FOLDER_NAME
	remotesFolderInstance.Parent = ReplicatedStorage
end

local remotesFolder: Folder = remotesFolderInstance :: Folder
local remoteEventInstance: RemoteEvent? = remotesFolder:FindFirstChild(MatchmakingDictionary.PARTY_REMOTE_EVENT_NAME) :: RemoteEvent?

if not remoteEventInstance then
	remoteEventInstance = Instance.new("RemoteEvent")
	remoteEventInstance.Name = MatchmakingDictionary.PARTY_REMOTE_EVENT_NAME
	remoteEventInstance.Parent = remotesFolder
end

local remoteEvent: RemoteEvent = remoteEventInstance :: RemoteEvent

------------------//MAIN FUNCTIONS
PartyService.start(remoteEvent)

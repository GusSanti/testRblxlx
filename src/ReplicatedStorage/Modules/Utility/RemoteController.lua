------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//VARIABLES
local RemoteController = {}
local RemoteNames = require(script.Parent:WaitForChild("RemoteNames") :: ModuleScript)

type RemoteClassName = "RemoteEvent" | "RemoteFunction"

------------------//FUNCTIONS
function RemoteController.create_folder(): Folder
	local existingFolder = ReplicatedStorage:FindFirstChild(RemoteNames.folderName)
	if existingFolder and existingFolder:IsA("Folder") then
		return existingFolder
	end

	local folder = Instance.new("Folder")
	folder.Name = RemoteNames.folderName
	folder.Parent = ReplicatedStorage
	return folder
end

function RemoteController.get_folder(): Folder
	return ReplicatedStorage:WaitForChild(RemoteNames.folderName) :: Folder
end

function RemoteController.create(remoteName: string, remoteClassName: RemoteClassName): Instance
	local remoteFolder = RemoteController.create_folder()
	local existingRemote = remoteFolder:FindFirstChild(remoteName)
	if existingRemote and existingRemote:IsA(remoteClassName) then
		return existingRemote
	end

	local remote = Instance.new(remoteClassName)
	remote.Name = remoteName
	remote.Parent = remoteFolder
	return remote
end

function RemoteController.get(remoteName: string, remoteClassName: RemoteClassName): Instance
	local remoteFolder = RemoteController.get_folder()
	local remote = remoteFolder:WaitForChild(remoteName)
	if not remote:IsA(remoteClassName) then
		error(remoteName .. " is not a " .. remoteClassName)
	end

	return remote
end

function RemoteController.create_event(remoteName: string): RemoteEvent
	return RemoteController.create(remoteName, "RemoteEvent") :: RemoteEvent
end

function RemoteController.create_function(remoteName: string): RemoteFunction
	return RemoteController.create(remoteName, "RemoteFunction") :: RemoteFunction
end

function RemoteController.get_event(remoteName: string): RemoteEvent
	return RemoteController.get(remoteName, "RemoteEvent") :: RemoteEvent
end

function RemoteController.get_function(remoteName: string): RemoteFunction
	return RemoteController.get(remoteName, "RemoteFunction") :: RemoteFunction
end

------------------//INIT
return RemoteController

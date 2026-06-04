------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui: StarterGui = game:GetService("StarterGui")

------------------//VARIABLES
local localPlayer: Player = Players.LocalPlayer
local playerScripts: PlayerScripts = localPlayer:WaitForChild("PlayerScripts")
local sourceFolder: Folder = ReplicatedStorage:WaitForChild("PlayerScripts")

task.spawn(function()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", false)
		end)

		if ok then
			return
		end

		task.wait(0.25)
	end
end)

------------------//MAIN FUNCTIONS
for _, scriptObj in sourceFolder:GetDescendants() do
	if scriptObj:IsA("LocalScript") then
		scriptObj.Parent = playerScripts
	end
end

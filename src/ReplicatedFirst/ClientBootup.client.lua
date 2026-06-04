local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer:WaitForChild("PlayerScripts")
local sourceFolder = ReplicatedStorage:WaitForChild("PlayerScripts")

task.spawn(function()
	for attempt = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", false)
		end)

		if ok then
			return
		end

		task.wait(0.25)
	end
end)

local descendants = sourceFolder:GetDescendants()
for _, scriptObj in ipairs(descendants) do
	if scriptObj:IsA("LocalScript") then
		print("[ClientBootup] Movendo LocalScript para PlayerScripts: " .. scriptObj:GetFullName())
		scriptObj.Parent = playerScripts
	end
end

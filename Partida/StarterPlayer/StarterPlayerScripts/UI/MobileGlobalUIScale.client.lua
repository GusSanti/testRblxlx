local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local MOBILE_SCALE = 1.2
local SCALE_OBJECT_NAME = "MobileGlobalScale"
local EXCLUDED_GUIS = {
	TouchGui = true,
	sideMenu = true,
	IngameHud = true,
	Slots = true,
}

if not UserInputService.TouchEnabled or UserInputService.KeyboardEnabled then
	return
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("NewUI")

local function applyScale(gui)
	if EXCLUDED_GUIS[gui.Name] then
		return
	end
	
	local scaleObject = gui:FindFirstChild(SCALE_OBJECT_NAME)
	if gui:FindFirstChildWhichIsA("UIScale") then
		return
	end
	

	if scaleObject and not scaleObject:IsA("UIScale") then
		scaleObject = nil
	end

	if not scaleObject then
		scaleObject = Instance.new("UIScale")
		scaleObject.Name = SCALE_OBJECT_NAME
		scaleObject.Parent = gui
	end

	scaleObject.Scale = MOBILE_SCALE
end

for _, gui in playerGui:GetChildren() do
	applyScale(gui)
end

playerGui.ChildAdded:Connect(applyScale)

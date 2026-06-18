local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local HOVER_SCALE = 1.1
local CLICK_SCALE = 1 / 1.2
local HOVER_DURATION = 0.2
local CLICK_DURATION = 0.2

local TARGET_CHILD_NAMES = {
	"Internal",
	"Contents",
	"Content",
	"Frame",
	"Main",
	"Holder",
	"Container",
	"Background",
	"Bg"
}

local setupStates = setmetatable({}, {__mode = "k"})

local function requireMouseOverModule()
	local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
	local rootModule = modulesFolder:FindFirstChild("MouseOverModule")
	if rootModule then
		return require(rootModule)
	end
	return require(modulesFolder:WaitForChild("Client"):WaitForChild("Simplebar"):WaitForChild("MouseOverModule"))
end

local MouseOverModule = requireMouseOverModule()

local function isLikelyFullSizeChild(child)
	local size = child.Size
	return size.X.Scale >= 1 and size.X.Offset == 0 and size.Y.Scale >= 1 and size.Y.Offset == 0
end

local function resolveAnimationTarget(button)
	local explicitTargetName = button:GetAttribute("AnimationTarget")
	if type(explicitTargetName) == "string" and explicitTargetName ~= "" then
		local explicitTarget = button:FindFirstChild(explicitTargetName, true)
		if explicitTarget and explicitTarget:IsA("GuiObject") then
			return explicitTarget
		end
	end

	local parent = button.Parent
	if button:IsA("TextButton") and button.BackgroundTransparency >= 1 and parent and parent:IsA("Frame") then
		return parent
	end

	for _, childName in ipairs(TARGET_CHILD_NAMES) do
		local child = button:FindFirstChild(childName)
		if child and child:IsA("GuiObject") then
			return child
		end
	end

	for _, child in ipairs(button:GetChildren()) do
		if child:IsA("GuiObject") then
			if isLikelyFullSizeChild(child) then
				return child
			end
		end
	end

	return button
end

local function getOrCreateScaleTarget(guiObject)
	local scaleObject = guiObject:FindFirstChildOfClass("UIScale")
	if not scaleObject then
		scaleObject = Instance.new("UIScale")
		scaleObject.Scale = 1
		scaleObject.Parent = guiObject
	end
	return scaleObject
end

local function tweenToScale(state, scaleValue, duration)
	if state.currentTween then
		state.currentTween:Cancel()
	end

	state.currentTween = TweenService:Create(
		state.scaleObject,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Scale = scaleValue}
	)
	state.currentTween:Play()
end

local function cleanupState(button)
	local state = setupStates[button]
	if not state then
		return
	end

	if state.currentTween then
		state.currentTween:Cancel()
	end

	for _, connection in ipairs(state.connections) do
		connection:Disconnect()
	end

	setupStates[button] = nil
end

local module = {}

function module.SetUp(button)
	if not button or not button:IsA("GuiButton") then
		return
	end

	if setupStates[button] then
		return
	end

	local animationTarget = resolveAnimationTarget(button)
	local state = {
		animationTarget = animationTarget,
		scaleObject = getOrCreateScaleTarget(animationTarget),
		isHovered = false,
		isPressed = false,
		currentTween = nil,
		connections = {}
	}
	setupStates[button] = state

	local mouseEnter, mouseLeave = MouseOverModule.MouseEnterLeaveEvent(button)

	state.connections[#state.connections + 1] = mouseEnter:Connect(function()
		state.isHovered = true
		if not state.isPressed then
			tweenToScale(state, HOVER_SCALE, HOVER_DURATION)
		end
	end)

	state.connections[#state.connections + 1] = mouseLeave:Connect(function()
		state.isHovered = false
		state.isPressed = false
		tweenToScale(state, 1, HOVER_DURATION)
	end)

	state.connections[#state.connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if state.isHovered then
				state.isPressed = true
				tweenToScale(state, CLICK_SCALE, CLICK_DURATION)
			end
		end
	end)

	state.connections[#state.connections + 1] = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if state.isPressed then
				state.isPressed = false
				tweenToScale(state, state.isHovered and HOVER_SCALE or 1, HOVER_DURATION)
			end
		end
	end)

	state.connections[#state.connections + 1] = button.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			cleanupState(button)
		end
	end)
end

return module

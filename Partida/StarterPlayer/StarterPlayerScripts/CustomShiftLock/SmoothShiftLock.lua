--[[

	@ Name: SmoothShiftLock
	@ Author: x33
	@ Version: 1.3.0
	
	@ Variables:
	└	.Enabled - ShiftLock's enabled state.
		
	@ Methods:
	│	:Enable() - Enables the whole module.
	│	:Disable() - Disables the whole module.
	│	:IsEnabled(): boolean - Returns ShiftLock's enabled state.
	└	:ToggleShiftLock(Enable: boolean?) - Toggles the ShiftLock, if Enable parameter is provided then ShiftLock will be toggled to it.

--]]

local SmoothShiftLock = {};
SmoothShiftLock.__index = SmoothShiftLock;

--// [ Locals: ]

--// Services
local Workspace = game:GetService("Workspace");
local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local ContextActionService = game:GetService("ContextActionService");
local UserInputService = game:GetService("UserInputService");

--// Utilities
local Maid = require(script:WaitForChild("Maid"));
local Spring = require(script:WaitForChild("Spring"));

--// Instances
local LocalPlayer = Players.LocalPlayer;
local PlayerMouse = LocalPlayer:GetMouse();
local Camera = Workspace.CurrentCamera;
local MOBILE_ACTION_NAME = "ShiftLockSwitchAction";

--// Configuration
local Config = {
	MOBILE_SUPPORT              = true,                      --// Adds a button to toggle the shift lock for touchscreen devices
	MOBILE_BUTTON_TITLE         = "Shift Lock",
	MOBILE_BUTTON_RAISE_OFFSET  = 48,
	SMOOTH_CHARACTER_ROTATION   = true,                       --// If your character should rotate smoothly or not
	CHARACTER_ROTATION_SPEED    = 3,                          --// How quickly character rotates smoothly
	TRANSITION_SPRING_DAMPER    = 0.7,                        --// Camera transition spring damper, test it out to see what works for you
	CAMERA_TRANSITION_IN_SPEED  = 10,                         --// How quickly locked camera moves to offset position
	CAMERA_TRANSITION_OUT_SPEED = 14,                         --// How quickly locked camera moves back from offset position
	LOCKED_CAMERA_OFFSET        = Vector3.new(1.75, 0.25, 0), --// Locked camera offset
	LOCKED_MOUSE_ICON           =                             --// Locked mouse icon
		"rbxassetid://125422396581305",
	SHIFT_LOCK_KEYBINDS         =                             --// Shift lock keybinds
		{Enum.KeyCode.LeftControl}
};

--// [ Constructor: ]
function SmoothShiftLock.new()
	local self = setmetatable({}, SmoothShiftLock);

	--// Utilities
	self._runtimeMaid = Maid.new();
	self._shiftlockMaid = Maid.new();
	self._cameraOffsetSpring = Spring.new(Vector3.new(0, 0, 0));
	self._cameraOffsetSpring.Damper = Config.TRANSITION_SPRING_DAMPER;

	--// Variables
	self.Enabled = false;

	--// Setup
	self:Enable();

	return self;
end;

function SmoothShiftLock:_getRaisedMobileButtonPosition(basePosition: UDim2): UDim2
	return UDim2.new(
		basePosition.X.Scale,
		basePosition.X.Offset,
		basePosition.Y.Scale,
		basePosition.Y.Offset - Config.MOBILE_BUTTON_RAISE_OFFSET
	);
end;

function SmoothShiftLock:_applyMobileButtonPosition(mobileButton: GuiObject)
	if not self._mobileButtonTargetPosition then
		self._mobileButtonTargetPosition = self:_getRaisedMobileButtonPosition(mobileButton.Position);
	end;

	pcall(function()
		ContextActionService:SetPosition(MOBILE_ACTION_NAME, self._mobileButtonTargetPosition);
	end);

	if mobileButton.Position ~= self._mobileButtonTargetPosition then
		mobileButton.Position = self._mobileButtonTargetPosition;
	end;
end;

function SmoothShiftLock:_updateMobileButtonTitle(mobileButton: GuiObject)
	local ActionTitle = mobileButton:FindFirstChild("ActionTitle", true);
	if ActionTitle and ActionTitle:IsA("TextLabel") then
		ActionTitle.Text = Config.MOBILE_BUTTON_TITLE;
		return;
	end;

	local CustomTitle = mobileButton:FindFirstChild("ShiftLockLabel");
	if not CustomTitle then
		CustomTitle = Instance.new("TextLabel");
		CustomTitle.Name = "ShiftLockLabel";
		CustomTitle.BackgroundTransparency = 1;
		CustomTitle.AnchorPoint = Vector2.new(0.5, 0);
		CustomTitle.Position = UDim2.new(0.5, 0, 1, 4);
		CustomTitle.Size = UDim2.new(1.8, 0, 0, 18);
		CustomTitle.Font = Enum.Font.GothamBold;
		CustomTitle.TextColor3 = Color3.fromRGB(255, 255, 255);
		CustomTitle.TextStrokeTransparency = 0.35;
		CustomTitle.TextScaled = true;
		CustomTitle.ZIndex = mobileButton.ZIndex + 1;
		CustomTitle.Parent = mobileButton;
	end;

	CustomTitle.Text = Config.MOBILE_BUTTON_TITLE;
end;

function SmoothShiftLock:_ensureCustomMobileButton(templateButton: GuiObject): GuiObject
	if self._customMobileButton and self._customMobileButton.Parent then
		return self._customMobileButton;
	end;

	local CustomButton = templateButton:Clone();
	CustomButton.Name = "ShiftLockCustomMobileButton";
	CustomButton.Visible = true;
	CustomButton.Active = true;
	CustomButton.Parent = templateButton.Parent;

	if CustomButton:IsA("ImageButton") then
		CustomButton.AutoButtonColor = false;
		CustomButton.HoverImage = CustomButton.Image;
		CustomButton.PressedImage = CustomButton.Image;
	end;

	self._runtimeMaid:GiveTask(CustomButton.Activated:Connect(function()
		self:ToggleShiftLock();
	end));

	self._customMobileButton = CustomButton;
	return CustomButton;
end;

function SmoothShiftLock:_configureMobileButton()
	if not Config.MOBILE_SUPPORT or not UserInputService.TouchEnabled then
		return;
	end;

	pcall(function()
		ContextActionService:SetTitle(MOBILE_ACTION_NAME, Config.MOBILE_BUTTON_TITLE);
	end);

	task.defer(function()
		local MobileButton;
		for _ = 1, 10 do
			MobileButton = ContextActionService:GetButton(MOBILE_ACTION_NAME);
			if MobileButton then
				break;
			end;
			task.wait();
		end;

		if not MobileButton then
			return;
		end;

		self:_applyMobileButtonPosition(MobileButton);
		self:_updateMobileButtonTitle(MobileButton);

		local CustomButton = self:_ensureCustomMobileButton(MobileButton);
		CustomButton.Position = self._mobileButtonTargetPosition;
		CustomButton.Size = MobileButton.Size;
		CustomButton.AnchorPoint = MobileButton.AnchorPoint;
		self:_updateMobileButtonTitle(CustomButton);

		MobileButton.Visible = false;
		MobileButton.Active = false;
	end);
end;

--// [ Module Functions: ]
function SmoothShiftLock:Enable()
	self:_refreshCharacterVariables();
	self._runtimeMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
		self:_refreshCharacterVariables();
	end));

	--// Bind Keybinds
	ContextActionService:BindActionAtPriority(MOBILE_ACTION_NAME, function(Name, State, Input)
		return self:_doShiftLockSwitch(Name, State, Input);
	end, Config.MOBILE_SUPPORT, Enum.ContextActionPriority.Medium.Value, unpack(Config.SHIFT_LOCK_KEYBINDS));
	self:_configureMobileButton();

	--// Camera Offset
	RunService:BindToRenderStep("ShiftLockCameraUpdate", Enum.RenderPriority.Camera.Value + 1, function()
		if self.Head.LocalTransparencyModifier > 0.6 then return; end;

		local CameraCFrame = Camera.CoordinateFrame;
		local Distance = (self.Head.Position - CameraCFrame.p).magnitude;

		--// Camera offset
		if Distance > 1 then	
			Camera.CFrame = (Camera.CFrame * CFrame.new(self._cameraOffsetSpring.Position)); 
			if self.Enabled and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
				self:_updateMouseState();
			end;
		end;
	end)
end;

function SmoothShiftLock:Disable()
	self._runtimeMaid:DoCleaning();
	self._shiftlockMaid:DoCleaning();

	--// Unbind Camera Update
	RunService:UnbindFromRenderStep("ShiftLockCameraUpdate")

	--// Unbind Keybinds
	ContextActionService:UnbindAction(MOBILE_ACTION_NAME);
end;

--// [ Internal Functions: ]
function SmoothShiftLock:_refreshCharacterVariables()
	self.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
	self.RootPart = self.Character:WaitForChild("HumanoidRootPart");
	self.Humanoid = self.Character:WaitForChild("Humanoid");
	self.Head = self.Character:WaitForChild("Head");
end;

--// Internal function for ContextActionService
function SmoothShiftLock:_doShiftLockSwitch(_, State: Enum.UserInputState)
	if State == Enum.UserInputState.Begin then
		self:ToggleShiftLock();
		return Enum.ContextActionResult.Sink;
	end;

	return Enum.ContextActionResult.Pass;
end;

--// Update the mouse behaviour
function SmoothShiftLock:_updateMouseState()
	UserInputService.MouseBehavior = (self.Enabled and Enum.MouseBehavior.LockCenter) or Enum.MouseBehavior.Default;
end;

--// Update the mouse icon
function SmoothShiftLock:_updateMouseIcon()
	PlayerMouse.Icon = (self.Enabled and Config.LOCKED_MOUSE_ICON :: string) or "";
end;

--// Transition the camera to lock offset
function SmoothShiftLock:_transitionLockOffset()
	if self.Enabled then
		self._cameraOffsetSpring.Speed = Config.CAMERA_TRANSITION_IN_SPEED;
		self._cameraOffsetSpring.Target = Config.LOCKED_CAMERA_OFFSET;
	else
		self._cameraOffsetSpring.Speed = Config.CAMERA_TRANSITION_OUT_SPEED;
		self._cameraOffsetSpring.Target = Vector3.new(0, 0, 0);
	end;
end;

--// [ External Functions: ]
function SmoothShiftLock:IsEnabled(): boolean
	return self.Enabled;
end;

--// ShiftLock toggle function
function SmoothShiftLock:ToggleShiftLock(Enable: boolean?)
	if Enable ~= nil then
		self.Enabled = Enable;
	else
		self.Enabled = not self.Enabled;
	end;

	self:_updateMouseState();
	self:_updateMouseIcon();
	self:_transitionLockOffset();
	if self.Enabled then
		self._shiftlockMaid:GiveTask(RunService.RenderStepped:Connect(function(Delta: number)
			if (self.Humanoid and self.RootPart) then 
				self.Humanoid.AutoRotate = not self.Enabled;
			end;

			--// Rotate the character
			if self.Humanoid.Sit then return; end;
			if Config.SMOOTH_CHARACTER_ROTATION then
				local x, y, z = Camera.CFrame:ToOrientation();
				self.RootPart.CFrame = self.RootPart.CFrame:Lerp(CFrame.new(self.RootPart.Position) * CFrame.Angles(0, y, 0), Delta * 5 * Config.CHARACTER_ROTATION_SPEED);
			else
				local x, y, z = Camera.CFrame:ToOrientation();
				self.RootPart.CFrame = CFrame.new(self.RootPart.Position) * CFrame.Angles(0, y, 0);
			end;
		end));
	else
		self.Humanoid.AutoRotate = true;
		self._shiftlockMaid:DoCleaning();
	end;
end;

return SmoothShiftLock.new();

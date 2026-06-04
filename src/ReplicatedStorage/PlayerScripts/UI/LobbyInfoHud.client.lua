------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local LOBBY_GUI_NAME = "Lobby"
local COINS_LABEL_NAME = "Coins"

local modulesFolder: Folder = ReplicatedStorage:WaitForChild("Modules") :: Folder
local utilityFolder: Folder = modulesFolder:WaitForChild("Utility") :: Folder
local DataUtility = require(utilityFolder:WaitForChild("DataUtility"))

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local lobbyGui: ScreenGui? = nil
local coinsLabel: TextLabel? = nil

local lobbyDescendantAddedConnection: RBXScriptConnection? = nil
local lobbyDescendantRemovingConnection: RBXScriptConnection? = nil
local playerGuiChildAddedConnection: RBXScriptConnection? = nil
local coinsBindConnection: { Disconnect: (self: any) -> () }? = nil

------------------//FUNCTIONS
local function parse_coins(value: any): number
	if typeof(value) == "number" then
		return math.max(0, math.floor(value))
	end

	return 0
end

local function find_coins_label(root: Instance): TextLabel?
	local direct = root:FindFirstChild(COINS_LABEL_NAME)

	if direct and direct:IsA("TextLabel") then
		return direct
	end

	for _, desc in root:GetDescendants() do
		if desc.Name == COINS_LABEL_NAME and desc:IsA("TextLabel") then
			return desc
		end
	end

	return nil
end

local function ensure_lobby_gui(): ScreenGui?
	if lobbyGui and lobbyGui.Parent == playerGui then
		return lobbyGui
	end

	local found = playerGui:FindFirstChild(LOBBY_GUI_NAME)

	if found and found:IsA("ScreenGui") then
		lobbyGui = found
		return found
	end

	lobbyGui = nil
	return nil
end

local function refresh_coins_label_reference(): ()
	local currentLobbyGui = ensure_lobby_gui()

	if not currentLobbyGui then
		coinsLabel = nil
		return
	end

	coinsLabel = find_coins_label(currentLobbyGui)
end

local function render_coins(value: any?): ()
	local coinsValue = value

	if coinsValue == nil then
		coinsValue = DataUtility.client.get("Coins")
	end

	refresh_coins_label_reference()

	if not coinsLabel then
		return
	end

	coinsLabel.Text = tostring(parse_coins(coinsValue)) .. " $$"
end

local function bind_lobby_gui(gui: ScreenGui): ()
	lobbyGui = gui

	if lobbyDescendantAddedConnection then
		lobbyDescendantAddedConnection:Disconnect()
		lobbyDescendantAddedConnection = nil
	end

	if lobbyDescendantRemovingConnection then
		lobbyDescendantRemovingConnection:Disconnect()
		lobbyDescendantRemovingConnection = nil
	end

	lobbyDescendantAddedConnection = gui.DescendantAdded:Connect(function(desc: Instance)
		if desc.Name == COINS_LABEL_NAME and desc:IsA("TextLabel") then
			coinsLabel = desc
			render_coins(nil)
		end
	end)

	lobbyDescendantRemovingConnection = gui.DescendantRemoving:Connect(function(desc: Instance)
		if coinsLabel and desc == coinsLabel then
			coinsLabel = nil
		end
	end)

	refresh_coins_label_reference()
	render_coins(nil)
end

local function on_player_gui_child_added(child: Instance): ()
	if child.Name ~= LOBBY_GUI_NAME or not child:IsA("ScreenGui") then
		return
	end

	bind_lobby_gui(child)
end

------------------//MAIN FUNCTIONS
DataUtility.client.ensure_remotes()

local currentLobbyGui = ensure_lobby_gui()

if currentLobbyGui then
	bind_lobby_gui(currentLobbyGui)
end

if coinsBindConnection then
	coinsBindConnection:Disconnect()
end

coinsBindConnection = DataUtility.client.bind("Coins", function(value: any)
	render_coins(value)
end)

if playerGuiChildAddedConnection then
	playerGuiChildAddedConnection:Disconnect()
end

playerGuiChildAddedConnection = playerGui.ChildAdded:Connect(on_player_gui_child_added)
render_coins(nil)

------------------//INIT

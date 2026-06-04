------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui: StarterGui = game:GetService("StarterGui")
local TextChatService: TextChatService = game:GetService("TextChatService")

------------------//CONSTANTS
local MatchmakingDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("MatchmakingDictionary"))
local DailyRewardDictionary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Dictionary"):WaitForChild("DailyRewardDictionary"))
local PagesClientService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("PagesClientService"))

local modulesFolder: Folder = ReplicatedStorage:WaitForChild("Modules") :: Folder
local utilityFolder: Folder = modulesFolder:WaitForChild("Utility") :: Folder
local DataUtility = require(utilityFolder:WaitForChild("DataUtility"))

local DAILY_PAGE_NAME = "Daily"
local DAILY_TOGGLE_BUTTON_NAME = "DailyReward"
local DEBUG_PREFIX = "[DailyReward]"

local CHAT_COLORS = {
	Info = Color3.fromRGB(185, 220, 255),
	Warn = Color3.fromRGB(255, 218, 120),
	Error = Color3.fromRGB(255, 135, 135),
	Success = Color3.fromRGB(130, 255, 160),
}

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local lobbyGui: ScreenGui = playerGui:WaitForChild("Lobby") :: ScreenGui
local pagesGui: ScreenGui? = nil

local remotesFolder: Folder = ReplicatedStorage:WaitForChild(MatchmakingDictionary.REMOTE_FOLDER_NAME) :: Folder
local dailyRemote: RemoteEvent = remotesFolder:WaitForChild(MatchmakingDictionary.DAILY_REWARD_REMOTE_EVENT_NAME) :: RemoteEvent

local dailyPage: GuiObject? = nil
local dailyContainer: GuiObject? = nil
local dayTemplate: GuiObject? = nil
local dayClaimedTemplate: GuiObject? = nil
local claimButton: GuiButton? = nil
local closeButton: GuiButton? = nil

local bindClaimedConnection: { Disconnect: (self: any) -> () }? = nil
local bindAvailableConnection: { Disconnect: (self: any) -> () }? = nil
local bindClaimableConnection: { Disconnect: (self: any) -> () }? = nil
local playerGuiChildAddedConnection: RBXScriptConnection? = nil
local lobbyDescendantAddedConnection: RBXScriptConnection? = nil
local uiConfigured = false

local claimInProgress = false

------------------//FUNCTIONS
local function get_chat_color(colorName: string?): Color3
	if colorName and CHAT_COLORS[colorName] then
		return CHAT_COLORS[colorName]
	end

	return CHAT_COLORS.Info
end

local function try_system_message(text: string, colorName: string?): boolean
	local textChannels = TextChatService:FindFirstChild("TextChannels")
	local generalChannel = textChannels and textChannels:FindFirstChild("RBXGeneral")

	if generalChannel and generalChannel:IsA("TextChannel") then
		generalChannel:DisplaySystemMessage(text)
		return true
	end

	local success = pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = text,
			Color = get_chat_color(colorName),
		})
	end)

	return success
end

local function send_debug(message: string, colorName: string?): ()
	local text = DEBUG_PREFIX .. " " .. message

	if try_system_message(text, colorName) then
		return
	end

	task.spawn(function()
		local attempts = 0

		while attempts < 8 do
			attempts += 1
			task.wait(0.5)

			if try_system_message(text, colorName) then
				return
			end
		end
	end)
end

local function get_number_value(path: string): number
	local value = DataUtility.client.get(path)

	if typeof(value) ~= "number" then
		return 0
	end

	return math.max(0, math.floor(value))
end

local function refresh_pages_gui(): ScreenGui?
	local foundPages = playerGui:FindFirstChild("Pages")

	if foundPages and foundPages:IsA("ScreenGui") then
		pagesGui = foundPages
		return foundPages
	end

	pagesGui = nil
	return nil
end

local function is_daily_panel_candidate(instance: Instance?): boolean
	if not instance or not instance:IsA("GuiObject") then
		return false
	end

	local scrollingFrame = instance:FindFirstChild("ScrollingFrame", true)
	local claimBt = instance:FindFirstChild("ClaimBt", true)

	if not scrollingFrame or not scrollingFrame:IsA("GuiObject") or not claimBt or not claimBt:IsA("GuiButton") then
		return false
	end

	local day = scrollingFrame:FindFirstChild("Day")
	local dayClaimed = scrollingFrame:FindFirstChild("DayClaimed")

	return day ~= nil and day:IsA("GuiObject") and dayClaimed ~= nil and dayClaimed:IsA("GuiObject")
end

local function find_daily_page(): GuiObject?
	local currentPagesGui = refresh_pages_gui()
	local pagesDaily = currentPagesGui and currentPagesGui:FindFirstChild(DAILY_PAGE_NAME)

	if is_daily_panel_candidate(pagesDaily) then
		return pagesDaily :: GuiObject
	end

	local pagesDailyReward = currentPagesGui and currentPagesGui:FindFirstChild(DAILY_TOGGLE_BUTTON_NAME)

	if is_daily_panel_candidate(pagesDailyReward) then
		return pagesDailyReward :: GuiObject
	end

	local lobbyDaily = lobbyGui:FindFirstChild(DAILY_PAGE_NAME)

	if is_daily_panel_candidate(lobbyDaily) then
		return lobbyDaily :: GuiObject
	end

	local lobbyDailyReward = lobbyGui:FindFirstChild(DAILY_TOGGLE_BUTTON_NAME)

	if is_daily_panel_candidate(lobbyDailyReward) then
		return lobbyDailyReward :: GuiObject
	end

	for _, descendant in lobbyGui:GetDescendants() do
		if (descendant.Name == DAILY_PAGE_NAME or descendant.Name == DAILY_TOGGLE_BUTTON_NAME) and is_daily_panel_candidate(descendant) then
			return descendant :: GuiObject
		end
	end

	if currentPagesGui then
		for _, descendant in currentPagesGui:GetDescendants() do
			if (descendant.Name == DAILY_PAGE_NAME or descendant.Name == DAILY_TOGGLE_BUTTON_NAME) and is_daily_panel_candidate(descendant) then
				return descendant :: GuiObject
			end
		end
	end

	for _, descendant in playerGui:GetDescendants() do
		if descendant == lobbyGui or descendant == currentPagesGui then
			continue
		end

		if (descendant.Name == DAILY_PAGE_NAME or descendant.Name == DAILY_TOGGLE_BUTTON_NAME) and is_daily_panel_candidate(descendant) then
			return descendant :: GuiObject
		end
	end

	return nil
end

local function find_daily_toggle_button(): GuiButton?
	local holder = lobbyGui:FindFirstChild("Holder")

	if not holder then
		return nil
	end

	local button = holder:FindFirstChild(DAILY_PAGE_NAME)

	if button and button:IsA("GuiButton") then
		return button
	end

	local dailyRewardButton = holder:FindFirstChild(DAILY_TOGGLE_BUTTON_NAME)

	if dailyRewardButton and dailyRewardButton:IsA("GuiButton") then
		return dailyRewardButton
	end

	return nil
end

local function clear_rows(): ()
	local container = dailyContainer
	local rawDayTemplate = dayTemplate
	local rawClaimedTemplate = dayClaimedTemplate

	if not container or not rawDayTemplate or not rawClaimedTemplate then
		return
	end

	for _, child in container:GetChildren() do
		if child ~= rawDayTemplate and child ~= rawClaimedTemplate and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function fill_reward_card(card: GuiObject, reward, isClaimed: boolean): ()
	local rewardName = card:FindFirstChild("RewardName")
	local amount = card:FindFirstChild("Amount")
	local dayLabel = card:FindFirstChild("Day")
	local claimedLabel = card:FindFirstChild("Claimed")
	local icon = card:FindFirstChild("Icon")

	if rewardName and (rewardName:IsA("TextLabel") or rewardName:IsA("TextButton")) then
		rewardName.Text = reward.rewardName
	end

	if amount and (amount:IsA("TextLabel") or amount:IsA("TextButton")) then
		amount.Text = DailyRewardDictionary.get_amount_text(reward)
	end

	if dayLabel and (dayLabel:IsA("TextLabel") or dayLabel:IsA("TextButton")) then
		dayLabel.Text = "Day " .. tostring(reward.day)
	end

	if claimedLabel and claimedLabel:IsA("GuiObject") then
		claimedLabel.Visible = isClaimed
	end

	if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
		icon.Image = reward.iconImage
	end
end

local function update_claim_button(): ()
	if not claimButton then
		return
	end

	local claimableDays = get_number_value("DailyRewards.ClaimableDays")
	local canClaim = claimableDays > 0 and not claimInProgress

	claimButton.Active = canClaim
	claimButton.AutoButtonColor = canClaim

	if claimButton:IsA("TextButton") then
		if claimInProgress then
			claimButton.Text = "Claiming..."
		elseif claimableDays > 1 then
			claimButton.Text = "Claim All"
		elseif claimableDays == 1 then
			claimButton.Text = "Claim"
		else
			claimButton.Text = "No Reward"
		end
	end
end

local function render_daily_rewards(): ()
	local container = dailyContainer
	local rawDayTemplate = dayTemplate
	local rawClaimedTemplate = dayClaimedTemplate

	if not container or not rawDayTemplate or not rawClaimedTemplate then
		return
	end

	local claimedDays = math.clamp(get_number_value("DailyRewards.ClaimedDays"), 0, DailyRewardDictionary.TOTAL_DAYS)
	local availableDays = math.clamp(get_number_value("DailyRewards.AvailableDays"), 0, DailyRewardDictionary.TOTAL_DAYS)

	rawDayTemplate.Visible = false
	rawClaimedTemplate.Visible = false
	clear_rows()

	for _, reward in DailyRewardDictionary.get_rewards() do
		local useClaimedTemplate = reward.day <= availableDays
		local card = if useClaimedTemplate then rawClaimedTemplate:Clone() else rawDayTemplate:Clone()

		card.Name = "DailyReward_" .. tostring(reward.day)
		card.LayoutOrder = reward.day
		card.Visible = true

		fill_reward_card(card, reward, reward.day <= claimedDays)
		card.Parent = container
	end

	update_claim_button()
end

local function open_daily_page(): ()
	if not dailyPage then
		return
	end

	dailyPage.Visible = true
	PagesClientService.open_page(DAILY_PAGE_NAME)
	dailyRemote:FireServer("Sync")
end

local function close_daily_page(): ()
	if not dailyPage then
		return
	end

	dailyPage.Visible = false
	PagesClientService.close_page(DAILY_PAGE_NAME)
end

local function configure_ui(): ()
	if uiConfigured then
		return
	end

	dailyPage = find_daily_page()

	if not dailyPage then
		return
	end

	local scrollingFrame = dailyPage:FindFirstChild("ScrollingFrame", true)
	local claimBt = dailyPage:FindFirstChild("ClaimBt", true)
	local closeBt = dailyPage:FindFirstChild("Close", true)

	if not scrollingFrame or not scrollingFrame:IsA("GuiObject") or not claimBt or not claimBt:IsA("GuiButton") then
		return
	end

	local foundDayTemplate = scrollingFrame:FindFirstChild("Day")
	local foundDayClaimedTemplate = scrollingFrame:FindFirstChild("DayClaimed")

	if not foundDayTemplate or not foundDayTemplate:IsA("GuiObject") or not foundDayClaimedTemplate or not foundDayClaimedTemplate:IsA("GuiObject") then
		return
	end

	dailyContainer = scrollingFrame
	dayTemplate = foundDayTemplate
	dayClaimedTemplate = foundDayClaimedTemplate
	claimButton = claimBt
	closeButton = if closeBt and closeBt:IsA("GuiButton") then closeBt else nil

	dayTemplate.Visible = false
	dayClaimedTemplate.Visible = false
	uiConfigured = true

	PagesClientService.register_page(DAILY_PAGE_NAME, dailyPage)

	local toggleButton = find_daily_toggle_button()

	if toggleButton then
		toggleButton.Activated:Connect(function()
			open_daily_page()
		end)
	end

	if closeButton then
		closeButton.Activated:Connect(function()
			close_daily_page()
		end)
	end

	claimButton.Activated:Connect(function()
		if claimInProgress or get_number_value("DailyRewards.ClaimableDays") <= 0 then
			return
		end

		claimInProgress = true
		update_claim_button()
		dailyRemote:FireServer("ClaimAll")
	end)

	if dailyPage.Visible then
		PagesClientService.open_page(DAILY_PAGE_NAME)
	else
		PagesClientService.close_page(DAILY_PAGE_NAME)
	end

	render_daily_rewards()
end

local function on_daily_remote_event(action: string, payload: any): ()
	if action ~= "ClaimResult" then
		return
	end

	claimInProgress = false
	update_claim_button()

	if typeof(payload) ~= "table" then
		send_debug("Daily reward atualizado.", "Info")
		return
	end

	local message = if typeof(payload.message) == "string" then payload.message else "Daily reward updated."
	local success = payload.success == true
	send_debug(message, if success then "Success" else "Warn")
end

------------------//MAIN FUNCTIONS
DataUtility.client.ensure_remotes()
configure_ui()

dailyRemote.OnClientEvent:Connect(on_daily_remote_event)

if bindClaimedConnection then
	bindClaimedConnection:Disconnect()
end

bindClaimedConnection = DataUtility.client.bind("DailyRewards.ClaimedDays", function(_value: any)
	render_daily_rewards()
end)

if bindAvailableConnection then
	bindAvailableConnection:Disconnect()
end

bindAvailableConnection = DataUtility.client.bind("DailyRewards.AvailableDays", function(_value: any)
	render_daily_rewards()
end)

if bindClaimableConnection then
	bindClaimableConnection:Disconnect()
end

bindClaimableConnection = DataUtility.client.bind("DailyRewards.ClaimableDays", function(_value: any)
	update_claim_button()
end)

if playerGuiChildAddedConnection then
	playerGuiChildAddedConnection:Disconnect()
end

playerGuiChildAddedConnection = playerGui.ChildAdded:Connect(function(child: Instance)
	if uiConfigured then
		return
	end

	if child.Name == "Pages" or child.Name == "Lobby" or child.Name == DAILY_PAGE_NAME or child.Name == DAILY_TOGGLE_BUTTON_NAME then
		task.defer(configure_ui)
	end
end)

if lobbyDescendantAddedConnection then
	lobbyDescendantAddedConnection:Disconnect()
end

lobbyDescendantAddedConnection = lobbyGui.DescendantAdded:Connect(function(descendant: Instance)
	if uiConfigured then
		return
	end

	if descendant.Name == DAILY_PAGE_NAME or descendant.Name == DAILY_TOGGLE_BUTTON_NAME or descendant.Name == "ScrollingFrame" or descendant.Name == "ClaimBt" then
		task.defer(configure_ui)
	end
end)

dailyRemote:FireServer("Sync")

------------------//INIT

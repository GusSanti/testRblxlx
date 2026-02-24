------------------//SERVICES
local DataStoreService: DataStoreService = game:GetService("DataStoreService")
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local COINS_DATASTORE_NAME = "Global_TopCoins_V1"
local HATCHED_DATASTORE_NAME = "Global_TopHatched_V1"
local TIME_DATASTORE_NAME = "Global_TimePlayed_V1"

local UPDATE_INTERVAL = 60
local MAX_PLAYERS_ON_BOARD = 50

------------------//VARIABLES
local DataUtility = require(ReplicatedStorage.Modules.Utility.DataUtility)

local coinsODS: OrderedDataStore = DataStoreService:GetOrderedDataStore(COINS_DATASTORE_NAME)
local hatchedODS: OrderedDataStore = DataStoreService:GetOrderedDataStore(HATCHED_DATASTORE_NAME)
local timePlayedODS: OrderedDataStore = DataStoreService:GetOrderedDataStore(TIME_DATASTORE_NAME)

local coinLeaderboard: BasePart? = workspace:FindFirstChild("CoinLeaderboard", true)
local hatchedLeaderboard: BasePart? = workspace:FindFirstChild("HatchedLeaderboard", true)
local timeLeaderboard: BasePart? = workspace:FindFirstChild("TimeLeaderboard", true)

local coinList: ScrollingFrame? = nil
local hatchedList: ScrollingFrame? = nil
local timeList: ScrollingFrame? = nil

------------------//FUNCTIONS
local function format_abbreviation(value: number): string
	if value >= 1e9 then
		return string.format("%.1fB", value / 1e9)
	elseif value >= 1e6 then
		return string.format("%.1fM", value / 1e6)
	elseif value >= 1e3 then
		return string.format("%.1fK", value / 1e3)
	else
		return tostring(value)
	end
end

local function create_ui(part: BasePart?, titleText: string): ScrollingFrame?
	if not part then 
		warn("BasePart para o Leaderboard não encontrada!")
		return nil 
	end

	local oldGui = part:FindFirstChild("LeaderboardGui")
	if oldGui then
		oldGui:Destroy()
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = part

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundTransparency = 1
	background.Parent = surfaceGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0.15, 0)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Parent = background

	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MaxTextSize = 35
	titleConstraint.MinTextSize = 15
	titleConstraint.Parent = title

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "List"
	scrollFrame.Size = UDim2.new(1, -20, 0.8, -20)
	scrollFrame.Position = UDim2.new(0, 10, 0.15, 10)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

	listLayout.Parent = scrollFrame
	scrollFrame.Parent = background

	return scrollFrame
end

local function create_row(parent: ScrollingFrame, rank: number, userId: number, value: number, isTime: boolean?): ()
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -10, 0, 40)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	row.BackgroundTransparency = 0.1
	row.LayoutOrder = rank

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	if rank == 1 then row.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	elseif rank == 2 then row.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	elseif rank == 3 then row.BackgroundColor3 = Color3.fromRGB(205, 127, 50)
	end

	-- Texto do Rank
	local rankText = Instance.new("TextLabel")
	rankText.Size = UDim2.new(0.15, 0, 0.6, 0)
	rankText.Position = UDim2.new(0.02, 0, 0.2, 0)
	rankText.BackgroundTransparency = 1
	rankText.Text = "#" .. tostring(rank)
	rankText.TextColor3 = rank <= 3 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	rankText.Font = Enum.Font.GothamBold
	rankText.TextScaled = true
	rankText.Parent = row

	local rankConstraint = Instance.new("UITextSizeConstraint")
	rankConstraint.MaxTextSize = 20
	rankConstraint.Parent = rankText

	-- Avatar Imagem
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 30, 0, 30)
	avatar.Position = UDim2.new(0.18, 0, 0.5, -15)
	avatar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar
	avatar.Parent = row

	task.spawn(function()
		local success, thumb = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		if success then
			avatar.Image = thumb
		end
	end)

	-- Nome do Jogador
	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.new(0.4, 0, 0.6, 0)
	nameText.Position = UDim2.new(0.18, 40, 0.2, 0)
	nameText.BackgroundTransparency = 1
	nameText.TextXAlignment = Enum.TextXAlignment.Left
	nameText.Text = "Loading..."
	nameText.TextColor3 = rank <= 3 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	nameText.Font = Enum.Font.GothamSemibold
	nameText.TextScaled = true
	nameText.Parent = row

	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MaxTextSize = 16
	nameConstraint.Parent = nameText

	task.spawn(function()
		local success, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if success then
			nameText.Text = name
		else
			nameText.Text = "Unknown"
		end
	end)

	-- Valor (Formata para horas caso seja o Leaderboard de Tempo, caso contrário abreviação padrão)
	local valText = Instance.new("TextLabel")
	valText.Size = UDim2.new(0.3, 0, 0.6, 0)
	valText.Position = UDim2.new(0.68, 0, 0.2, 0)
	valText.BackgroundTransparency = 1
	valText.TextXAlignment = Enum.TextXAlignment.Right
	valText.Text = isTime and string.format("%.1fh", value / 3600) or format_abbreviation(value)
	valText.TextColor3 = rank <= 3 and Color3.new(0, 0, 0) or Color3.fromRGB(150, 255, 150)
	valText.Font = Enum.Font.GothamBold
	valText.TextScaled = true
	valText.Parent = row

	local valConstraint = Instance.new("UITextSizeConstraint")
	valConstraint.MaxTextSize = 18
	valConstraint.Parent = valText

	row.Parent = parent
end

local function update_board_ui(listFrame: ScrollingFrame?, orderedDataStore: OrderedDataStore, isTime: boolean?): ()
	if not listFrame then return end

	local success, pages = pcall(function()
		return orderedDataStore:GetSortedAsync(false, MAX_PLAYERS_ON_BOARD)
	end)

	if success and pages then
		local data = pages:GetCurrentPage()

		for _, child in listFrame:GetChildren() do
			if child:IsA("Frame") then 
				child:Destroy() 
			end
		end

		for rank, playerInfo in data do
			create_row(listFrame, rank, playerInfo.key, playerInfo.value, isTime)
		end

		listFrame.CanvasSize = UDim2.new(0, 0, 0, #data * 45)
	else
		warn("Falha ao atualizar Leaderboard UI para Datastore.")
	end
end

local function save_player_data(player: Player): ()
	local coins = DataUtility.server.get(player, "Coins")
	local timePlayed = DataUtility.server.get(player, "TimePlayed")
	local hatched = DataUtility.server.get(player, "Stats.TotalHatched") 

	if coins then
		pcall(function() coinsODS:SetAsync(player.UserId, math.floor(coins)) end)
	end
	if hatched then
		pcall(function() hatchedODS:SetAsync(player.UserId, math.floor(hatched)) end)
	end
	if timePlayed then
		pcall(function() timePlayedODS:SetAsync(player.UserId, math.floor(timePlayed)) end)
	end
end

local function save_all_and_update_boards(): ()
	for _, player in Players:GetPlayers() do
		save_player_data(player)
	end

	update_board_ui(coinList, coinsODS)
	update_board_ui(hatchedList, hatchedODS)
	update_board_ui(timeList, timePlayedODS, true)
end

------------------//MAIN FUNCTIONS
local function start_leaderboards(): ()
	coinList = create_ui(coinLeaderboard, "🏆 Top Coins")
	hatchedList = create_ui(hatchedLeaderboard, "🥚 Top Hatched")
	timeList = create_ui(timeLeaderboard, "⏱️ Top Time")

	task.spawn(function()
		while true do
			save_all_and_update_boards()
			task.wait(UPDATE_INTERVAL)
		end
	end)
end

------------------//EVENTS
Players.PlayerRemoving:Connect(function(player)
	save_player_data(player)
end)

------------------//INIT
start_leaderboards()

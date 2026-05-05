--!strict
------------------//SERVICES
local TweenService: TweenService = game:GetService("TweenService")

------------------//CONSTANTS
local FLIP_DURATION: number = 0.18
local SQUISH_AMOUNT: number = 0.88
local TWEEN_IN: TweenInfo = TweenInfo.new(FLIP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local TWEEN_OUT: TweenInfo = TweenInfo.new(FLIP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_TEXT: TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

------------------//VARIABLES
type TextData = {
	obj: GuiObject,
	origTrans: number,
	origStroke: number
}

type CardFlip = {
	front: GuiObject,
	back: GuiObject,
	hitbox: TextButton,
	origBgTrans: number,
	origImgTrans: number,
	textElements: { TextData },
	isFlipped: boolean,
	targetFlipped: boolean,
	isAnimating: boolean,
}

local FlipCard = {}
local _cards: { CardFlip } = {}

------------------//FUNCTIONS
local function find_child(root: Instance, name: string): GuiObject?
	local obj = root:FindFirstChild(name, true)
	if obj and obj:IsA("GuiObject") then return obj :: GuiObject end
	return nil
end

local function process_flip(card: CardFlip): ()
	if card.isAnimating then return end
	card.isAnimating = true

	while card.isFlipped ~= card.targetFlipped do
		local wantBack = card.targetFlipped

		-- Esconde os textos imediatamente antes da carta virar para evitar o glitch do TextScaled
		if wantBack then
			for _, data in card.textElements do
				data.obj.TextTransparency = 1
				if data.obj:IsA("TextLabel") or data.obj:IsA("TextButton") or data.obj:IsA("TextBox") then
					data.obj.TextStrokeTransparency = 1
				end
			end
		end

		-- Passo 1: Encolher a carta dentro do Hitbox
		local shrinkGoal = { Size = UDim2.fromScale(0, SQUISH_AMOUNT) }
		local tIn = TweenService:Create(card.front, TWEEN_IN, shrinkGoal)
		tIn:Play()
		tIn.Completed:Wait()

		-- Passo 2: Trocar de face no "ponto cego"
		if wantBack then
			if card.front:IsA("ImageButton") or card.front:IsA("ImageLabel") then
				(card.front :: any).ImageTransparency = 1
			end
			card.front.BackgroundTransparency = 1

			-- DESATIVA O CLIQUE DA CAPA INVISÍVEL
			if card.front:IsA("GuiObject") then
				card.front.Active = false 
			end

			card.back.Visible = true
		else
			if card.front:IsA("ImageButton") or card.front:IsA("ImageLabel") then
				(card.front :: any).ImageTransparency = card.origImgTrans
			end
			card.front.BackgroundTransparency = card.origBgTrans

			-- REATIVA O CLIQUE DA CAPA
			if card.front:IsA("GuiObject") then
				card.front.Active = true 
			end

			card.back.Visible = false
		end

		card.isFlipped = wantBack

		if card.targetFlipped ~= wantBack then
			continue
		end

		-- Passo 3: Expandir de volta ao tamanho normal (Scale 1 = 100% do Hitbox)
		local expandGoal = { Size = UDim2.fromScale(1, 1) }
		local tOut = TweenService:Create(card.front, TWEEN_OUT, expandGoal)
		tOut:Play()
		tOut.Completed:Wait()

		-- Passo 4: Revelar o texto suavemente (Tween de Transparência)
		if card.isFlipped then
			for _, data in card.textElements do
				TweenService:Create(data.obj, TWEEN_TEXT, {
					TextTransparency = data.origTrans,
					TextStrokeTransparency = data.origStroke
				}):Play()
			end
		end
	end

	card.isAnimating = false
end

local function request_flip(card: CardFlip, wantBack: boolean): ()
	card.targetFlipped = wantBack
	if not card.isAnimating then
		task.spawn(process_flip, card)
	end
end

function FlipCard.setup(frontName: string, backName: string, root: Instance): ()
	local front = find_child(root, frontName)
	local back = find_child(root, backName)

	if not front or not back then
		warn(string.format("[FlipCard] Não encontrou '%s' ou '%s' em '%s'", frontName, backName, root.Name))
		return
	end

	-- 1. Cria o Hitbox estático para evitar instabilidade com o mouse
	local hitbox = Instance.new("Frame") -- Alterado de TextButton para Frame
	hitbox.Name = front.Name .. "_Hitbox"
	hitbox.Size = front.Size
	hitbox.Position = front.Position
	hitbox.AnchorPoint = front.AnchorPoint
	hitbox.BackgroundTransparency = 1
	hitbox.Active = false 
	hitbox.LayoutOrder = front.LayoutOrder
	hitbox.ZIndex = front.ZIndex
	hitbox.Parent = front.Parent

	-- Salva as transparências originais da capa
	local origBgTrans = front.BackgroundTransparency
	local origImgTrans = 0
	if front:IsA("ImageButton") or front:IsA("ImageLabel") then
		origImgTrans = (front :: any).ImageTransparency
	end

	-- 2. Coloca o front (capa) DENTRO do Hitbox e o ajusta para escala relativa
	front.Position = UDim2.fromScale(0.5, 0.5)
	front.AnchorPoint = Vector2.new(0.5, 0.5)
	front.Size = UDim2.fromScale(1, 1)
	front.Parent = hitbox

	back.Size = UDim2.fromScale(1, 1)

	-- 3. Mapeia e salva todos os textos do verso para o Fade In
	local textElements: { TextData } = {}
	for _, child in back:GetDescendants() do
		if child.Name == "Fill_Bg" then continue end -- Ignorado conforme a estrutura

		if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
			table.insert(textElements, {
				obj = child,
				origTrans = child.TextTransparency,
				origStroke = child.TextStrokeTransparency
			})
		end
	end

	local card: CardFlip = {
		front = front,
		back = back,
		hitbox = hitbox,
		origBgTrans = origBgTrans,
		origImgTrans = origImgTrans,
		textElements = textElements,
		isFlipped = false,
		targetFlipped = false,
		isAnimating = false,
	}

	-- Estado Inicial Limpo
	if front:IsA("ImageButton") or front:IsA("ImageLabel") then
		(front :: any).ImageTransparency = origImgTrans
	end
	front.BackgroundTransparency = origBgTrans
	back.Visible = false

	table.insert(_cards, card)

	-- Conecta o hover no Hitbox, que nunca muda de tamanho!
	hitbox.MouseEnter:Connect(function() request_flip(card, true) end)
	hitbox.MouseLeave:Connect(function() request_flip(card, false) end)
end

------------------//INIT
return FlipCard
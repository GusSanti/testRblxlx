------------------//SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

------------------//MODULES
local DataUtility = require(ReplicatedStorage.Modules.Utility.DataUtility)
local RebirthShopData = require(ReplicatedStorage.Modules.Datas.RebirthShopData)

------------------//VARIABLES
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainUI = playerGui:WaitForChild("UI")
local shopFrame = mainUI:WaitForChild("RebirthShop")

local tooltip
local textLabel
local hoveredItem = nil
local slots = {}

------------------//SETUP REMOTES
local remotesFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes")
local shopEvent = remotesFolder:WaitForChild("RebirthShopEvent")

------------------//FUNCTIONS
local function setup_tooltip()
	tooltip = Instance.new("Frame")
	tooltip.Size = UDim2.new(0, 220, 0, 70)
	tooltip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	tooltip.Visible = false
	tooltip.ZIndex = 100
	tooltip.Parent = mainUI

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = tooltip

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(0, 170, 255)
	uiStroke.Thickness = 2
	uiStroke.Parent = tooltip

	textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -16, 1, -16)
	textLabel.Position = UDim2.new(0, 8, 0, 8)
	textLabel.BackgroundTransparency = 1
	textLabel.FontFace = Font.fromId(12187365364)
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 170, 255)
	textLabel.Parent = tooltip
end

local function setup_slots()
	for i = 1, 4 do
		table.insert(slots, shopFrame.ShopBG.ListScrollingFrame.Grad1FR["Slot"..i])
	end
	for i = 1, 4 do
		table.insert(slots, shopFrame.ShopBG.ListScrollingFrame.Grad2FR["Slot"..i])
	end

	for i, itemData in ipairs(RebirthShopData.Items) do
		local slot = slots[i]
		if slot then
			slot.PurchaseBT.MouseEnter:Connect(function()
				hoveredItem = itemData
				textLabel.Text = itemData.Desc
				tooltip.Visible = true
			end)

			slot.PurchaseBT.MouseLeave:Connect(function()
				if hoveredItem == itemData then
					hoveredItem = nil
					tooltip.Visible = false
				end
			end)

			slot.PurchaseBT.MouseButton1Click:Connect(function()
				local owned = DataUtility.client.get("OwnedRebirthUpgrades") or {}
				if not table.find(owned, itemData.Id) then
					warn("purchase")
					shopEvent:FireServer("Purchase", itemData.Id)
				end
			end)
		end
	end
end

local function update_ui()
	local owned = DataUtility.client.get("OwnedRebirthUpgrades") or {}

	for i, itemData in ipairs(RebirthShopData.Items) do
		local slot = slots[i]
		if slot then
			slot.ItemNameTX.Text = itemData.Name
			local btnLabel = slot.PurchaseBT:FindFirstChildWhichIsA("TextLabel")
			
			slot.Icon.Image = itemData.IconId
			if btnLabel then
				if table.find(owned, itemData.Id) then
					btnLabel.Text = "OWNED"
				else
					btnLabel.Text = "PURCHASE (" .. itemData.Price .. " RP)"
				end
			end
		end
	end
end

local function update_tooltip_position()
	if tooltip.Visible then
		local mousePos = UserInputService:GetMouseLocation()
		tooltip.Position = UDim2.new(0, mousePos.X + 20, 0, mousePos.Y - 20)
	end
end

------------------//INIT
setup_tooltip()
setup_slots()
update_ui()

RunService.RenderStepped:Connect(update_tooltip_position)

DataUtility.client.bind("OwnedRebirthUpgrades", update_ui)
DataUtility.client.bind("RP", update_ui)
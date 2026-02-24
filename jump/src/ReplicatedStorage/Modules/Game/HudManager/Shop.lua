------------------//SERVICES
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//VARIABLES
local ShopController = {}
local localPlayer = Players.LocalPlayer

local ProductsData = require(
	ReplicatedStorage:WaitForChild("Modules")
		:WaitForChild("Datas")
		:WaitForChild("ProductsData")
)

local NotificationUtility = require(
	ReplicatedStorage:WaitForChild("Modules")
		:WaitForChild("Utility")
		:WaitForChild("NotificationUtility")
)

local pendingPurchases = {}

------------------//FUNCTIONS
local function get_shop_ui()
	local playerGui = localPlayer:WaitForChild("PlayerGui", 10)
	if not playerGui then return nil end

	local UI = playerGui:WaitForChild("UI", 10)
	if not UI then return nil end

	local shopFrame = UI:FindFirstChild("Shop", true)
	if not shopFrame then return nil end

	return shopFrame
end

local function prompt_purchase(productId: number, productType: string, productName: string)
	pendingPurchases[productId] = {
		productType = productType,
		productName = productName,
		timestamp = tick()
	}

	if productType == "DeveloperProduct" then
		MarketplaceService:PromptProductPurchase(localPlayer, productId)
	elseif productType == "Gamepass" then
		MarketplaceService:PromptGamePassPurchase(localPlayer, productId)
	else
		pendingPurchases[productId] = nil
	end
end

local function on_product_purchase_finished(player: Player, productId: number, wasPurchased: boolean)
	if player ~= localPlayer then return end

	local purchaseData = pendingPurchases[productId]
	if not purchaseData then return end

	if wasPurchased then
		NotificationUtility:Show({
			message = "🎉 " .. purchaseData.productName .. " purchased successfully!",
			type = "success",
			duration = 4,
			sound = true
		})
	end

	pendingPurchases[productId] = nil
end

local function on_gamepass_purchase_finished(player: Player, gamepassId: number, wasPurchased: boolean)
	if player ~= localPlayer then return end

	local purchaseData = pendingPurchases[gamepassId]
	if not purchaseData then return end

	if wasPurchased then
		NotificationUtility:Show({
			message = "🎉 " .. purchaseData.productName .. " purchased successfully!",
			type = "success",
			duration = 4,
			sound = true
		})
	end

	pendingPurchases[gamepassId] = nil
end

local function setup_purchase_button(button: GuiButton)
	local productKey = button:GetAttribute("ProductKey")
	local productType = button:GetAttribute("ProductType")
	if not productKey or not productType then return end

	local productData
	local productId

	if productType == "DeveloperProduct" then
		productData = ProductsData.DeveloperProducts[productKey]
		if productData then
			productId = productData.ProductId
		end
	elseif productType == "Gamepass" then
		productData = ProductsData.Gamepasses[productKey]
		if productData then
			productId = productData.GamepassId
		end
	end

	if not productData or not productId then return end

	local itemNameText = button.Parent:FindFirstChild("ItemNameTX", true)
	if itemNameText and itemNameText:IsA("TextLabel") then
		itemNameText.Text = productData.Name or productKey
	end

	button.Activated:Connect(function()
		prompt_purchase(productId, productType, productData.Name or productKey)
	end)
end

local function find_all_purchase_buttons(parent: Instance)
	local buttons = {}

	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("GuiButton") and descendant.Name == "PurchaseBT" then
			table.insert(buttons, descendant)
		end
	end

	return buttons
end

local function setup_pogos_button(shopFrame: Frame)
	local categoryFR = shopFrame:FindFirstChild("CategoryFR")
	if not categoryFR then return end

	local categoryBG = categoryFR:FindFirstChild("CategoryBG")
	if not categoryBG then return end

	local btPogos = categoryBG:FindFirstChild("BTPogos")
	if not btPogos then return end

	local InventoryEvent = ReplicatedStorage:FindFirstChild("InventoryEvent")
	if not InventoryEvent then
		InventoryEvent = Instance.new("BindableEvent")
		InventoryEvent.Name = "InventoryEvent"
		InventoryEvent.Parent = ReplicatedStorage
	end

	btPogos.Activated:Connect(function()
		shopFrame.Visible = false

		local UI = shopFrame.Parent
		local inventoryFrame = UI:FindFirstChild("Inventory", true)
		if inventoryFrame then
			inventoryFrame.Visible = true
			InventoryEvent:Fire("Pogos")
		end
	end)
end

local function initialize_shop()
	local shopFrame = get_shop_ui()
	if not shopFrame then return end

	local purchaseButtons = find_all_purchase_buttons(shopFrame)
	if #purchaseButtons == 0 then return end

	for _, button in ipairs(purchaseButtons) do
		setup_purchase_button(button)
	end

	setup_pogos_button(shopFrame)
end

------------------//INIT
MarketplaceService.PromptProductPurchaseFinished:Connect(on_product_purchase_finished)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(on_gamepass_purchase_finished)

task.spawn(function()
	initialize_shop()
end)

return ShopController

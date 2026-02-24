------------------//SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//MODULES
local DataUtility = require(ReplicatedStorage.Modules.Utility.DataUtility)
local RebirthShopData = require(ReplicatedStorage.Modules.Datas.RebirthShopData)

------------------//SETUP REMOTES
local remotesFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes")
local shopEvent = remotesFolder:FindFirstChild("RebirthShopEvent") or Instance.new("RemoteEvent", remotesFolder)
shopEvent.Name = "RebirthShopEvent"

------------------//FUNCTIONS
local function handle_purchase(player: Player, itemId: string)
	local itemData
	for _, item in ipairs(RebirthShopData.Items) do
		if item.Id == itemId then 
			itemData = item 
			break 
		end
	end

	if not itemData then return end

	local rp = DataUtility.server.get(player, "RebirthTokens") or 0
	local owned = DataUtility.server.get(player, "OwnedRebirthUpgrades") or {}

	if not table.find(owned, itemId) and rp >= itemData.Price then
		DataUtility.server.set(player, "RP", rp - itemData.Price)
		table.insert(owned, itemId)
		DataUtility.server.set(player, "OwnedRebirthUpgrades", owned)
	end
end

------------------//INIT
DataUtility.server.ensure_remotes()

shopEvent.OnServerEvent:Connect(function(player, action, itemId)
	if action == "Purchase" then
		handle_purchase(player, itemId)
	end
end)
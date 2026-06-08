local ReplicatedStorage = game:GetService("ReplicatedStorage")
local items = ReplicatedStorage.Assets:WaitForChild("CharacterItems")
local CharacterCreatorEvent = ReplicatedStorage.Remotes:WaitForChild("CharacterCreatorEvent")

local screenGui = script.Parent
local frame = script.Parent:WaitForChild("CreatorFrame")
local button = script.Parent:FindFirstChild("OpenGuiTextButton")
local openFromNpcEvent = screenGui:FindFirstChild("OpenFromNpc")
if not openFromNpcEvent or not openFromNpcEvent:IsA("BindableEvent") then
	openFromNpcEvent = Instance.new("BindableEvent")
	openFromNpcEvent.Name = "OpenFromNpc"
	openFromNpcEvent.Parent = screenGui
end

frame.Visible = false
if button and button:IsA("GuiObject") then
	button.Visible = false
end

local currentItems = {}

local function open_character_creator()
	currentItems = {}
	for i, currentItem in pairs(game.Players.LocalPlayer:WaitForChild("CurrentItems"):GetChildren()) do
		table.insert(currentItems, currentItem.Name)
	end

	for x, child in pairs(frame.CharacterViewportFrame:GetChildren()) do
		if child:IsA("Camera") or child:IsA("Model") then child:Destroy() end
	end

	local character = game.Players.LocalPlayer.Character
	if not character then
		return
	end

	character.Archivable = true
	local characterModel = character:Clone()
	characterModel.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	characterModel.Name = "Character"

	local camera = Instance.new("Camera")
	camera.Parent = frame.CharacterViewportFrame
	frame.CharacterViewportFrame.CurrentCamera = camera

	camera.CFrame = CFrame.new(characterModel.PrimaryPart.Position + characterModel.PrimaryPart.CFrame.LookVector * 5, characterModel.PrimaryPart.Position)

	characterModel.Parent = frame.CharacterViewportFrame

	frame.Visible = true

	local blur = game.Lighting:FindFirstChild("CharacterCreatorBlur")
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Name = "CharacterCreatorBlur"
		blur.Parent = game.Lighting
	end
end

--Open and close GUI
if button and button:IsA("GuiButton") then
	button.MouseButton1Click:Connect(function()
		open_character_creator()
	end)
end

openFromNpcEvent.Event:Connect(function()
	open_character_creator()
end)

frame.ConfirmTextButton.MouseButton1Click:Connect(function()

	CharacterCreatorEvent:FireServer(currentItems)

	frame.Visible = false

	if game.Lighting:FindFirstChild("CharacterCreatorBlur") then
		game.Lighting.CharacterCreatorBlur:Destroy()
	end
end)


--Setup character creator GUI
local function setupGui()

	for i, child in pairs(frame.CategoriesScrollingFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	for x, category in pairs(items:GetChildren()) do

		local categoryName = category.Name

		local newCategoryButton = script.ItemCategoryButton:Clone()
		newCategoryButton.Text = categoryName

		newCategoryButton.MouseButton1Click:Connect(function()

			for y, child in pairs(frame.ItemsScrollingFrame:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end

			local debounce = false

			for z, item in pairs(category:GetChildren()) do
				local itemType = item:FindFirstChildOfClass("Shirt") or item:FindFirstChildOfClass("Pants") or item
				local itemName = itemType.Name

				if itemName ~= "Police Top" and itemName ~= "Police Bottom" and itemName ~= "bon bon" and itemName ~= "sigma" then
					local newItemButton = script.ItemButton:Clone()
					newItemButton.Name = itemName
					newItemButton.ItemName.Text = itemName
					newItemButton.UIStroke.Enabled = false
					if table.find(currentItems, itemType.Name) then newItemButton.UIStroke.Enabled = true end

					local camera = Instance.new("Camera")
					camera.Parent = newItemButton.ItemViewportFrame
					newItemButton.ItemViewportFrame.CurrentCamera = camera

					local itemModel = item:Clone()
					local itemMainPart = itemModel:FindFirstChild("Handle") or itemModel.PrimaryPart

					if itemModel:FindFirstChild("Humanoid") then
						itemModel.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					end

					local distance = 6				
					if itemMainPart.Name == "Handle" then distance = 2 end
					camera.CFrame = CFrame.new(itemMainPart.Position + itemMainPart.CFrame.LookVector * distance, itemMainPart.Position)

					newItemButton.MouseButton1Click:Connect(function()

						if frame.CharacterViewportFrame:FindFirstChild("Character") and not debounce then
							debounce = true
							local character = frame.CharacterViewportFrame.Character

							if not table.find(currentItems, itemType.Name) then
								table.insert(currentItems, itemType.Name)

								newItemButton.UIStroke.Enabled = true

								local itemToApply = itemType:Clone()

								if itemType:IsA("Shirt") then

									if character:FindFirstChildOfClass("Shirt") then
										for i, existingItem in pairs(currentItems) do
											if items:FindFirstChild(existingItem, true) and items:FindFirstChild(existingItem, true):IsA("Shirt") then
												table.remove(currentItems, i)
											end
										end
										if frame.ItemsScrollingFrame:FindFirstChild(character:FindFirstChildOfClass("Shirt").Name) then
											frame.ItemsScrollingFrame:FindFirstChild(character:FindFirstChildOfClass("Shirt").Name).UIStroke.Enabled = false
										end
										for i, child in pairs(character:GetChildren()) do
											if child:IsA("Shirt") then child:Destroy() end
										end
									end
									itemToApply.Parent = character

								elseif itemType:IsA("Pants") then

									if character:FindFirstChildOfClass("Pants") then
										for i, existingItem in pairs(currentItems) do
											if items:FindFirstChild(existingItem, true) and items:FindFirstChild(existingItem, true):IsA("Pants") then
												table.remove(currentItems, i)
											end
										end
										if frame.ItemsScrollingFrame:FindFirstChild(character:FindFirstChildOfClass("Pants").Name) then
											frame.ItemsScrollingFrame:FindFirstChild(character:FindFirstChildOfClass("Pants").Name).UIStroke.Enabled = false
										end
										for i, child in pairs(character:GetChildren()) do
											if child:IsA("Pants") then child:Destroy() end
										end
									end
									itemToApply.Parent = character

								elseif itemType:IsA("Accessory") then

									local c = frame.CharacterViewportFrame.Character
									c.Parent = workspace

									itemToApply.Parent = c

									local a1 = itemToApply.Handle:FindFirstChildOfClass("Attachment")

									if a1 then
										-- Procura o Attachment correspondente em qualquer parte do personagem
										local attachmentName = a1.Name
										local targetAttachment = nil

										for _, part in pairs(c:GetDescendants()) do
											if part:IsA("Attachment") and part.Name == attachmentName and part.Parent ~= itemToApply.Handle then
												targetAttachment = part
												break
											end
										end

										if targetAttachment then
											local weld = Instance.new("Weld")
											weld.Part0 = targetAttachment.Parent
											weld.Part1 = itemToApply.Handle
											weld.C0 = targetAttachment.CFrame
											weld.C1 = a1.CFrame
											weld.Parent = targetAttachment.Parent
										end
									end

									c.Parent = frame.CharacterViewportFrame
								end

							else
								-- CORRIGIDO: remoção segura por classe/nome
								table.remove(currentItems, table.find(currentItems, itemType.Name))
								newItemButton.UIStroke.Enabled = false

								if itemType:IsA("Shirt") then
									for _, child in pairs(character:GetChildren()) do
										if child:IsA("Shirt") then child:Destroy() break end
									end
								elseif itemType:IsA("Pants") then
									for _, child in pairs(character:GetChildren()) do
										if child:IsA("Pants") then child:Destroy() break end
									end
								elseif itemType:IsA("Accessory") then
									local found = character:FindFirstChild(item.Name)
									if found then found:Destroy() end
								else
									local found = character:FindFirstChild(itemName)
									if found then found:Destroy() end
								end
							end
						end
						wait(1)
						debounce = false
					end)

					itemModel.Parent = newItemButton.ItemViewportFrame

					newItemButton.Parent = frame.ItemsScrollingFrame
					newItemButton.Size = UDim2.new(0, newItemButton.AbsoluteSize.X, 0, newItemButton.AbsoluteSize.Y)
					frame.ItemsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, frame.ItemsScrollingFrame.UIGridLayout.AbsoluteContentSize.Y)
				end
			end
		end)

		newCategoryButton.Parent = frame.CategoriesScrollingFrame
		newCategoryButton.Size = UDim2.new(0, newCategoryButton.AbsoluteSize.X, 0, newCategoryButton.AbsoluteSize.Y)
		frame.CategoriesScrollingFrame.CanvasSize = UDim2.new(0, frame.CategoriesScrollingFrame.UIListLayout.AbsoluteContentSize.X, 0, 0)
	end
end

setupGui()
items.DescendantAdded:Connect(setupGui)

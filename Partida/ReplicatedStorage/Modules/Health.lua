local Players = game:GetService("Players")

local health = {}

local function destroyGui(gui)
	if gui and gui.Parent then
		gui:Destroy()
	end
end

local function getHumanoid(model)
	if not model or not model.Parent then
		return nil
	end

	return model:FindFirstChildOfClass("Humanoid")
end

function health.Setup(model, screenGui)
	local healthGuiTemplate = script:FindFirstChild("HealthGui")
	if not healthGuiTemplate then
		return
	end

	local newHealthBar = healthGuiTemplate:Clone()
	local HRP = model and model:FindFirstChild("HumanoidRootPart")

	if not model or not HRP or not model.Parent then
		destroyGui(newHealthBar)
		return
	end

	local humanoid = getHumanoid(model)
	if not humanoid then
		destroyGui(newHealthBar)
		return
	end

	newHealthBar:GetPropertyChangedSignal('Adornee'):Connect(function()
		if not newHealthBar.Adornee then
			destroyGui(newHealthBar)
		end
	end)

	newHealthBar.Adornee = HRP

	newHealthBar.Parent = Players.LocalPlayer.PlayerGui:WaitForChild("Billboards")

	local function syncHiddenState()
		if not newHealthBar.Parent then
			return
		end

		newHealthBar.Enabled = not model:GetAttribute("MobHidden")
	end

	if workspace:WaitForChild('Info').World.Value == 5 then -- tatooine
		newHealthBar.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	end

	if model.Name == "Base" then
		newHealthBar.MaxDistance = 100
		newHealthBar.Size = UDim2.new(0, 200, 0, 20)

	else
		newHealthBar.MaxDistance = 30
		newHealthBar.Main.MobName.Text = model.Name
	end


	health.UpdateBarHealth(newHealthBar, model)
	if screenGui then
		health.UpdateScreenGuiHealth(screenGui, model)
	end

	local function updateHealthDisplays()
		if not newHealthBar.Parent or not model.Parent then
			return
		end

		health.UpdateBarHealth(newHealthBar, model)
		if screenGui then
			health.UpdateScreenGuiHealth(screenGui, model)
		end
	end

	humanoid.HealthChanged:Connect(function()
		updateHealthDisplays()
	end)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealthDisplays)
	model:GetAttributeChangedSignal("MobHidden"):Connect(syncHiddenState)
	model.Destroying:Connect(function()
		destroyGui(newHealthBar)
	end)

	syncHiddenState()
end

-- FUNCTIONS
function health.UpdateScreenGuiHealth(gui,model)
	if not gui then
		return
	end

	if model == nil or model.Parent == nil then
		destroyGui(gui)
		return
	end

	local humanoid = getHumanoid(model)
	if not humanoid then
		destroyGui(gui)
		return
	end

	local currentHealth = gui:FindFirstChild("CurrentHealth")
	local hpText = gui:FindFirstChild("HpText")
	if not currentHealth or not hpText then
		destroyGui(gui)
		return
	end

	if humanoid and gui then
		local percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)

		if currentHealth.Size.Y.Scale == 0.5 then
			currentHealth.Size = UDim2.new(percent, 0, .5, 0)
		else
			currentHealth.Size = UDim2.new(percent, 0, 1, 0)
		end

		if humanoid.Health <= 0 then
			if model.Name == "Base" then
				hpText.Text = model.Name .. " DESTROYED".. humanoid.MaxHealth .. ", GG"
				workspace.Mobs:ClearAllChildren()

			else
				game.Debris:AddItem(gui,0.5)
			end

		else
			hpText.Text = humanoid.Health .. "/" .. humanoid.MaxHealth
		end
	end

end

function health.UpdateBarHealth(gui, model)
	if not gui then
		return
	end

	if model == nil or model.Parent == nil then
		destroyGui(gui)
		return
	end

	local humanoid = getHumanoid(model)
	if not humanoid then
		destroyGui(gui)
		return
	end

	local main = gui:FindFirstChild("Main")
	local barFrame = main and main:FindFirstChild("BarFrame")
	local bar = barFrame and barFrame:FindFirstChild("Bar")
	local healthLabel = main and main:FindFirstChild("Health")
	if not main or not bar or not healthLabel then
		destroyGui(gui)
		return
	end

	if humanoid and gui then
		local percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)

		bar.Size = UDim2.fromScale(percent,1)

		if humanoid.Health <= 0 then
			if model.Name == "Base" then
				healthLabel.Text = model.Name .. " DESTROYED".. humanoid.MaxHealth .. ", GG"

				if workspace:FindFirstChild('Mobs') then
					workspace.Mobs:ClearAllChildren()
				else
					workspace.RedMobs:ClearAllChildren()
					workspace.BlueMobs:ClearAllChildren()
				end
			else
				healthLabel.Text = humanoid.Health .. "/" .. humanoid.MaxHealth
				game.Debris:AddItem(gui,0.5)
			end

		else
			healthLabel.Text = humanoid.Health .. "/" .. humanoid.MaxHealth
		end
	end
end

return health

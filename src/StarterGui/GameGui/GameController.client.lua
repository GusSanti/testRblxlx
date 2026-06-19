-- SERVICES
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
-- CONSTANTS
local Shortner = require(ReplicatedStorage.Modules.NumberFormat)
local itemModule = require(ReplicatedStorage.ItemStats)
local ChallengeModule = require(ReplicatedStorage.Modules.ChallengeModule)
local UIMapLoadingScreenModule = require(ReplicatedStorage.Modules.Client.UIMapLoadingScreen)
local ViewModule = require(ReplicatedStorage.Modules.ViewModule)
local UIHandler = require(ReplicatedStorage.Modules.Client.UIHandler)
local modules = ReplicatedStorage:WaitForChild("Modules")
local health = require(modules:WaitForChild("Health"))
local ViewPortModule = require(ReplicatedStorage.Modules.ViewPortModule)
local TowerInfo = require(ReplicatedStorage.Modules.Helpers.TowerInfo)
local GameBalance = require(ReplicatedStorage.Modules.GameBalance)
local Format = require(game.ReplicatedStorage.Modules.MathFormat)
local GetUnitModel = require(ReplicatedStorage.Modules.GetUnitModel)
local Traits = require(ReplicatedStorage.Traits)
local VFX_Loader = require(ReplicatedStorage.VFX_Loader)
local ExpModule = require(ReplicatedStorage.Modules.ExpModule)
local StoryModeStats = require(ReplicatedStorage.StoryModeStats)
local RaidModeStats = require(ReplicatedStorage.RaidModeStats)
local upgradesModule = require(ReplicatedStorage.Upgrades)
local TweenModule = require(ReplicatedStorage.AceLib.TweenModule)
local RankCalculator = require(ReplicatedStorage.CompetitiveData.RankCalculator)
local RomanNumeralsConverter = require(ReplicatedStorage.AceLib.RomanNumeralsConverter)
local EmitModule = require(ReplicatedStorage.Modules:WaitForChild("EmitModule"))
local functions = ReplicatedStorage:WaitForChild("Functions")
local requestTowerFunction = functions:WaitForChild("RequestTower")
local spawnTowerFunction = functions:WaitForChild("SpawnTower")
local UpgradeFunction = functions:WaitForChild("Upgrade")
local sellTowerFunction = functions:WaitForChild("SellTower")
local changeModeFunction = functions:WaitForChild("ChangeTowerMode")
local requestAbilityFunction = functions:WaitForChild("RequestAbility")
local events = ReplicatedStorage:WaitForChild("Events")
local ActivateAbility = ReplicatedStorage.Remotes.DestroyerRemotes.CallDestroyer
local AbilityStatus = ReplicatedStorage.States.AbilityStatus
local UnitGradients = ReplicatedStorage.Borders
local Click = SoundService.SoundFX.Click
local requiredSlotLevel = {0, 0, 0, 10, 20, 30}
local RARITY_STARS = {
	Rare = 2,
	Epic = 3,
	Legendary = 4,
	Mythical = 5,
	Supreme = 6,
	Exclusive = 6,
	Secret = 6,
	Unique = 5
}
local VALID_PLACEMENT_COLOR = Color3.fromRGB(90, 255, 125)
local VALID_PLACEMENT_OUTLINE = Color3.fromRGB(216, 255, 156)
local INVALID_PLACEMENT_COLOR = Color3.fromRGB(255, 74, 74)
local INVALID_PLACEMENT_OUTLINE = Color3.fromRGB(255, 186, 186)
local PlacementDebug = {
	enabled = true,
	moveInterval = 0.35,
	minSurfaceNormalY = 0.65,
	lastSignature = nil,
	lastAt = 0,
}
local SelectedTowers = {}
local slotButtonConnections = {}
local ownedTowerConnections = {}
-- VARIABLES
local player = Players.LocalPlayer
local playerMoney = Players.LocalPlayer:WaitForChild("Money")
local playerguix = player.PlayerGui
local NewUI = playerguix:WaitForChild("NewUI")
local IngameHud = NewUI:WaitForChild("IngameHud")
local FailedScreen = NewUI:WaitForChild("Failed")
local VictoryScreen = NewUI:WaitForChild("Victory")
local SpeedButton = IngameHud.Top.Speed
local mouse = game.Players.LocalPlayer:GetMouse()
local camera = workspace.CurrentCamera
local gui = script.Parent
local GlobalGUI = gui.Parent:WaitForChild("GlobalGUI")
local info = workspace:WaitForChild("Info")
local Upgrade = NewUI:WaitForChild("Scout")
local SkipUI = NewUI:WaitForChild("Skip")
local StopButton = nil
local SKIP_CENTER_POSITION = UDim2.fromScale(0.5, 0.5)
local SKIP_HIDDEN_POSITION = UDim2.fromScale(0.5, -0.5)
local selectedTower = nil
local towerToSpawn = nil
local towerToSpawnValue = nil
local IsOwner = nil
local canPlace = false
local rotation = 0
local placedTowers = 0
local spawnCooldown = 0.5
local lastSpawnTime = 0
local lastHighlight = nil
local lastValidResult = nil
local hoveredInstance = nil
local abilityConn = nil :: RBXScriptConnection
local abilityTick = nil
local abilityActivateConn = nil :: RBXScriptConnection
local LevelBar = IngameHud.Bottom.LevelBar.Fill
local LevelNumber = IngameHud.Bottom.LevelBar.Text
local LevelBarOriginalSize = LevelBar.Size
local activeEndScreen = nil
local endScreenConnections = {}
local endScreenDisplayToken = 0
local waveTimerToken = 0
local spectatingTower = nil
local spectateStopConnection = nil :: RBXScriptConnection?
local spectateTowerAncestryConnection = nil :: RBXScriptConnection?
local spectateVisualState = {}
local PREVIEW_DEBUG_ENABLED = true
local slotUiReady = false
local slotUiRequestedVisible = true
-- FUNCTIONS
EmitModule.init()
SkipUI.AnchorPoint = Vector2.new(0.5, 0.5)
SkipUI.Position = SKIP_CENTER_POSITION

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
end)

function previewDebug(...)
	if not PREVIEW_DEBUG_ENABLED then
		return
	end

	print("[PreviewDebug]", ...)
end

function PlacementDebug.log(...)
	if not PlacementDebug.enabled then
		return
	end

	print("[PlacementDebug][Client]", ...)
end

function PlacementDebug.formatVector3(value)
	if typeof(value) ~= "Vector3" then
		return tostring(value)
	end

	return string.format("(%.2f, %.2f, %.2f)", value.X, value.Y, value.Z)
end

function PlacementDebug.formatCFrame(value)
	if typeof(value) ~= "CFrame" then
		return tostring(value)
	end

	return "pos=" .. PlacementDebug.formatVector3(value.Position)
end

function PlacementDebug.getInstancePath(instance)
	if typeof(instance) ~= "Instance" then
		return tostring(instance)
	end

	return instance:GetFullName()
end

function PlacementDebug.isBlockedSurfaceName(instance)
	if typeof(instance) ~= "Instance" then
		return false
	end

	local lowerName = string.lower(instance.Name)
	return string.find(lowerName, "barrier") ~= nil
		or string.find(lowerName, "wall") ~= nil
		or string.find(lowerName, "bound") ~= nil
		or string.find(lowerName, "border") ~= nil
end

PlacementDebug.spawnClearance = 18
PlacementDebug.spawnPathClearance = 10
PlacementDebug.spawnPathLength = 28

function resolveStopButton()
	if StopButton and StopButton.Parent then
		return StopButton
	end

	local foundStopButton = NewUI:FindFirstChild("StopButton", true)
		or gui:FindFirstChild("StopButton", true)
		or playerguix:FindFirstChild("StopButton", true)

	if foundStopButton and foundStopButton:IsA("GuiObject") then
		StopButton = foundStopButton
	else
		StopButton = nil
	end

	return StopButton
end

function getCurrentCamera()
	camera = workspace.CurrentCamera or camera
	return camera
end

function applyBottomSlotVisibility()
	IngameHud.Bottom.Slot.Visible = slotUiReady and slotUiRequestedVisible and spectatingTower == nil
end

function requestBottomSlotVisibility(state)
	slotUiRequestedVisible = state
	applyBottomSlotVisibility()
end

function getOwnedTowerLoadSignature()
	local signatureParts = {}
	for _, tower in ipairs(player.OwnedTowers:GetChildren()) do
		signatureParts[#signatureParts + 1] = table.concat({
			tower.Name,
			tostring(tower:GetAttribute("Equipped")),
			tostring(tower:GetAttribute("EquippedSlot")),
			tostring(tower:GetAttribute("Level")),
			tostring(tower:GetAttribute("Trait")),
			tostring(tower:GetAttribute("Shiny"))
		}, "|")
	end

	table.sort(signatureParts)
	return table.concat(signatureParts, "||")
end

function waitForOwnedTowersToSettle(timeoutSeconds, settleSeconds)
	local deadline = os.clock() + (timeoutSeconds or 5)
	local settledFor = settleSeconds or 0.15
	local lastSignature = nil
	local stableSince = os.clock()

	while os.clock() < deadline do
		local signature = getOwnedTowerLoadSignature()
		if signature ~= lastSignature then
			lastSignature = signature
			stableSince = os.clock()
		elseif os.clock() - stableSince >= settledFor then
			return true
		end

		task.wait(0.05)
	end

	return false
end

applyBottomSlotVisibility()

function getFlatDistance(pos1, pos2)
	local delta = pos1 - pos2
	return Vector3.new(delta.X, 0, delta.Z).Magnitude
end

function getFlatDistanceToSegment(position, segmentStart, segmentEnd)
	local point = Vector3.new(position.X, 0, position.Z)
	local startPoint = Vector3.new(segmentStart.X, 0, segmentStart.Z)
	local endPoint = Vector3.new(segmentEnd.X, 0, segmentEnd.Z)
	local segment = endPoint - startPoint
	local segmentLengthSquared = segment:Dot(segment)

	if segmentLengthSquared <= 0 then
		return (point - startPoint).Magnitude, 0
	end

	local alpha = math.clamp((point - startPoint):Dot(segment) / segmentLengthSquared, 0, 1)
	local closestPoint = startPoint + (segment * alpha)
	return (point - closestPoint).Magnitude, (closestPoint - startPoint).Magnitude
end

function getSpawnMarkers(map)
	local markers = {}
	if not map then
		return markers
	end

	for _, descendant in ipairs(map:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local name = descendant.Name
			if name == "Start" or name == "RedStart" or name == "BlueStart" or name:match("^Start%d+$") then
				table.insert(markers, descendant)
			end
		end
	end

	return markers
end

function getWaypointFolderForSpawn(map, spawnMarker)
	if not map or not spawnMarker then
		return nil
	end

	local waypointRoot = spawnMarker.Parent or map

	if spawnMarker.Name == "RedStart" then
		return waypointRoot:FindFirstChild("RedWaypoints")
	end

	if spawnMarker.Name == "BlueStart" then
		return waypointRoot:FindFirstChild("BlueWaypoints")
	end

	local pathNumber = spawnMarker.Name:match("^Start(%d+)$")
	if pathNumber then
		return waypointRoot:FindFirstChild("Waypoints" .. pathNumber)
	end

	return waypointRoot:FindFirstChild("Waypoints")
end

function getFirstWaypoint(map, spawnMarker)
	local waypoints = getWaypointFolderForSpawn(map, spawnMarker)
	if not waypoints then
		return nil
	end

	local firstWaypoint = waypoints:FindFirstChild("1")
	if firstWaypoint then
		return firstWaypoint
	end

	local lowestIndex = math.huge
	for _, child in ipairs(waypoints:GetChildren()) do
		local index = tonumber(child.Name)
		if index and index < lowestIndex and child:IsA("BasePart") then
			lowestIndex = index
			firstWaypoint = child
		end
	end

	return firstWaypoint
end

function isNearEnemySpawn(position)
	local map = workspace:FindFirstChild("Map") or workspace

	for _, spawnMarker in ipairs(getSpawnMarkers(map)) do
		if getFlatDistance(spawnMarker.Position, position) < PlacementDebug.spawnClearance then
			return true
		end

		local firstWaypoint = getFirstWaypoint(map, spawnMarker)
		if firstWaypoint and firstWaypoint:IsA("BasePart") then
			local segmentDistance, distanceFromSpawn = getFlatDistanceToSegment(position, spawnMarker.Position, firstWaypoint.Position)
			if distanceFromSpawn <= PlacementDebug.spawnPathLength and segmentDistance < PlacementDebug.spawnPathClearance then
				return true
			end
		end
	end

	return false
end

function PlacementDebug.describeRaycastResult(result)
	if not result then
		return "nil"
	end

	local instance = result.Instance
	local parent = instance and instance.Parent
	return string.format(
		"hit=%s parent=%s pos=%s normal=%s material=%s canQuery=%s",
		instance and PlacementDebug.getInstancePath(instance) or "nil",
		parent and PlacementDebug.getInstancePath(parent) or "nil",
		PlacementDebug.formatVector3(result.Position),
		PlacementDebug.formatVector3(result.Normal),
		tostring(result.Material),
		tostring(instance and instance.CanQuery)
	)
end

function PlacementDebug.state(reason, result, tower, placementCFrame)
	if not PlacementDebug.enabled or not tower then
		return
	end

	local hitName = result and result.Instance and result.Instance:GetFullName() or "nil"
	local hitPosition = result and result.Position or Vector3.new()
	local towerPosition = placementCFrame and placementCFrame.Position or tower:GetPivot().Position
	local signature = table.concat({
		reason,
		tower.Name,
		tostring(canPlace),
		hitName,
		tostring(math.floor(hitPosition.X * 10 + 0.5)),
		tostring(math.floor(hitPosition.Y * 10 + 0.5)),
		tostring(math.floor(hitPosition.Z * 10 + 0.5)),
		tostring(math.floor(towerPosition.Y * 10 + 0.5)),
		tostring(rotation),
	}, "|")
	local now = tick()

	if signature == PlacementDebug.lastSignature and now - PlacementDebug.lastAt < PlacementDebug.moveInterval then
		return
	end

	PlacementDebug.lastSignature = signature
	PlacementDebug.lastAt = now
	PlacementDebug.log(reason, "tower=", tower.Name, "canPlace=", canPlace, "raycast=", PlacementDebug.describeRaycastResult(result), "cframe=", placementCFrame and PlacementDebug.formatCFrame(placementCFrame) or "nil", "rotation=", rotation)
end

function getSlotByIndex(i)
	return IngameHud.Bottom.Slot:FindFirstChild(tostring(i))
end
function getTemplateFolder()
	return IngameHud:FindFirstChild("Template")
end
function getSlotTemplateForRarity(rarity)
	local templateFolder = getTemplateFolder()
	if not templateFolder then return nil end
	local searchRarity = rarity
	if rarity == "Mythical" then
		searchRarity = "Mythic"
	end
	local template = templateFolder:FindFirstChild(searchRarity)
	if template then
		return template
	end
	local fallbacks = {
		Secret = "Mythic",
		Unique = "Mythic",
		Supreme = "Mythic",
		Exclusive = "Exclusive"
	}
	return templateFolder:FindFirstChild(fallbacks[rarity] or "Rare")
end
function getEquippedTowersBySlot()
	local equippedTowers = {}
	for _, tower in player.OwnedTowers:GetChildren() do
		if tower:GetAttribute("Equipped") ~= true then
			continue
		end
		local slotIndex = tonumber(tower:GetAttribute("EquippedSlot"))
		if typeof(slotIndex) == "number" and slotIndex >= 1 and slotIndex <= 6 and equippedTowers[slotIndex] == nil then
			equippedTowers[slotIndex] = tower
		else
			for fallbackIndex = 1, 6 do
				if equippedTowers[fallbackIndex] == nil then
					equippedTowers[fallbackIndex] = tower
					break
				end
			end
		end
	end
	return equippedTowers
end
local SLOT_TEMPLATE_NAME = "SlotGeneratedTemplate"
local SLOT_EMPTY_TEMPLATE_NAME = "SlotGeneratedClosedTemplate"

function resetSlotConnection(slot)
	local connection = slotButtonConnections[slot]
	if connection then
		connection:Disconnect()
		slotButtonConnections[slot] = nil
	end
end

function getSlotLimitText(slot)
	if not slot then return nil end
	return slot:FindFirstChild("LimitText", true)
end

function findFirstChildByNames(parent, names, recursive)
	if not parent then
		return nil
	end

	for _, name in ipairs(names) do
		local child = parent:FindFirstChild(name, recursive)
		if child then
			return child
		end
	end

	return nil
end

function getScoutLeftSection()
	return findFirstChildByNames(Upgrade, {"LeftSection", "Leftsection"})
end

function getScoutRightSection()
	return findFirstChildByNames(Upgrade, {"RightSection", "Rightsection"})
end

function getScoutButtonsSection()
	local rightSection = getScoutRightSection()
	return rightSection and rightSection:FindFirstChild("Buttons")
end

function getScoutProfileSection()
	local rightSection = getScoutRightSection()
	return rightSection and rightSection:FindFirstChild("Profile")
end

function findViewportFrame(container)
	if not container then
		return nil
	end

	local viewport = findFirstChildByNames(container, {"ViewPortFrame", "ViewportFrame"})
	if viewport and viewport:IsA("ViewportFrame") then
		return viewport
	end

	viewport = findFirstChildByNames(container, {"ViewPortFrame", "ViewportFrame"}, true)
	if viewport and viewport:IsA("ViewportFrame") then
		return viewport
	end

	return nil
end

function getEndScreenLeftInfo(screen)
	local content = screen and screen:FindFirstChild("Main") and screen.Main:FindFirstChild("Content")
	if not content then
		return nil
	end

	return findFirstChildByNames(content, {"LeftInfo", "Leftinfo"})
end

function getUnitRarity(unit)
	local rarity = nil
	for _, v in ReplicatedStorage.Towers:GetChildren() do
		if v:IsA("Folder") and v:FindFirstChild(unit) then
			rarity = v.Name
			break
		end
	end
	return rarity
end

function safeDestroyViewport(viewport)
	if not viewport then
		return
	end

	if viewport:IsA("ViewportFrame") and ViewPortModule.DestroyViewport then
		ViewPortModule.DestroyViewport(viewport)
		if viewport.Parent then
			viewport:Destroy()
		end
	else
		viewport:Destroy()
	end
end

function destroyGuiTree(instance)
	if not instance then
		return
	end

	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("ViewportFrame") then
			safeDestroyViewport(descendant)
		end
	end

	if instance.Parent then
		instance:Destroy()
	end
end

function clearSlotVisuals(slot)
	if not slot then return end

	resetSlotConnection(slot)

	-- Mesmo comportamento do UnitsHandler do lobby:
	-- limpa o visual antigo do slot para o template de raridade substituir o background.
	-- Preserva só objetos de suporte que não fazem parte do card visual.
	for _, child in slot:GetChildren() do
		if child:IsA("GuiObject") and child.Name ~= "LimitText" and child.Name ~= "Backend" then
			destroyGuiTree(child)
		end
	end

	slot:SetAttribute("TowerName", nil)

	local limitText = getSlotLimitText(slot)
	if limitText then
		limitText.Visible = false
	end

	if slot:FindFirstChild("Backend") and slot.Backend:FindFirstChild("valEnabled") then
		slot.Backend.valEnabled.Value = false
	end
end

function clearViewportContents(viewport)
	if not viewport or not viewport:IsA("ViewportFrame") then
		return
	end

	for _, child in viewport:GetChildren() do
		if child:IsA("ViewportFrame") then
			safeDestroyViewport(child)
		else
			child:Destroy()
		end
	end
end

function moveGeneratedViewportIntoExistingViewport(targetViewport, generatedViewport)
	if not targetViewport or not targetViewport:IsA("ViewportFrame") then
		return nil
	end
	if not generatedViewport or not generatedViewport:IsA("ViewportFrame") then
		return nil
	end

	local parent = targetViewport.Parent
	if not parent then
		safeDestroyViewport(generatedViewport)
		targetViewport:Destroy()
		return nil
	end

	generatedViewport.Name = targetViewport.Name
	generatedViewport.AnchorPoint = targetViewport.AnchorPoint
	generatedViewport.Position = targetViewport.Position
	generatedViewport.Size = targetViewport.Size
	generatedViewport.Visible = targetViewport.Visible
	generatedViewport.LayoutOrder = targetViewport.LayoutOrder
	generatedViewport.Rotation = targetViewport.Rotation
	generatedViewport.ZIndex = targetViewport.ZIndex
	generatedViewport.SizeConstraint = targetViewport.SizeConstraint
	generatedViewport.AutomaticSize = targetViewport.AutomaticSize
	generatedViewport.ClipsDescendants = targetViewport.ClipsDescendants
	generatedViewport.BackgroundColor3 = targetViewport.BackgroundColor3
	generatedViewport.BackgroundTransparency = targetViewport.BackgroundTransparency
	generatedViewport.BorderColor3 = targetViewport.BorderColor3
	generatedViewport.BorderMode = targetViewport.BorderMode
	generatedViewport.BorderSizePixel = targetViewport.BorderSizePixel

	targetViewport:Destroy()
	generatedViewport.Parent = parent

	return generatedViewport
end

function populateSlotViewport(viewportFrame, tower)
	if not viewportFrame or not viewportFrame:IsA("ViewportFrame") or not tower then
		return nil
	end

	local generatedViewport = ViewPortModule.CreateViewPort(tower.Name, tower:GetAttribute("Shiny"), true)
	if not generatedViewport then
		return nil
	end

	return moveGeneratedViewportIntoExistingViewport(viewportFrame, generatedViewport)
end

function populateEmptySlotViewport(viewportFrame)
	if not viewportFrame or not viewportFrame:IsA("ViewportFrame") then
		return nil
	end

	local generatedViewport = ViewPortModule.CreateEmptyPort(true)
	if not generatedViewport then
		return nil
	end

	return moveGeneratedViewportIntoExistingViewport(viewportFrame, generatedViewport)
end

function getTowerPreviewMetadata(tower)
	if not tower then
		return false, nil, nil, nil
	end

	local config = tower:FindFirstChild("Config")
	local shinyValue = config and config:FindFirstChild("Shiny")
	local traitValue = config and config:FindFirstChild("Trait")
	local timeObtainedValue = config and config:FindFirstChild("TimeObtained")
	local takedownsValue = config and config:FindFirstChild("Takedowns")

	local isShiny = tower:GetAttribute("Shiny") == true
	if shinyValue and shinyValue:IsA("BoolValue") then
		isShiny = shinyValue.Value
	end

	local traitName = tower:GetAttribute("Trait")
	if traitValue and traitValue:IsA("StringValue") and traitValue.Value ~= "" then
		traitName = traitValue.Value
	end

	local timeObtained = tower:GetAttribute("TimeObtained")
	if timeObtained == nil and timeObtainedValue and timeObtainedValue:IsA("ValueBase") then
		timeObtained = timeObtainedValue.Value
	end

	local takedowns = tower:GetAttribute("Takedowns")
	if takedowns == nil and takedownsValue and takedownsValue:IsA("ValueBase") then
		takedowns = takedownsValue.Value
	end

	return isShiny, traitName, timeObtained, takedowns
end

function createTowerPreviewSource(tower)
	if not tower then
		return nil
	end

	local previewSource = Instance.new("Folder")
	previewSource.Name = tower.Name

	local isShiny, traitName, timeObtained, takedowns = getTowerPreviewMetadata(tower)
	previewSource:SetAttribute("Shiny", isShiny == true)

	if traitName and traitName ~= "" then
		previewSource:SetAttribute("Trait", traitName)
	end

	if timeObtained ~= nil then
		previewSource:SetAttribute("TimeObtained", timeObtained)
	end

	if takedowns ~= nil then
		previewSource:SetAttribute("Takedowns", takedowns)
	end

	return previewSource
end

function getTowerInfoPreviewContainer(profile)
	if profile then
		local placeholder = findFirstChildByNames(profile, {"Placeholder", "PlaceHolder"})
		local profileViewport = findViewportFrame(placeholder or profile)
		if profileViewport then
			return profileViewport
		end
		if placeholder then
			return placeholder
		end
	end

	local leftSection = getScoutLeftSection()
	local previewFrame = leftSection and leftSection:FindFirstChild("PreviewFrame")
	local previewViewport = previewFrame and previewFrame:FindFirstChild("Preview")
	if previewViewport then
		return previewViewport
	end

	if not profile then
		return nil
	end

	return findViewportFrame(profile)
end

function populateTowerPreviewContainer(container, tower)
	if not container or not tower then
		return nil
	end

	local isShiny = getTowerPreviewMetadata(tower)

	if container:IsA("ViewportFrame") then
		clearViewportContents(container)

		local generatedViewport = ViewPortModule.CreateViewPort(tower.Name, isShiny, true)
		if not generatedViewport then
			return nil
		end

		return moveGeneratedViewportIntoExistingViewport(container, generatedViewport)
	end

	for _, child in container:GetChildren() do
		if child:IsA("ViewportFrame") then
			safeDestroyViewport(child)
		end
	end

	local generatedViewport = ViewPortModule.CreateViewPort(tower.Name, isShiny)
	if not generatedViewport then
		return nil
	end

	generatedViewport.Parent = container
	return generatedViewport
end

function getTowerPriceMultiplier(tower)
	local priceMultiplier = 1
	local traitName = tower:GetAttribute("Trait")

	if Traits.Traits[traitName] and not info.Versus.Value then
		local traitData = Traits.Traits[traitName]
		if traitData.Money then
			priceMultiplier = 1 - (traitData.Money / 100)
		end
	end

	if workspace.Info.ChallengeNumber.Value ~= -1 then
		local challengeData = ChallengeModule.Data[workspace.Info.ChallengeNumber.Value]
		if challengeData and challengeData.UnitStats ~= nil then
			priceMultiplier += (challengeData.UnitStats.Price / 100)
		end
	end

	return priceMultiplier
end

function setupSlotTemplateClone(template, slot, generatedName)
	if not template or not slot then
		return nil
	end

	local clone = template:Clone()
	clone.Name = generatedName or SLOT_TEMPLATE_NAME
	clone:SetAttribute("GeneratedSlotVisual", true)
	clone.Size = UDim2.fromScale(1, 1)
	clone.Position = UDim2.fromScale(0.5, 0.5)
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Visible = true
	clone.Parent = slot

	return clone
end

function getClickTarget(slot, visualRoot)
	if visualRoot and visualRoot:IsA("GuiButton") then
		return visualRoot
	end

	if slot and slot:IsA("GuiButton") then
		return slot
	end

	if visualRoot then
		local descendantButton = visualRoot:FindFirstChildWhichIsA("GuiButton", true)
		if descendantButton then
			return descendantButton
		end
	end

	return nil
end

function clearSlotDisplay(slot, slotIndex)
	if not slot then return end

	clearSlotVisuals(slot)
	slot.Visible = true

	local templateFolder = getTemplateFolder()
	local closedTemplate = templateFolder and templateFolder:FindFirstChild("Closed")

	if closedTemplate then
		local clone = setupSlotTemplateClone(closedTemplate, slot, SLOT_EMPTY_TEMPLATE_NAME)
		local profile = clone and clone:FindFirstChild("Profile")
		local viewportFrame = findViewportFrame(profile)
		if viewportFrame and viewportFrame:IsA("ViewportFrame") then
			populateEmptySlotViewport(viewportFrame)
		end
	else
		warn("Template Closed não encontrado em IngameHud.Template")
	end

	if player.PlayerLevel.Value < requiredSlotLevel[slotIndex] then
		slot:SetAttribute("SlotLocked", true)
	else
		slot:SetAttribute("SlotLocked", false)
	end
end

local createplacementbox
local AddPlaceholderTower
local setPlacementVFXEnabled

function fillSlotDisplay(slot, tower)
	if not slot or not tower then return end

	clearSlotVisuals(slot)
	slot.Visible = true

	local statsTower = upgradesModule[tower.Name]
	local rarity = (statsTower and statsTower.Rarity) or getUnitRarity(tower.Name) or "Rare"
	local template = getSlotTemplateForRarity(rarity)

	slot:SetAttribute("TowerName", tower.Name)
	slot:SetAttribute("SlotLocked", false)

	if not template then
		warn("Template de raridade não encontrado para o slot:", rarity, tower.Name)
		return
	end

	-- Copia o background/card da pasta IngameHud.Template, igual ao UnitsHandler do lobby.
	local visualRoot = setupSlotTemplateClone(template, slot, SLOT_TEMPLATE_NAME)
	if not visualRoot then
		return
	end

	local clickTarget = getClickTarget(slot, visualRoot)

	local profile = visualRoot:FindFirstChild("Profile")
	if profile then
		local viewportFrame = findViewportFrame(profile)
		if viewportFrame and viewportFrame:IsA("ViewportFrame") then
			populateSlotViewport(viewportFrame, tower)
		else
			warn("Profile sem ViewportFrame:", profile:GetFullName())
		end

		local profileText = profile:FindFirstChild("Text")
		if profileText then
			local priceLabel = profileText:FindFirstChild("Amount")
			local nameLabel = profileText:FindFirstChild("NamePerson")

			if priceLabel and statsTower then
				priceLabel.Text = "$" .. math.round(statsTower.Upgrades[1].Price * getTowerPriceMultiplier(tower))
			end

			if nameLabel then
				nameLabel.Text = tower.Name
			end
		end

		local starsFrame = profile:FindFirstChild("Stars")
		if starsFrame then
			local numStars = RARITY_STARS[rarity] or 2
			for starIndex = 1, 6 do
				local starNode = starsFrame:FindFirstChild(tostring(starIndex))
				if starNode then
					local emptyStar = starNode:FindFirstChild("Empty")
					local fullStar = starNode:FindFirstChild("Full")
					if emptyStar and fullStar then
						fullStar.Visible = starIndex <= numStars
						emptyStar.Visible = starIndex > numStars
					end
				end
			end
		end
	else
		warn("Template sem Profile:", visualRoot:GetFullName())
	end

	local levelFrame = visualRoot:FindFirstChild("Lvl")
	if levelFrame then
		local levelText = levelFrame:FindFirstChild("Text")
		local levelLabel = levelText and levelText:FindFirstChild("Amount")
		if levelLabel then
			levelLabel.Text = tostring(info.Versus.Value and 1 or tower:GetAttribute("Level") or 1)
		end
	end

	if clickTarget and clickTarget:IsA("GuiButton") then
		slotButtonConnections[slot] = clickTarget.Activated:Connect(function()
			PlacementDebug.log("SlotClick:request", "slot=", slot.Name, "tower=", tower.Name, "unitValue=", PlacementDebug.getInstancePath(tower))
			local allowedToSpawn = requestTowerFunction:InvokeServer(tower)
			PlacementDebug.log("SlotClick:request-result", "slot=", slot.Name, "tower=", tower.Name, "allowed=", allowedToSpawn)
			if allowedToSpawn then
				createplacementbox()
				towerToSpawnValue = tower
				AddPlaceholderTower(tower.Name, tower)
			end
		end)
	else
		warn("Slot sem GuiButton para clique:", slot:GetFullName())
	end
end
local refreshEquippedSlots
function disconnectOwnedTowerConnections(tower)
	local connections = ownedTowerConnections[tower]
	if not connections then
		return
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	ownedTowerConnections[tower] = nil
end
function watchOwnedTower(tower)
	if ownedTowerConnections[tower] then
		return
	end
	ownedTowerConnections[tower] = {
		tower:GetAttributeChangedSignal("Equipped"):Connect(function()
			refreshEquippedSlots()
		end),
		tower:GetAttributeChangedSignal("EquippedSlot"):Connect(function()
			refreshEquippedSlots()
		end),
		tower:GetAttributeChangedSignal("Level"):Connect(function()
			refreshEquippedSlots()
		end),
		tower:GetAttributeChangedSignal("Trait"):Connect(function()
			refreshEquippedSlots()
		end),
		tower:GetAttributeChangedSignal("Shiny"):Connect(function()
			refreshEquippedSlots()
		end),
		tower:GetPropertyChangedSignal("Name"):Connect(function()
			refreshEquippedSlots()
		end)
	}
end
refreshEquippedSlots = function()
	local equippedTowers = getEquippedTowersBySlot()
	table.clear(SelectedTowers)
	for i = 1, 6 do
		local tower = equippedTowers[i]
		SelectedTowers[i] = tower
		local slot = getSlotByIndex(i)
		if slot then
			if tower then
				fillSlotDisplay(slot, tower)
			else
				clearSlotDisplay(slot, i)
			end
		end
	end
end
function convertNum(ELO)
	return ELO % 100
end
function formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local seconds = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end
function CheckIfPc()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
		return false
	elseif not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return true
	end
end
function HideScoutToolbarsOnMobile()
	if CheckIfPc() ~= false then
		return
	end

	for _, descendant in Upgrade:GetDescendants() do
		if descendant.Name == "TOOLBAR" and descendant:IsA("GuiObject") then
			descendant.Visible = false
		end
	end
end
function EndScreenGUIDisable(value)
	IngameHud.Bottom.AmountMoney.Visible = value
	requestBottomSlotVisibility(value)
	if info.Versus.Value then
		local vh = IngameHud.Top:FindFirstChild("VersusHealth")
		if vh then
			vh.Visible = value
		end
	else
		IngameHud.Top.HealthBar.Visible = value
	end
end
function UpdatePlayerLevelBar()
	local playerLevelValue = player.PlayerLevel.Value
	local playerExpValue = player.PlayerExp.Value
	local requireExp = ExpModule.playerExpCalculation(playerLevelValue)
	if type(requireExp) ~= "number" or requireExp <= 0 then
		requireExp = math.max(playerExpValue, 1)
	end
	local ratio = math.clamp(playerExpValue / math.max(requireExp, 1), 0, 1)
	TweenService:Create(LevelBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(ratio, 0, LevelBarOriginalSize.Y.Scale, LevelBarOriginalSize.Y.Offset)
	}):Play()
	LevelNumber.Text = `Level {playerLevelValue} [{playerExpValue}/{requireExp}]`
end
function updateAbilityStatus()
	local rightSection = getScoutRightSection()
	local buttons = rightSection and rightSection:FindFirstChild("Buttons")
	if buttons and buttons:FindFirstChild("Ability") then
		buttons.Ability.DisplayBind.TextLabel.Text = AbilityStatus.Value
	end
end
function MouseRaycast(model)
	local currentCamera = getCurrentCamera()
	if not currentCamera then
		return nil
	end

	local guiInset = GuiService:GetGuiInset()
	local mousePosition = UserInputService:GetMouseLocation() - guiInset
	local mouseRay = currentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local raycastParams = RaycastParams.new()
	local blacklist = currentCamera:GetChildren()
	table.insert(blacklist, model)
	table.insert(blacklist, player.Character)
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = blacklist
	raycastParams.CollisionGroup = "UnitSelection"
	local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
	for i = 1, 10 do
		if not raycastResult or raycastResult.Instance.CanQuery then break end
		PlacementDebug.log("MouseRaycast:skip-non-query-hit", "attempt=", i, "raycast=", PlacementDebug.describeRaycastResult(raycastResult))
		table.insert(blacklist, raycastResult.Instance)
		raycastParams.FilterDescendantsInstances = blacklist
		raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
	end
	return raycastResult
end

function hasPlacementSurfaceForPlayer()
	if (info.Versus.Value or info.Competitive.Value) and not player.Team then
		return false
	end

	local mapRoot = workspace:FindFirstChild("Map")
	if not mapRoot then
		return false
	end

	for _, descendant in ipairs(mapRoot:GetDescendants()) do
		if not descendant:IsA("BasePart") then
			continue
		end

		local parent = descendant.Parent
		local parentName = parent and parent.Name
		if parentName == "GroundPlace" or parentName == "AirPlace" then
			return true
		end

		if player.Team and parentName == player.Team.Name .. "GroundPlace" then
			return true
		end
	end

	return false
end

function waitForPlacementSurface(timeoutSeconds)
	local deadline = os.clock() + (timeoutSeconds or 3)
	while os.clock() < deadline do
		if hasPlacementSurfaceForPlayer() and getCurrentCamera() then
			return true
		end

		task.wait(0.1)
	end

	return hasPlacementSurfaceForPlayer()
end

function getDirectChildUnder(parent: Instance?, instance: Instance?)
	if not parent or not instance or not instance:IsDescendantOf(parent) then
		return nil
	end

	local current = instance
	while current and current.Parent ~= parent do
		current = current.Parent
	end

	return current
end

function resolveTowerFromInstance(instance: Instance?)
	if not instance then
		return nil
	end

	local towersFolder = workspace:FindFirstChild("Towers")
	local tower = getDirectChildUnder(towersFolder, instance)
	if tower and tower:IsA("Model") and tower:FindFirstChild("Config") then
		return tower
	end

	local spawnablesFolder = workspace:FindFirstChild("Spawnables")
	local spawnable = getDirectChildUnder(spawnablesFolder, instance)
	if spawnable and spawnable:IsA("Model") then
		local ownedBy = spawnable:FindFirstChild("OwnedBy")
		if ownedBy and ownedBy:IsA("ObjectValue") and ownedBy.Value then
			return resolveTowerFromInstance(ownedBy.Value)
		end
	end

	return nil
end

function canSelectTower(tower: Instance?)
	if not tower or not tower:IsA("Model") then
		return false
	end

	local config = tower:FindFirstChild("Config")
	if not config then
		return false
	end

	local canAttackValue = config:FindFirstChild("CanAttack")
	return not canAttackValue or canAttackValue.Value ~= false
end

function prepareTowerSelectionParts(tower: Instance?)
	if not tower or not tower:IsA("Model") then
		return
	end

	for _, descendant in tower:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanQuery = true
		end
	end
end

task.defer(function()
	local towersFolder = workspace:WaitForChild("Towers")
	for _, tower in towersFolder:GetChildren() do
		prepareTowerSelectionParts(tower)
	end

	towersFolder.ChildAdded:Connect(function(tower)
		task.defer(function()
			prepareTowerSelectionParts(tower)
		end)
	end)
end)

function isPlacementResultValid(result: RaycastResult?, tower: Model?)
	if not result or not result.Instance or not tower then
		return false
	end

	if PlacementDebug.isBlockedSurfaceName(result.Instance) then
		return false
	end

	if result.Normal.Y < PlacementDebug.minSurfaceNormalY then
		return false
	end

	if isNearEnemySpawn(result.Position) then
		return false
	end

	local parent = result.Instance.Parent
	local parentName = parent and parent.Name
	if parentName == "GroundPlace" or (player.Team and parentName == player.Team.Name .. "GroundPlace") then
		return true
	end

	return parentName == "AirPlace" and upgradesModule[tower.Name].Upgrades[1].Type == "Air"
end

function buildPlacementColorSequence(primaryColor: Color3, secondaryColor: Color3)
	return ColorSequence.new{
		ColorSequenceKeypoint.new(0, primaryColor),
		ColorSequenceKeypoint.new(0.649, primaryColor),
		ColorSequenceKeypoint.new(1, secondaryColor)
	}
end

function getOrCreatePlacementHighlight(tower: Model)
	local highlight = tower:FindFirstChild("PlacementPreviewHighlight")
	if highlight and highlight:IsA("Highlight") then
		return highlight
	end

	highlight = Instance.new("Highlight")
	highlight.Name = "PlacementPreviewHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillTransparency = 0.55
	highlight.OutlineTransparency = 0.1
	highlight.Parent = tower
	return highlight
end
createplacementbox = function()
	local e = workspace.Towers:GetChildren()
	for i, tower in e do
		if tower:FindFirstChild("PlacementBox") or tower:GetAttribute("Ignore") then continue end
		local p = Instance.new("Part")
		local w = Instance.new("WeldConstraint")
		p.Name = "PlacementBox"
		p.Parent = tower
		w.Name = "PlacementWeld"
		w.Parent = tower
		w.Part0 = tower.VFXTowerBasePart
		w.Part1 = p
		p.Anchored = true
		p.CanCollide = true
		p.CFrame = tower.VFXTowerBasePart.CFrame
		p.Color = Color3.new(0.988235, 0, 0)
		p.Material = Enum.Material.ForceField
		p.Size = Vector3.new(2.623, 3.256, 3.256)
		p.Orientation = Vector3.new(0, 90, -90)
		p.Shape = Enum.PartType.Cylinder
		PhysicsService:SetPartCollisionGroup(p, "Tower")
	end
	for i, v: BasePart in workspace:WaitForChild("RedZones"):GetChildren() do
		v.Transparency = 0
	end
end
function CreateRangeCircle(tower: Model, placeholder)
	local HumanoidRootPart = tower:WaitForChild("HumanoidRootPart")
	local indicatorHeightOffset = 0.25
	local flatIndicatorThickness = 0.05
	local rangesize = Vector3.new(0, 0, 0)
	if game.Workspace.Camera:FindFirstChild("Range") then
		rangesize = game.Workspace.Camera.Range.Size
	end
	game.Workspace.Camera:ClearAllChildren()
	local config = if placeholder then upgradesModule[tower.Name].Upgrades[1] else upgradesModule[tower.Name].Upgrades[tower.Config:WaitForChild("Upgrades").Value]
	local range = TowerInfo.GetRange(tower, placeholder)
	local height = (HumanoidRootPart.Size.Y * 2.5) / 2
	local offset = CFrame.new(0, -height + indicatorHeightOffset, 0)
	local aoeYOffset = HumanoidRootPart.Size.Y * -1.45 + indicatorHeightOffset
	local VFXTowerBasePart
	if tower:FindFirstChild("VFXTowerBasePart") then
		VFXTowerBasePart = tower:FindFirstChild("VFXTowerBasePart")
	else
		VFXTowerBasePart = Instance.new("Part")
		VFXTowerBasePart.Name = "VFXTowerBasePart"
		VFXTowerBasePart.CanCollide = false
		VFXTowerBasePart.CanTouch = false
		VFXTowerBasePart.CanQuery = false
		VFXTowerBasePart.Transparency = 1
		VFXTowerBasePart.Anchored = true
		VFXTowerBasePart.Position = HumanoidRootPart.Position
		VFXTowerBasePart.Size = Vector3.new(HumanoidRootPart.Size.Y, HumanoidRootPart.Size.Y, HumanoidRootPart.Size.Y)
		VFXTowerBasePart.Parent = tower
	end
	local TowerBasePart
	if tower:FindFirstChild("TowerBasePart") then
		TowerBasePart = tower:FindFirstChild("TowerBasePart")
	else
		TowerBasePart = Instance.new("Part")
		TowerBasePart.Name = "TowerBasePart"
		TowerBasePart.CanCollide = false
		TowerBasePart.CanTouch = false
		TowerBasePart.CanQuery = false
		TowerBasePart.Transparency = 1
		TowerBasePart.Anchored = true
		TowerBasePart.Position = HumanoidRootPart.Position
		TowerBasePart.Size = Vector3.new(HumanoidRootPart.Size.Y, HumanoidRootPart.Size.Y, HumanoidRootPart.Size.Y)
		TowerBasePart.Parent = tower
	end
	local previewBasePart = if placeholder then VFXTowerBasePart else TowerBasePart
	if placeholder then
		local p = ReplicatedStorage.VFX.Range:Clone()
		p.CFrame = VFXTowerBasePart.CFrame * offset
		p.Size = Vector3.new(range * 2, flatIndicatorThickness, range * 2)
		p.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = p
		weld.Part1 = VFXTowerBasePart
		weld.Parent = p
		p.Parent = tower
		local att = script.Attachments.PlacementParticles:Clone()
		att.Orientation = Vector3.new(0, 0, 0)
		att.Position = Vector3.new(0, VFXTowerBasePart.Size.Y * -1.45, 0)
		att.Parent = VFXTowerBasePart
		att.Outline:Emit(1)
	else
		local p = ReplicatedStorage.VFX.RangeSphere:Clone()
		p.Name = "Range"
		p.Size = rangesize
		p.CFrame = previewBasePart.CFrame * offset
		local p2 = ReplicatedStorage.VFX.Range:Clone()
		p2.Name = "Range2"
		p2.Anchored = true
		p2.CFrame = previewBasePart.CFrame * offset
		p2.Size = Vector3.new(rangesize.X + 0.01, flatIndicatorThickness, rangesize.Z + 0.01)
		p2.Parent = workspace.Camera
		p.Anchored = true
		p.Parent = workspace.Camera
		TweenService:Create(p2, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {Size = Vector3.new(range * 2, flatIndicatorThickness, range * 2)}):Play()
		TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {Size = Vector3.new(range * 2, range * 2, range * 2)}):Play()
	end
	warn("DEBUG XO1")
	if tower.TowerBasePart:FindFirstChild("PlacementParticles") and false then
		warn("wee woo dont execute")
		tower.TowerBasePart.PlacementParticles.Outline.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 0)),
			ColorSequenceKeypoint.new(.649, Color3.fromRGB(255, 170, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 242, 58))
		}
		tower.TowerBasePart.PlacementParticles.RIPPLE.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 0)),
			ColorSequenceKeypoint.new(.649, Color3.fromRGB(255, 170, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 242, 58))
		}
	end
	tower.TowerBasePart.Size = Vector3.new(2, 3, 2)
	tower.TowerBasePart.CanQuery = true
	if config.AOEType then
		if config.AOEType == "Cone" then
			local coneaoe = ReplicatedStorage.VFX.ConeAOE:Clone()
			coneaoe.Anchored = false
			local weld = Instance.new("WeldConstraint")
			coneaoe.Size = Vector3.new((config.AOESize / 45) * range * 2, flatIndicatorThickness, range)
			coneaoe.CFrame = previewBasePart.CFrame * CFrame.new(0, aoeYOffset, -(coneaoe.Size.Z / 2))
			weld.Part0 = coneaoe
			weld.Part1 = previewBasePart
			weld.Parent = coneaoe
			coneaoe.Parent = game.Workspace.Camera
		elseif config.AOEType == "Splash" and config.Type.Value ~= "Spawner" then
			local splashaoe = ReplicatedStorage.VFX.SplashPart:Clone()
			splashaoe.Anchored = false
			local weld = Instance.new("WeldConstraint")
			splashaoe.Size = Vector3.new(config.AOESize * 2, flatIndicatorThickness, config.AOESize * 2)
			if not placeholder then
				splashaoe.CFrame = CFrame.new(tower:WaitForChild("SplashPositionPart").Position)
				weld.Part1 = tower.SplashPositionPart
			else
				local newCFrame = CFrame.new((VFXTowerBasePart.CFrame * CFrame.new(0, indicatorHeightOffset, -config.AOESize * 1.5)).Position)
				splashaoe.CFrame = newCFrame
				weld.Part1 = VFXTowerBasePart
			end
			weld.Part0 = splashaoe
			weld.Parent = splashaoe
			splashaoe.Parent = game.Workspace.Camera
			TweenService:Create(splashaoe, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, false), {Rotation = Vector3.new(0, 360, 0)}):Play()
			local arrows = script.Arrows:Clone()
			arrows.Parent = splashaoe
			arrows.Part1.Position = previewBasePart.Position
			if placeholder then
				local weld1 = Instance.new("WeldConstraint")
				weld1.Part0 = arrows.Part1
				weld1.Part1 = previewBasePart
				weld1.Parent = arrows.Part1
				arrows.Part1.Anchored = false
			end
			arrows.Part2.Position = splashaoe.Position
			arrows.Part2.Anchored = if placeholder then false else true
			local weld2 = Instance.new("WeldConstraint")
			weld2.Part0 = arrows.Part2
			weld2.Part1 = splashaoe
			weld2.Parent = arrows.Part2
		elseif config.AOEType == "AOE" then
			local fullaoe = ReplicatedStorage.VFX.SplashPart:Clone()
			fullaoe.Anchored = false
			fullaoe.Size = Vector3.new(range * 2, flatIndicatorThickness, range * 2)
			fullaoe.Position = previewBasePart.Position - Vector3.new(0, HumanoidRootPart.Size.Y * 1.45 - indicatorHeightOffset, 0)
			local weld1 = Instance.new("WeldConstraint")
			weld1.Part0 = fullaoe
			weld1.Part1 = previewBasePart
			weld1.Parent = fullaoe
			fullaoe.Parent = game.Workspace.Camera
			TweenService:Create(fullaoe, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, false), {Rotation = Vector3.new(0, 360, 0)}):Play()
		end
	end
end
function FindEquippedTowerName(towerName)
	local Player = Players.LocalPlayer
	for i, v in Player.OwnedTowers:GetChildren() do
		if v:GetAttribute("Equipped") == true and v.Name == towerName then
			return v
		end
	end
	return false
end
function findSlotByTowerName(towerName)
	for i = 1, 6 do
		local slot = getSlotByIndex(i)
		if not slot then continue end
		if slot:GetAttribute("TowerName") == towerName then
			return slot
		end
	end
	return nil
end
function RemovePlaceholderTower()
	if towerToSpawn then
		PlacementDebug.log("RemovePlaceholderTower", "tower=", towerToSpawn.Name, "cframe=", PlacementDebug.formatCFrame(towerToSpawn:GetPivot()))
		canPlace = false
		PlacementDebug.lastSignature = nil
		local UnitSlot = findSlotByTowerName(towerToSpawn.Name)
		if UnitSlot then
			local limitText = getSlotLimitText(UnitSlot)
			if limitText then
				limitText.Visible = false
			end
		end
		script.Parent.PhoneControls.Visible = false
		towerToSpawn:Destroy()
		towerToSpawn = nil
		rotation = 0
		gui.Controls.Visible = false
		for i, tower in workspace.Towers:GetChildren() do
			if tower:FindFirstChild("PlacementBox") then
				tower.PlacementWeld:Destroy()
				tower.PlacementBox:Destroy()
			end
		end
		game.Workspace.Camera:ClearAllChildren()
		for i, v in workspace:WaitForChild("RedZones"):GetChildren() do
			v.Transparency = 1
		end
	end
end
AddPlaceholderTower = function(name, unit)
	PlacementDebug.log("AddPlaceholderTower:start", "name=", name, "unit=", PlacementDebug.getInstancePath(unit), "trait=", unit and unit:GetAttribute("Trait"), "shiny=", unit and unit:GetAttribute("Shiny"))
	game.Workspace.Camera:ClearAllChildren()
	local towerExists = GetUnitModel[name]
	if towerExists then
		RemovePlaceholderTower()
		local placementSurfaceReady = waitForPlacementSurface(3)
		PlacementDebug.log("AddPlaceholderTower:placement-surface-ready", "name=", name, "ready=", placementSurfaceReady, "team=", player.Team and player.Team.Name or "nil")
		towerToSpawn = towerExists:Clone()
		local counter = 0
		local Limit = if not info.Versus.Value and (unit:GetAttribute("Trait") == "Cosmic Crusader" or unit:GetAttribute("Trait") == "Waders Will") then 1 else upgradesModule[towerToSpawn.Name]["Place Limit"]
		for _, u in game.Workspace.Towers:GetChildren() do
			if u.Name == towerToSpawn.Name and u.Config.Owner.Value == player.Name then
				counter = counter + 1
			end
		end
		local UnitSlot = findSlotByTowerName(towerToSpawn.Name)
		if UnitSlot then
			local limitText = getSlotLimitText(UnitSlot)
			if limitText then
				limitText.Visible = true
				limitText.Text = counter .. "/" .. Limit
			end
		end
		PlacementDebug.log("AddPlaceholderTower:limit", "name=", towerToSpawn.Name, "placedByPlayer=", counter, "limit=", Limit, "money=", playerMoney.Value)
		local result = MouseRaycast(towerToSpawn)
		local initialCanPlace = isPlacementResultValid(result, towerToSpawn)
		PlacementDebug.log("AddPlaceholderTower:initial-raycast", "name=", towerToSpawn.Name, "initialCanPlace=", initialCanPlace, "raycast=", PlacementDebug.describeRaycastResult(result))
		if result and result.Instance then
			local height = towerToSpawn:WaitForChild("HumanoidRootPart").Size.Y * 1.5
			local x = result.Position.X
			local y = result.Position.Y + height
			local z = result.Position.Z
			local cframe = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rotation), 0)
			towerToSpawn:SetPrimaryPartCFrame(cframe)
			if towerToSpawn:FindFirstChild("VFXTowerBasePart", true) then
				towerToSpawn:FindFirstChild("VFXTowerBasePart", true).CFrame = cframe
			end
			PlacementDebug.log("AddPlaceholderTower:initial-cframe", "name=", towerToSpawn.Name, "height=", height, "cframe=", PlacementDebug.formatCFrame(cframe))
		else
			PlacementDebug.log("AddPlaceholderTower:no-initial-result", "name=", towerToSpawn.Name)
		end
		towerToSpawn.Parent = workspace
		if towerToSpawn:FindFirstChild("Animations") then
			if towerToSpawn.Animations:FindFirstChild("Idle") then
				towerToSpawn.Humanoid:LoadAnimation(towerToSpawn.Animations.Idle):Play()
			end
		end
		CreateRangeCircle(towerToSpawn, true)
		createplacementbox(towerToSpawn, true)
		local equippedTower = FindEquippedTowerName(name)
		if equippedTower then
			Traits.AddVisualAura(towerToSpawn, equippedTower:GetAttribute("Trait"))
		end
		for i, object in towerToSpawn:GetDescendants() do
			if object:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(object, "Tower")
			end
		end
		setPlacementVFXEnabled(towerToSpawn, initialCanPlace)
		canPlace = initialCanPlace
		PlacementDebug.state("AddPlaceholderTower:ready", result, towerToSpawn, towerToSpawn:GetPivot())
		if UserInputService.TouchEnabled then
			script.Parent.PhoneControls.Visible = true
		else
			gui.Controls.Visible = true
			local connection
			function UpdateControlPosition()
				if not gui.Controls.Visible then connection:Disconnect() end
				if UserInputService.GamepadEnabled then
					gui.Controls.Position = UDim2.new(0.075, mouse.X, 0, mouse.Y)
				else
					gui.Controls.Position = UDim2.new(0.0125, mouse.X, 0, mouse.Y)
				end
			end
			UpdateControlPosition()
			connection = mouse.Move:Connect(UpdateControlPosition)
		end
	else
		PlacementDebug.log("AddPlaceholderTower:model-missing", "name=", name)
	end
end
local toggleTowerInfo

function restoreDefaultCameraSubject()
	if player:GetAttribute("PossessingTower") ~= nil then
		return
	end

	local playerChr = player.Character or player.CharacterAdded:Wait()
	camera.CameraSubject = playerChr:WaitForChild("Humanoid")
end

function disconnectSpectateConnections()
	if spectateStopConnection then
		spectateStopConnection:Disconnect()
		spectateStopConnection = nil
	end

	if spectateTowerAncestryConnection then
		spectateTowerAncestryConnection:Disconnect()
		spectateTowerAncestryConnection = nil
	end
end

function restoreSpectateVisualState()
	for instance, previousValue in spectateVisualState do
		if instance and instance.Parent then
			if instance:IsA("BasePart") then
				instance.Transparency = previousValue
			elseif instance:IsA("ImageLabel") then
				instance.ImageTransparency = previousValue
			elseif instance:IsA("Beam") then
				instance.Enabled = previousValue
			end
		end
	end

	table.clear(spectateVisualState)
end

function stopSpectating()
	local stopButton = resolveStopButton()
	local stopButtonVisible = stopButton and stopButton.Visible or false

	if not spectatingTower and not stopButtonVisible and next(spectateVisualState) == nil then
		return
	end

	disconnectSpectateConnections()
	restoreSpectateVisualState()

	spectatingTower = nil
	if stopButton then
		stopButton.Visible = false
	end
	IngameHud.Bottom.AmountMoney.Visible = true
	requestBottomSlotVisibility(true)
	Upgrade.Visible = selectedTower ~= nil
	restoreDefaultCameraSubject()
end

function startSpectating(tower)
	if not tower or tower.Parent == nil then
		return
	end

	local unitHum = tower:FindFirstChild("Humanoid", true)
	local focusPart = tower:FindFirstChild("HumanoidRootPart", true)
	if not unitHum or not focusPart then
		return
	end

	stopSpectating()
	spectatingTower = tower
	camera.CameraSubject = focusPart

	for _, v in camera:GetDescendants() do
		if v:IsA("BasePart") then
			spectateVisualState[v] = v.Transparency
			v.Transparency = 1
		elseif v:IsA("ImageLabel") then
			spectateVisualState[v] = v.ImageTransparency
			v.ImageTransparency = 1
		elseif v:IsA("Beam") then
			spectateVisualState[v] = v.Enabled
			v.Enabled = false
		end
	end

	IngameHud.Bottom.AmountMoney.Visible = false
	Upgrade.Visible = false
	requestBottomSlotVisibility(false)
	local stopButton = resolveStopButton()
	if stopButton then
		stopButton.Visible = true

		if stopButton:IsA("GuiButton") then
			spectateStopConnection = stopButton.MouseButton1Click:Connect(function()
				stopSpectating()
			end)
		end
	end

	spectateTowerAncestryConnection = tower.AncestryChanged:Connect(function(_, parent)
		if parent ~= nil then
			return
		end

		task.defer(function()
			if selectedTower == tower then
				selectedTower = nil
			end

			stopSpectating()
			toggleTowerInfo()
		end)
	end)
end

toggleTowerInfo = function()
	if spectatingTower and selectedTower ~= spectatingTower then
		stopSpectating()
	end

	abilityTick = tick()
	if abilityConn then
		abilityConn:Disconnect()
		abilityConn = nil
		abilityActivateConn:Disconnect()
		abilityActivateConn = nil
	end
	local newHighlight = Instance.new("Highlight")
	newHighlight.FillTransparency = 1
	if selectedTower then
		local towerName = type(selectedTower) == "string" and selectedTower or selectedTower.Name
		local towerUpgrades = upgradesModule[towerName]
		if not towerUpgrades then return end
		local hasMoneyUpgrade = false
		if towerUpgrades.Upgrades then
			for _, upgrade in towerUpgrades.Upgrades do
				if upgrade.Money then
					hasMoneyUpgrade = true
					break
				end
			end
		end
		for i, v: Model in workspace:WaitForChild("Spawnables"):GetChildren() do
			if v:FindFirstChild("Radius") then
				TweenModule.tween(v.Radius, 0.3, {Transparency = 1})
			end
		end
		for i, v: Model in workspace:WaitForChild("Spawnables"):GetChildren() do
			if v:IsA("Model") then
				if v:FindFirstChild("OwnedBy") and v.OwnedBy.Value == selectedTower then
					if v:FindFirstChild("Radius") then
						TweenModule.tween(v.Radius, 0.3, {Transparency = 0.7})
					end
				end
			end
		end
		Click:Play()
		local Rightsection = getScoutRightSection()
		local Leftsection = getScoutLeftSection()
		if not Rightsection or not Leftsection then
			warn("Scout UI sem secoes esperadas:", Upgrade:GetFullName())
			return
		end
		local Middle = Leftsection:WaitForChild("Middle")
		local Buttons = Rightsection:WaitForChild("Buttons")
		local Profile = Rightsection:WaitForChild("Profile")
		if not hasMoneyUpgrade then
			Middle.Damage.Icon.Image = `rbxassetid://{93635387578503}`
			Middle.Damage.Visible = true
			Middle.Cooldown.Visible = true
			Middle.Range.Visible = true
			Upgrade.VFXText.Visible = true
		else
			Middle.Damage.Icon.Image = `rbxassetid://{132305833180435}`
			Middle.Damage.Visible = true
			Middle.Cooldown.Visible = false
			Middle.Range.Visible = false
			Upgrade.VFXText.Visible = true
		end
		local towername = selectedTower.Name
		Leftsection.Title.Text = towername
		CreateRangeCircle(selectedTower)
		newHighlight.Parent = selectedTower
		Upgrade.Visible = true
		local config = selectedTower.Config
		Profile.NamePerson.Text = towername
		Rightsection.Texto.Text = config.Owner.Value .. ""
		local buffs = {}
		local TraitBuff = config.Trait
		local TraitValue = Traits.Traits[TraitBuff.Value]
		local TraitImage = Profile:FindFirstChild("TraitIcon")
		if TraitImage then
			if TraitValue and TraitBuff.Value ~= "" and not info.Versus.Value then
				TraitImage.Visible = true
				TraitImage.Image = TraitValue.ImageID
				TraitImage.UIGradient.Color = Traits.TraitColors[TraitValue.Rarity].Gradient
			else
				TraitImage.Visible = false
			end
		end
		local buffstring = ""
		local index = 0
		for i, v in buffs do
			index += 1
			if index == 1 then
				buffstring = "Buffs: " .. i .. " " .. tostring(v) .. "%"
			else
				buffstring ..= ", " .. i .. " " .. tostring(v) .. "%"
			end
		end
		local previewContainer = getTowerInfoPreviewContainer(Profile)
		if previewContainer then
			populateTowerPreviewContainer(previewContainer, selectedTower)
		else
			warn("Profile sem container de preview:", Profile:GetFullName())
		end
		if config.Shiny.Value and Profile:FindFirstChild("Shiny") then
			Profile.Shiny.Visible = true
		elseif Profile:FindFirstChild("Shiny") then
			Profile.Shiny.Visible = false
		end
		local TowerRarity = upgradesModule[towername].Rarity
		if TowerRarity then
			if Profile.Bg:FindFirstChild("UIGradient") then
				Profile.Bg.UIGradient.Color = UnitGradients[TowerRarity].Color
			end
			if Profile.Shadow:FindFirstChild("UIGradient") then
				Profile.Shadow.UIGradient.Color = UnitGradients[TowerRarity].Color
			end
		end
		Buttons.Target.Text.Text = config.TargetMode.Value
		Buttons.Upgrade.Visible = true
		Buttons.Target.Visible = true
		Buttons.Sell.Visible = true

		local upgradeTower = config:FindFirstChild("Upgrades")
		local UpgradeModule = require(ReplicatedStorage.Upgrades)
		local UnitStats = UpgradeModule[selectedTower.Name].Upgrades
		local CurrentData = UnitStats[upgradeTower.Value]
		if Buttons:FindFirstChild("Ability") then
			Buttons.Ability.Visible = if CurrentData.AbilityCooldown then true else false
		end
		if CurrentData.AbilityCooldown then
			abilityConn = UserInputService.InputBegan:Connect(function(key, gp)
				if not gp then
					if (key.KeyCode == Enum.KeyCode.G or key.KeyCode == Enum.KeyCode.ButtonB) and AbilityStatus.Value == "G" then
						ActivateAbility:FireServer(selectedTower)
					end
				end
			end)
			if Buttons:FindFirstChild("Ability") then
				abilityActivateConn = Buttons.Ability.Activated:Connect(function()
					ActivateAbility:FireServer(selectedTower)
				end)
			end
		end
		if upgradeTower then
			local UpgradeData = UnitStats[upgradeTower.Value + 1]
			local priceMultiplier = 1
			if Traits.Traits[config.Trait.Value] and not info.Versus.Value then
				if Traits.Traits[config.Trait.Value]["Money"] then
					priceMultiplier = (1 - (Traits.Traits[config.Trait.Value]["Money"] / 100))
				end
			end
			if workspace.Info.ChallengeNumber.Value ~= -1 then
				local challengeData = ChallengeModule.Data[workspace.Info.ChallengeNumber.Value]
				if challengeData and challengeData.UnitStats ~= nil then
					priceMultiplier += (challengeData.UnitStats.Price / 100)
				end
			end
			if UpgradeData then
				if UnitStats[upgradeTower.Value].AttackName ~= UpgradeData.AttackName then
					Upgrade.VFXText.Text = "+" .. UpgradeData.AttackName
				else
					Upgrade.VFXText.Text = ""
				end
			else
				Upgrade.VFXText.Text = ""
			end
			local levelboost = 1 + config.Level.Value * (1 / 50)
			local UpgradeStats = {Damage = nil, Range = nil, Cooldown = nil}
			for _, stat in (hasMoneyUpgrade and {"Damage"}) or {"Damage", "Range", "Cooldown"} do
				if UpgradeData ~= nil then
					UpgradeStats[stat] = UpgradeData[stat]
				end
			end
			if UpgradeStats.Damage ~= nil then
				UpgradeStats.Damage = math.round(UpgradeStats.Damage * levelboost) > 100 and (UpgradeStats.Damage * levelboost) or ((UpgradeStats.Damage * levelboost) * 10) / 10
			end
			local sellPrice = math.round(selectedTower.Config.Worth.Value / 2)
			Buttons.Sell.Text.Text = "Sell: " .. math.round(sellPrice) .. "$"
			for _, stat in (hasMoneyUpgrade and {"Damage"}) or {"Damage", "Range", "Cooldown"} do
				if not UpgradeData then
					Leftsection.Upgrade.Text = "Upgrade [Max]"
					Buttons.Upgrade.Text.Text = "Upgrade [Max]"
					Buttons.Upgrade.Visible = false
					Middle[stat]["Arrow"].Visible = false
					Middle[stat]["Value1"].Visible = false
				else
					Leftsection.Upgrade.Text = "Upgrade [" .. config.Upgrades.Value - 1 .. "]"
					Buttons.Upgrade.Visible = true
					Buttons.Upgrade.Text.Text = "Upgrade: " .. math.round(UpgradeData.Price * priceMultiplier) .. "$"
					Middle[stat]["Arrow"].Visible = true
					Middle[stat]["Value1"].Visible = true
				end
				local Value
				if hasMoneyUpgrade then
					Value = config["Money"].Value
				else
					Value = TowerInfo["Get" .. stat](selectedTower)
				end
				if not info.Versus.Value and stat == "Cooldown" and workspace:GetAttribute("CosmicCrusader") then
					Value *= Traits.Traits["Cosmic Crusader"].TowerBuffs.Cooldown
				end
				Middle[stat]["value"].Text = Format.Format(Value, 1)
				if UpgradeData then
					local Value2
					if hasMoneyUpgrade then
						Value2 = UpgradeData["Money"]
					else
						Value2 = UpgradeData[stat]
					end
					if not hasMoneyUpgrade and not info.Versus.Value and stat == "Damage" then
						Value2 *= levelboost
						local towerData = upgradesModule[selectedTower.Name]
						Value2 = GameBalance.ApplyTowerDamage(Value2, towerData and towerData.Rarity)
					end
					if not info.Versus.Value and stat == "Cooldown" and workspace:GetAttribute("CosmicCrusader") then
						Value2 *= Traits.Traits["Cosmic Crusader"].TowerBuffs.Cooldown
					end
					Middle[stat]["Value1"].Text = Format.Format(Value2, 1)
				end
			end
		else
			Buttons.Upgrade.Visible = false
		end
		if config.Owner.Value == Players.LocalPlayer.Name then
			IsOwner = true
			Buttons.Upgrade.Visible = true
			Buttons.Target.Visible = true
			Buttons.Sell.Visible = true
		else
			IsOwner = false
			Buttons.Upgrade.Visible = false
			Buttons.Target.Visible = false
			Buttons.Sell.Visible = false
		end
		local originalTower = selectedTower
		function updateTotalDamage()
			local newTotalDamage = originalTower.Config.TotalDamage.Value
			Upgrade.TotalDamage.Text = `Total Damage: {Shortner.ShortenNum(newTotalDamage)}`
		end
		updateTotalDamage()
		local connection; connection = selectedTower.Config.TotalDamage:GetPropertyChangedSignal("Value"):Connect(function()
			if selectedTower == nil or selectedTower ~= originalTower then connection:Disconnect() return end
			updateTotalDamage()
		end)
	else
		workspace.Camera:ClearAllChildren()
		Upgrade.Visible = false
		for i, v: Model in workspace:WaitForChild("Spawnables"):GetChildren() do
			if v:FindFirstChild("Radius") then
				TweenModule.tween(v.Radius, 0.3, {Transparency = 1})
			end
		end
	end
	coroutine.wrap(function()
		repeat wait(0.01) until selectedTower == nil
		newHighlight:Destroy()
	end)()
end
function SpawnNewTower()
	if not towerToSpawn then
		PlacementDebug.log("SpawnNewTower:blocked-no-placeholder")
		return
	end

	local currentTime = tick()
	local timeSinceLastSpawn = currentTime - lastSpawnTime
	local placeholderCFrame = towerToSpawn:WaitForChild("HumanoidRootPart").CFrame
	PlacementDebug.log("SpawnNewTower:attempt", "tower=", towerToSpawn.Name, "unitValue=", PlacementDebug.getInstancePath(towerToSpawnValue), "canPlace=", canPlace, "cooldownRemaining=", math.max(0, spawnCooldown - timeSinceLastSpawn), "cframe=", PlacementDebug.formatCFrame(placeholderCFrame), "money=", playerMoney.Value)

	if not canPlace then
		PlacementDebug.log("SpawnNewTower:blocked-canPlace-false", "tower=", towerToSpawn.Name, "lastRaycast=", PlacementDebug.describeRaycastResult(lastValidResult))
		return
	end

	if timeSinceLastSpawn < spawnCooldown then
		PlacementDebug.log("SpawnNewTower:blocked-cooldown", "tower=", towerToSpawn.Name, "timeSinceLastSpawn=", timeSinceLastSpawn, "spawnCooldown=", spawnCooldown)
		return
	end

	lastSpawnTime = currentTime
	if placeholderCFrame == GetUnitModel[towerToSpawn.Name].HumanoidRootPart.CFrame then
		PlacementDebug.log("SpawnNewTower:blocked-default-cframe", "tower=", towerToSpawn.Name, "cframe=", PlacementDebug.formatCFrame(placeholderCFrame))
		return
	end

	PlacementDebug.log("SpawnNewTower:InvokeServer", "tower=", towerToSpawn.Name, "unitValue=", PlacementDebug.getInstancePath(towerToSpawnValue), "cframe=", PlacementDebug.formatCFrame(placeholderCFrame))
	local placedTower = spawnTowerFunction:InvokeServer(towerToSpawnValue, placeholderCFrame, false, true)
	PlacementDebug.log("SpawnNewTower:server-result", "tower=", towerToSpawn.Name, "resultType=", typeof(placedTower), "result=", typeof(placedTower) == "Instance" and PlacementDebug.getInstancePath(placedTower) or tostring(placedTower))
	if typeof(placedTower) == "Instance" and placedTower:IsA("Model") then
		placedTowers += 1
		selectedTower = placedTower
		local placeanimation = script.PlaceAnimation:Clone()
		placeanimation.Parent = placedTower
		placedTower:WaitForChild("Humanoid"):LoadAnimation(placeanimation):Play()
		local effect = script.PlacementEffect:Clone()
		effect.Position = placedTower:WaitForChild("HumanoidRootPart").Position - Vector3.new(0, 1, 0)
		effect.Parent = game.Workspace.VFX
		VFX_Loader.EmitAllParticles(effect)
		Debris:AddItem(effect, 2)
		Debris:AddItem(placeanimation, 2)
		local att = script.Attachments.PlacementParticles:Clone()
		att.Outline.LockedToPart = false
		att.RIPPLE.LockedToPart = false
		att.Position = Vector3.new(0, selectedTower:WaitForChild("HumanoidRootPart").Size.Y * -1.45, 0)
		att.Orientation = Vector3.new(0, 0, 0)
		att.Parent = selectedTower:WaitForChild("TowerBasePart")
		att.Outline:Emit(1)
		RemovePlaceholderTower()
		selectedTower = nil
		toggleTowerInfo()
	else
		PlacementDebug.log("SpawnNewTower:server-denied", "tower=", towerToSpawn.Name, "result=", tostring(placedTower))
		warn("Bro Cant Spawn")
	end
end
function UpgradeFunc()
	if selectedTower and IsOwner then
		local upgradeTower = selectedTower:WaitForChild("Config").Upgrades.Value
		local upgradeSuccess = UpgradeFunction:InvokeServer(selectedTower)
		if typeof(upgradeSuccess) == "string" then
			_G.Message(upgradeSuccess, Color3.fromRGB(221, 0, 0))
		elseif upgradeSuccess then
			local effect = script.UpgradeEffect:Clone()
			effect.Position = selectedTower.PrimaryPart.Position - Vector3.new(0, 1, 0)
			effect.Parent = game.Workspace.VFX
			VFX_Loader.EmitAllParticles(effect)
			events.Client.TowerUpgrade:Fire(selectedTower)
			Debris:AddItem(effect, 2)
			toggleTowerInfo()
		end
	end
end
function SellFunc()
	if selectedTower and IsOwner then
		local towerBeingSold = selectedTower
		local soldTower = sellTowerFunction:InvokeServer(selectedTower)
		if soldTower then
			selectedTower = nil
			if spectatingTower == towerBeingSold then
				stopSpectating()
			end
			placedTowers -= 1
			toggleTowerInfo()
		end
	end
end
function TargetFunc()
	if selectedTower and IsOwner then
		local modeChangeSuccess = changeModeFunction:InvokeServer(selectedTower)
		if modeChangeSuccess then
			toggleTowerInfo()
		end
	end
end
function SpectateFunc()
	if spectatingTower then
		stopSpectating()
		return
	end

	if IsOwner and selectedTower then
		startSpectating(selectedTower)
	end
end

function PreviewTowerFunc()
	previewDebug(
		"PreviewTowerFunc:start",
		"selectedTower=",
		selectedTower and selectedTower:GetFullName() or "nil"
	)

	if not selectedTower then
		previewDebug("PreviewTowerFunc:abort", "selectedTower=nil")
		return
	end

	local unitStats = upgradesModule[selectedTower.Name]
	if not unitStats then
		previewDebug("PreviewTowerFunc:abort", "unitStats=nil", "tower=", selectedTower.Name)
		return
	end

	local previewSource = createTowerPreviewSource(selectedTower)
	if not previewSource then
		previewDebug("PreviewTowerFunc:abort", "previewSource=nil", "tower=", selectedTower.Name)
		return
	end

	local success, err = pcall(function()
		previewDebug("PreviewTowerFunc:launch", "tower=", selectedTower.Name)
		ViewModule.Hatch({unitStats, previewSource, function()
			previewDebug("PreviewTowerFunc:resume-callback", "tower=", previewSource.Name)
			previewSource:Destroy()
		end})
	end)

	if not success then
		previewSource:Destroy()
		previewDebug("PreviewTowerFunc:error", "tower=", selectedTower.Name, "error=", err)
		warn("Falha ao abrir preview da torre:", selectedTower.Name, err)
	else
		previewDebug("PreviewTowerFunc:success", "tower=", selectedTower.Name)
	end
end

function resolveSpectateButtons()
	local buttons = {}
	local seenButtons = {}

	local function addButton(candidate, label)
		local resolvedButton = getClickTarget(nil, candidate)
		if not resolvedButton or not resolvedButton:IsA("GuiButton") then
			previewDebug("resolveSpectateButtons:missing", label)
			return
		end

		if seenButtons[resolvedButton] then
			return
		end

		seenButtons[resolvedButton] = true
		table.insert(buttons, {
			button = resolvedButton,
			label = label,
		})
	end

	local leftSection = getScoutLeftSection()
	local previewFrame = leftSection and leftSection:FindFirstChild("PreviewFrame")
	addButton(previewFrame and previewFrame:FindFirstChild("Spectate"), "NewUI.Scout.Leftsection.PreviewFrame.Spectate")

	return buttons
end

function bindPreviewSpectateButtons()
	for _, data in resolveSpectateButtons() do
		local button = data.button
		if button:GetAttribute("PreviewSpectateBound") then
			continue
		end

		button:SetAttribute("PreviewSpectateBound", true)
		local lastTriggerAt = 0
		local function onTriggered(source)
			local now = os.clock()
			if now - lastTriggerAt < 0.15 then
				return
			end

			lastTriggerAt = now
			previewDebug(
				"SpectateButton:triggered",
				"label=",
				data.label,
				"source=",
				source,
				"button=",
				button:GetFullName(),
				"selectedTower=",
				selectedTower and selectedTower:GetFullName() or "nil"
			)
			PreviewTowerFunc()
		end

		button.Activated:Connect(function()
			onTriggered("Activated")
		end)
		button.MouseButton1Click:Connect(function()
			onTriggered("MouseButton1Click")
		end)

		previewDebug("SpectateButton:bound", "label=", data.label, "button=", button:GetFullName())
	end
end
local KeyBinds = {
	F = UpgradeFunc,
	X = SellFunc,
	R = TargetFunc,
	V = SpectateFunc,
	ButtonY = UpgradeFunc,
	DPadLeft = TargetFunc,
	DPadRight = SellFunc
}
setPlacementVFXEnabled = function(tower: Model, state)
	if not tower then
		return
	end

	if tower:GetAttribute("PlacementVFXState") == state then
		return
	end

	tower:SetAttribute("PlacementVFXState", state)
	PlacementDebug.log("setPlacementVFXEnabled", "tower=", tower.Name, "state=", state, "pivot=", PlacementDebug.formatCFrame(tower:GetPivot()))

	local fillColor = if state then VALID_PLACEMENT_COLOR else INVALID_PLACEMENT_COLOR
	local outlineColor = if state then VALID_PLACEMENT_OUTLINE else INVALID_PLACEMENT_OUTLINE
	local colorSequence = buildPlacementColorSequence(fillColor, outlineColor)

	local highlight = getOrCreatePlacementHighlight(tower)
	highlight.FillColor = fillColor
	highlight.OutlineColor = outlineColor

	local placementParticles = tower:FindFirstChild("PlacementParticles", true)
	if placementParticles then
		local outlineEmitter = placementParticles:FindFirstChild("Outline")
		if outlineEmitter and outlineEmitter:IsA("ParticleEmitter") then
			outlineEmitter.Color = colorSequence
		end

		local rippleEmitter = placementParticles:FindFirstChild("RIPPLE")
		if rippleEmitter and rippleEmitter:IsA("ParticleEmitter") then
			rippleEmitter.Color = colorSequence
		end
	end

	for _, descendant in workspace.CurrentCamera:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = fillColor
		end
	end
	local rangeCircle = tower:FindFirstChild("Range")
	if rangeCircle and rangeCircle:IsA("BasePart") then
		rangeCircle.Color = fillColor
	end
end
function createHoverHighlight()
	local tower = resolveTowerFromInstance(hoveredInstance)
	if not canSelectTower(tower) then
		return
	end

	lastHighlight = Instance.new("Highlight")
	lastHighlight.FillTransparency = 1
	lastHighlight.OutlineTransparency = 1
	lastHighlight.Parent = tower
	TweenService:Create(lastHighlight, TweenInfo.new(1, Enum.EasingStyle.Exponential), {OutlineTransparency = 0.25}):Play()

	local config = tower:FindFirstChild("Config")
	local typeValue = config and config:FindFirstChild("Type")
	if typeValue and typeValue.Value == "Spawner" then
		for i, v in workspace:WaitForChild("Spawnables"):GetChildren() do
			if v:IsA("Model") then
				local ownedBy = v:FindFirstChild("OwnedBy")
				if ownedBy and ownedBy.Value == tower then
					local tempHighlight = Instance.new("Highlight")
					tempHighlight.FillTransparency = 1
					tempHighlight.OutlineTransparency = 1
					tempHighlight.Parent = v
					TweenService:Create(tempHighlight, TweenInfo.new(1, Enum.EasingStyle.Exponential), {OutlineTransparency = 0.25}):Play()
					lastHighlight:GetPropertyChangedSignal("Parent"):Once(function()
						tempHighlight:Destroy()
					end)
				end
			end
		end
	end
end
function onKeyBindPress(input, processed)
	if processed then return end
	if not Upgrade.Visible and input.KeyCode ~= Enum.KeyCode.V then return end
	for key, action in KeyBinds do
		if input.KeyCode == Enum.KeyCode[key] then
			action()
		end
	end
end
local updateWaveDisplays
local getActiveEndScreen
local showEndScreen
local setupEndScreen
local DisplayEndScreen

do
	function disconnectEndScreenConnections()
		for i = 1, #endScreenConnections do
			endScreenConnections[i]:Disconnect()
		end
		table.clear(endScreenConnections)
	end
	function hideAllEndScreens()
		FailedScreen.Visible = false
		VictoryScreen.Visible = false
		activeEndScreen = nil
	end
	function closeEndScreen(screen)
		endScreenDisplayToken += 1
		if workspace.CurrentCamera:FindFirstChild("Blur") then
			workspace.CurrentCamera.Blur:Destroy()
		end
		if screen and screen:IsA("GuiObject") then
			screen.Visible = false
		end
		hideAllEndScreens()
		EndScreenGUIDisable(true)
	end
	function getNumberFromSources(sources, names)
		for _, source in sources do
			if source then
				for _, name in names do
					local attr = source:GetAttribute(name)
					if typeof(attr) == "number" then
						return attr
					end
					local child = source:FindFirstChild(name)
					if child and child:IsA("ValueBase") and typeof(child.Value) == "number" then
						return child.Value
					end
				end
			end
		end
		return 0
	end
	function getEndScreenTitle()
		local worldValue = StoryModeStats.Worlds[info.World.Value]
		if info.Raid.Value then
			worldValue = info.WorldString.Value
		end
		if worldValue and worldValue ~= "" then
			return worldValue
		end
		if info:FindFirstChild("WorldString") and info.WorldString.Value ~= "" then
			return info.WorldString.Value
		end
		return "Destroyed Kamino"
	end
	function normalizeEndScreenDifficultyLabel(label)
		if type(label) ~= "string" then
			return nil
		end

		local trimmed = label:match("^%s*(.-)%s*$")
		if not trimmed or trimmed == "" then
			return nil
		end

		local lower = string.lower(trimmed)
		if lower == "hellfire" or lower == "hell fire" then
			return "Hell Fire"
		elseif lower == "hard" then
			return "Hard"
		elseif lower == "normal" then
			return "Normal"
		elseif lower == "raid" then
			return "Raid"
		elseif lower == "event" then
			return "Event"
		end

		return trimmed
	end
	function resolveEndScreenDifficultyLabel()
		local difficultyValue = info:FindFirstChild("Difficulty") and info.Difficulty.Value or ""
		local normalizedDifficulty = normalizeEndScreenDifficultyLabel(difficultyValue)
		if normalizedDifficulty then
			return normalizedDifficulty
		end

		if info.ChallengeNumber.Value > 0 then
			local challengeData = ChallengeModule.Data[info.ChallengeNumber.Value]
			return challengeData and challengeData.Name or "Challenge"
		end

		if info.Event.Value then
			return "Event"
		end

		if info.Raid.Value then
			return "Raid"
		end

		if info.Infinity.Value then
			return "Hard"
		end

		if info.Mode.Value == 3 then
			return "Hell Fire"
		elseif info.Mode.Value == 2 then
			return "Hard"
		end

		return "Normal"
	end
	function getEndScreenActText()
		if info.Infinity.Value then
			return "Infinity / " .. resolveEndScreenDifficultyLabel()
		end

		return "Act " .. info.Level.Value .. " / " .. resolveEndScreenDifficultyLabel()
	end
	function updateWaveDisplays(currentWave)
		local waveText = "Wave " .. tostring(currentWave)
		local waveLabel = IngameHud.Top:FindFirstChild("WaveLabel")
		if waveLabel then
			waveLabel.Text = waveText
			waveLabel.Visible = true
		end
		local versusHealth = IngameHud.Top:FindFirstChild("VersusHealth")
		if versusHealth and versusHealth:FindFirstChild("Wave") then
			versusHealth.Wave.Text = waveText
			versusHealth.Wave.Visible = true
		end
		local textWave = IngameHud.Top:FindFirstChild("TextWave")
		if textWave then
			textWave.Text = waveText
			textWave.Visible = true
		end
	end
	function getResultScreen(status)
		local isVictory = info.Victory.Value or status == "VICTORY"
		if info.Versus.Value and player.Team then
			isVictory = player.Team.Name == info.WinningTeam.Value
		end
		return if isVictory then VictoryScreen else FailedScreen, isVictory
	end
	function getActiveEndScreen()
		if activeEndScreen then
			return activeEndScreen
		end
		return if info.Victory.Value then VictoryScreen else FailedScreen
	end
	function setEndScreenDetail(slot, labelText, amountText)
		if not slot then return end
		local textLabel = slot:FindFirstChild("Text")
		local amountLabel = slot:FindFirstChild("Amount")
		if textLabel and textLabel:IsA("TextLabel") then
			textLabel.Text = labelText
		end
		if amountLabel and amountLabel:IsA("TextLabel") then
			amountLabel.Text = amountText
		end
	end
	function setEndScreenButtonText(buttonFrame, value)
		if not buttonFrame then return end
		local textLabel = buttonFrame:FindFirstChild("Text")
		if textLabel and textLabel:IsA("TextLabel") then
			textLabel.Text = value
		end
	end
	function setEndScreenButtonVisible(buttonFrame, value)
		if not buttonFrame then return end
		if buttonFrame:IsA("GuiObject") then
			buttonFrame.Visible = value
		end
	end
	function connectEndScreenButton(buttonFrame, callback)
		if not buttonFrame then return end
		local button = buttonFrame:FindFirstChild("Btn")
		if button and button:IsA("GuiButton") then
			endScreenConnections[#endScreenConnections + 1] = button.Activated:Connect(callback)
		elseif buttonFrame:IsA("GuiButton") then
			endScreenConnections[#endScreenConnections + 1] = buttonFrame.Activated:Connect(callback)
		end
	end
	function bindPersistentEndScreenClose(screen)
		if not screen then
			return
		end

		local closeButton = screen:FindFirstChild("Closebtn")
		if not closeButton then
			return
		end

		local targetButton = (closeButton:IsA("GuiButton") and closeButton)
			or closeButton:FindFirstChild("Btn")
			or closeButton:FindFirstChildWhichIsA("GuiButton", true)

		if not targetButton or not targetButton:IsA("GuiButton") then
			return
		end

		if targetButton:GetAttribute("PersistentCloseBound") then
			return
		end

		targetButton:SetAttribute("PersistentCloseBound", true)
		targetButton.Activated:Connect(function()
			closeEndScreen(screen)
		end)
	end
	function createFlatNumberSequence(value)
		return NumberSequence.new({
			NumberSequenceKeypoint.new(0, value),
			NumberSequenceKeypoint.new(1, value)
		})
	end
	function tweenGradientTransparency(gradient, fromValue, toValue, duration)
		if not gradient or not gradient:IsA("UIGradient") then
			return
		end
		local proxy = Instance.new("NumberValue")
		local connection
		gradient.Transparency = createFlatNumberSequence(fromValue)
		connection = proxy:GetPropertyChangedSignal("Value"):Connect(function()
			gradient.Transparency = createFlatNumberSequence(proxy.Value)
		end)
		proxy.Value = fromValue
		local tween = TweenService:Create(proxy, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Value = toValue
		})
		tween.Completed:Once(function()
			if connection then
				connection:Disconnect()
			end
			proxy:Destroy()
			gradient.Transparency = createFlatNumberSequence(toValue)
		end)
		tween:Play()
	end
	function getRewardSlots(screen)
		local rewardsFrame = screen.Main.Content:FindFirstChild("Rewards")
		if not rewardsFrame then
			return nil, {}
		end
		local slotsFolder = rewardsFrame:FindFirstChild("Slots")
		if not slotsFolder then
			return rewardsFrame, {}
		end
		local slots = {}
		for _, child in slotsFolder:GetChildren() do
			if child:IsA("GuiObject") and tonumber(child.Name) then
				slots[#slots + 1] = child
			end
		end
		table.sort(slots, function(a, b)
			return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
		end)
		return rewardsFrame, slots
	end
	function getProgressSlots(screen)
		local progressFrame = screen.Main.Content:FindFirstChild("Progress")
		if not progressFrame then
			return nil, {}
		end
		local content = progressFrame:FindFirstChild("Content")
		if not content then
			return progressFrame, {}
		end
		local slots = {}
		for _, child in content:GetChildren() do
			if child:IsA("GuiObject") and tonumber(child.Name) then
				slots[#slots + 1] = child
			end
		end
		table.sort(slots, function(a, b)
			return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
		end)
		return progressFrame, slots
	end
	function applyGradientSequence(target, colorSequence)
		if not target or not colorSequence then
			return
		end
		local gradient = target:FindFirstChild("UIGradient")
		if gradient and gradient:IsA("UIGradient") then
			gradient.Color = colorSequence
		end
		local stroke = target:FindFirstChildWhichIsA("UIStroke")
		if stroke then
			local strokeGradient = stroke:FindFirstChild("UIGradient")
			if strokeGradient and strokeGradient:IsA("UIGradient") then
				strokeGradient.Color = colorSequence
			else
				stroke.Color = colorSequence.Keypoints[1].Value
			end
		end
	end
	function applyCardRarity(card, rarity)
		local gradientObject = rarity and UnitGradients:FindFirstChild(rarity)
		if not gradientObject then
			return
		end
		applyGradientSequence(card, gradientObject.Color)
		local bg = card:FindFirstChild("Bg")
		if bg then
			applyGradientSequence(bg, gradientObject.Color)
		end
		local profile = card:FindFirstChild("Profile")
		if profile then
			local profileBg = profile:FindFirstChild("Bg")
			local profileShadow = profile:FindFirstChild("Shadow")
			if profileBg then
				applyGradientSequence(profileBg, gradientObject.Color)
			end
			if profileShadow then
				applyGradientSequence(profileShadow, gradientObject.Color)
			end
		end
		local bar = card:FindFirstChild("Bar")
		if bar then
			local fill = bar:FindFirstChild("Fill")
			if fill then
				applyGradientSequence(fill, gradientObject.Color)
			end
		end
	end
	function getTableField(tbl, names)
		if type(tbl) ~= "table" then
			return nil
		end
		for _, name in names do
			local value = tbl[name]
			if value ~= nil then
				return value
			end
		end
		return nil
	end
	function getTableNumber(tbl, names)
		local value = getTableField(tbl, names)
		if type(value) == "number" then
			return value
		end
		return nil
	end
	function getTableString(tbl, names)
		local value = getTableField(tbl, names)
		if type(value) == "string" then
			return value
		end
		return nil
	end
	function getTableBoolean(tbl, names)
		local value = getTableField(tbl, names)
		if type(value) == "boolean" then
			return value
		end
		return nil
	end
	function getValueFromInstance(source, names)
		if not source or typeof(source) ~= "Instance" then
			return nil
		end
		for _, name in names do
			local attr = source:GetAttribute(name)
			if attr ~= nil then
				return attr
			end
			local child = source:FindFirstChild(name)
			if child and child:IsA("ValueBase") then
				return child.Value
			end
		end
		return nil
	end
	function getNumberFromInstance(source, names)
		local value = getValueFromInstance(source, names)
		if type(value) == "number" then
			return value
		end
		return nil
	end
	function getBooleanFromInstance(source, names)
		local value = getValueFromInstance(source, names)
		if type(value) == "boolean" then
			return value
		end
		return nil
	end
	function getStringFromInstance(source, names)
		local value = getValueFromInstance(source, names)
		if type(value) == "string" then
			return value
		end
		return nil
	end
	function findOwnedTowerByName(towerName)
		if not towerName or towerName == "" then
			return nil
		end
		for _, ownedTower in player.OwnedTowers:GetChildren() do
			if ownedTower.Name == towerName then
				return ownedTower
			end
		end
		return nil
	end
	function getRewardItemImage(itemStats)
		if type(itemStats) ~= "table" then
			return nil
		end
		for _, fieldName in {"Image", "ImageId", "ImageID", "Icon", "IconId", "IconID", "AssetId", "AssetID"} do
			local value = itemStats[fieldName]
			if type(value) == "number" then
				return "rbxassetid://" .. tostring(value)
			elseif type(value) == "string" then
				if string.find(value, "rbxassetid://") then
					return value
				end
				if tonumber(value) then
					return "rbxassetid://" .. value
				end
				return value
			end
		end
		return nil
	end
	function getRewardSlotText(slot)
		local nameLabel = slot:FindFirstChild("Name", true)
		local amountLabel = slot:FindFirstChild("Amount", true) or slot:FindFirstChild("Price", true) or slot:FindFirstChild("Cost", true)
		return nameLabel, amountLabel
	end
	function getRewardSlotVisuals(slot)
		local placeholder = slot:FindFirstChild("Placeholder", true)
		local imageLabel = slot:FindFirstChild("ImageLabel", true)
		return placeholder, imageLabel
	end
	function clearRewardSlot(slot)
		local nameLabel, amountLabel = getRewardSlotText(slot)
		local placeholder, imageLabel = getRewardSlotVisuals(slot)
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = ""
		end
		if amountLabel and amountLabel:IsA("TextLabel") then
			amountLabel.Text = ""
		end
		if placeholder then
			for _, child in placeholder:GetChildren() do
				if child:IsA("ViewportFrame") then
					child:Destroy()
				end
			end
		end
		if imageLabel and imageLabel:IsA("ImageLabel") then
			imageLabel.Image = ""
			imageLabel.Visible = false
		end
		slot.Visible = false
	end
	function buildRewardEntries(rewards)
		local entries = {}
		if not rewards then
			return entries
		end
		if rewards.OwnedTowers then
			for _, tower in rewards.OwnedTowers do
				local towerStats = upgradesModule[tower.Name]
				local baseCost = 0
				if towerStats and towerStats.Upgrades and towerStats.Upgrades[1] then
					baseCost = towerStats.Upgrades[1].Price
				end
				entries[#entries + 1] = {
					kind = "Tower",
					name = tower.Name,
					secondaryText = "$" .. tostring(baseCost),
					rarity = getUnitRarity(tower.Name),
					shiny = tower:GetAttribute("Shiny") == true
				}
			end
		end
		if rewards.Tower and rewards.Tower.unit then
			local tower = rewards.Tower.unit
			local towerStats = upgradesModule[tower.Name]
			local baseCost = 0
			if towerStats and towerStats.Upgrades and towerStats.Upgrades[1] then
				baseCost = towerStats.Upgrades[1].Price
			end
			entries[#entries + 1] = {
				kind = "Tower",
				name = tower.Name,
				secondaryText = "$" .. tostring(baseCost),
				rarity = getUnitRarity(tower.Name),
				shiny = tower:GetAttribute("Shiny") == true
			}
		end
		if rewards.Items then
			for itemName, quantity in rewards.Items do
				if quantity > 0 then
					local itemStats = itemModule[itemName]
					local rarity = if itemStats and itemStats.Rarity then itemStats.Rarity else nil
					entries[#entries + 1] = {
						kind = "Item",
						name = itemName,
						secondaryText = "x" .. tostring(quantity),
						rarity = rarity,
						image = getRewardItemImage(itemStats)
					}
				end
			end
		end
		for rewardName, amount in rewards do
			if rewardName ~= "Items" and rewardName ~= "OwnedTowers" and rewardName ~= "Tower" and rewardName ~= "CompReward" and rewardName ~= "TowerXP" and rewardName ~= "TowerExp" and rewardName ~= "UnitXP" and rewardName ~= "UnitExp" and rewardName ~= "XPProgress" and rewardName ~= "PlacedTowerXP" and rewardName ~= "PlacedUnitXP" and rewardName ~= "Progress" and rewardName ~= "PlayerXP" and rewardName ~= "PlayerExp" and rewardName ~= "XP" and rewardName ~= "Exp" and rewardName ~= "Experience" then
				if type(amount) == "number" and amount > 0 then
					entries[#entries + 1] = {
						kind = "Currency",
						name = rewardName,
						secondaryText = "x" .. tostring(amount)
					}
				end
			end
		end
		return entries
	end
	function normalizeProgressEntry(rawEntry, fallbackName)
		local tower = nil
		if typeof(rawEntry) == "Instance" then
			tower = rawEntry
		elseif type(rawEntry) == "table" then
			for _, fieldName in {"Tower", "Unit", "TowerInstance", "UnitInstance", "OwnedTower", "Instance", "Object"} do
				local candidate = rawEntry[fieldName]
				if typeof(candidate) == "Instance" then
					tower = candidate
					break
				end
			end
		end
		local towerName = fallbackName
		if not towerName and type(rawEntry) == "table" then
			towerName = getTableString(rawEntry, {"TowerName", "UnitName", "Name", "Class"})
		end
		if not towerName and tower then
			towerName = tower.Name
		end
		if not towerName or towerName == "" then
			return nil
		end
		local ownedTower = tower or findOwnedTowerByName(towerName)
		local rarity = if type(rawEntry) == "table" then getTableString(rawEntry, {"Rarity"}) else nil
		local gainedXP = if type(rawEntry) == "table" then getTableNumber(rawEntry, {"GainedXP", "RewardedXP", "AddedXP", "XP", "Exp", "Amount"}) else nil
		local currentLevel = if type(rawEntry) == "table" then getTableNumber(rawEntry, {"Level", "TowerLevel", "CurrentLevel"}) else nil
		local currentXP = if type(rawEntry) == "table" then getTableNumber(rawEntry, {"CurrentXP", "CurrentExp", "XPNow", "ExpNow"}) else nil
		local requiredXP = if type(rawEntry) == "table" then getTableNumber(rawEntry, {"RequiredXP", "NeededXP", "NextLevelXP", "MaxXP", "GoalXP"}) else nil
		local shiny = if type(rawEntry) == "table" then getTableBoolean(rawEntry, {"Shiny"}) else nil
		if not rarity then
			rarity = getUnitRarity(towerName)
		end
		if currentLevel == nil and ownedTower then
			currentLevel = getNumberFromInstance(ownedTower, {"Level", "TowerLevel", "CurrentLevel"})
		end
		if currentXP == nil and ownedTower then
			currentXP = getNumberFromInstance(ownedTower, {"CurrentXP", "CurrentExp", "XP", "Exp", "Experience"})
		end
		if requiredXP == nil and ownedTower then
			requiredXP = getNumberFromInstance(ownedTower, {"RequiredXP", "NeededXP", "NextLevelXP", "MaxXP"})
		end
		if shiny == nil and ownedTower then
			shiny = getBooleanFromInstance(ownedTower, {"Shiny"})
		end
		if currentLevel == nil then
			currentLevel = 1
		end
		if currentXP == nil then
			currentXP = 0
		end
		if requiredXP == nil or requiredXP <= 0 then
			requiredXP = math.max(currentXP, 1)
		end
		if gainedXP == nil then
			gainedXP = 0
		end
		return {
			name = towerName,
			rarity = rarity or "Common",
			level = currentLevel,
			currentXP = currentXP,
			requiredXP = requiredXP,
			gainedXP = gainedXP,
			shiny = shiny == true
		}
	end
	function appendProgressEntries(source, entries)
		if not source then
			return
		end
		if typeof(source) == "Instance" then
			local normalized = normalizeProgressEntry(source)
			if normalized then
				entries[#entries + 1] = normalized
			end
			return
		end
		if type(source) ~= "table" then
			return
		end
		local singleEntry = normalizeProgressEntry(source)
		if singleEntry and source.Name then
			entries[#entries + 1] = singleEntry
			return
		end
		for key, value in source do
			if typeof(value) == "Instance" or type(value) == "table" then
				local fallbackName = if type(key) == "string" then key else nil
				local normalized = normalizeProgressEntry(value, fallbackName)
				if normalized then
					entries[#entries + 1] = normalized
				end
			elseif type(value) == "number" and type(key) == "string" then
				local normalized = normalizeProgressEntry({
					Name = key,
					GainedXP = value
				})
				if normalized then
					entries[#entries + 1] = normalized
				end
			end
		end
	end
	function getPlayerProgressGainedXP(rewards)
		local gainedXP = nil
		if type(rewards) == "table" then
			gainedXP = getTableNumber(rewards, {"PlayerXP", "PlayerExp", "XP", "Exp", "Experience", "XPGained"})
		end
		if gainedXP == nil then
			local playerXPAttribute = player:GetAttribute("PlayerXP")
			if type(playerXPAttribute) == "number" then
				gainedXP = playerXPAttribute
			end
		end
		if gainedXP == nil then
			gainedXP = 0
		end
		return gainedXP
	end

	function getPlayerProgressImage()
		local success, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if success and type(image) == "string" then
			return image
		end
		return ""
	end

	function getPlayerProgressStartState(currentLevel, currentXP, gainedXP)
		local previousLevel = currentLevel
		local previousXP = currentXP
		local remainingXP = math.max(math.floor(gainedXP or 0), 0)
		while remainingXP > 0 do
			if previousXP >= remainingXP then
				previousXP -= remainingXP
				remainingXP = 0
			elseif previousLevel > 1 then
				remainingXP -= previousXP
				previousLevel -= 1
				local previousRequiredXP = ExpModule.playerExpCalculation(previousLevel)
				if type(previousRequiredXP) ~= "number" or previousRequiredXP < 0 then
					previousRequiredXP = 0
				end
				previousXP = previousRequiredXP
			else
				previousXP = 0
				remainingXP = 0
			end
		end
		return previousLevel, previousXP
	end

	function getProgressBarObjects(slot)
		local barFrame = slot:FindFirstChild("Bar")
		if not barFrame then
			return nil, nil, nil, nil, nil
		end
		local nestedBar = barFrame:FindFirstChild("Bar")
		local targetBar = nil
		local fill = nil
		local textLabel = nil
		local levelGainLabel = nil
		if nestedBar and nestedBar:IsA("GuiObject") then
			fill = nestedBar:FindFirstChild("Fill")
			textLabel = nestedBar:FindFirstChild("Text")
			levelGainLabel = nestedBar:FindFirstChild("Lvl")
			if fill and fill:IsA("GuiObject") then
				targetBar = nestedBar
			end
		end
		if not targetBar then
			fill = barFrame:FindFirstChild("Fill")
			textLabel = barFrame:FindFirstChild("Text")
			levelGainLabel = barFrame:FindFirstChild("Lvl")
			if fill and fill:IsA("GuiObject") then
				targetBar = barFrame
			end
		end
		local gradient = nil
		if fill and fill:IsA("GuiObject") then
			gradient = fill:FindFirstChild("UIGradient")
			if not gradient and targetBar then
				gradient = targetBar:FindFirstChild("UIGradient")
			end
		end
		return barFrame, targetBar, fill, textLabel, levelGainLabel, gradient
	end

	function buildProgressEntries(rewards)
		local playerLevelValue = player:FindFirstChild("PlayerLevel")
		local playerExpValue = player:FindFirstChild("PlayerExp")
		if not playerLevelValue or not playerExpValue then
			return {}
		end
		local currentLevel = playerLevelValue.Value
		local currentXP = playerExpValue.Value
		local requiredXP = ExpModule.playerExpCalculation(currentLevel)
		if type(requiredXP) ~= "number" or requiredXP <= 0 then
			requiredXP = math.max(currentXP, 1)
		end
		local gainedXP = getPlayerProgressGainedXP(rewards)
		local previousLevel = getPlayerProgressStartState(currentLevel, currentXP, gainedXP)
		local levelGain = math.max(currentLevel - previousLevel, 0)
		return {{
			name = if player.DisplayName ~= "" then player.DisplayName else player.Name,
			rarity = "Player XP",
			level = currentLevel,
			currentXP = currentXP,
			requiredXP = requiredXP,
			gainedXP = gainedXP,
			levelGain = levelGain,
			image = getPlayerProgressImage()
		}}
	end

	function clearProgressSlot(slot)
		if not slot then
			return
		end
		local profile = slot:FindFirstChild("Profile")
		if profile then
			if profile:FindFirstChild("Lvl") then
				profile.Lvl.Text = ""
			end
			local imageLabel = profile:FindFirstChild("ImageLabel")
			if imageLabel and imageLabel:IsA("ImageLabel") then
				imageLabel.Image = ""
				imageLabel.Visible = false
			end
		end
		local classLabel = slot:FindFirstChild("Class")
		if classLabel and classLabel:IsA("TextLabel") then
			classLabel.Text = ""
		end
		local rarityLabel = slot:FindFirstChild("Rarity")
		if rarityLabel and rarityLabel:IsA("TextLabel") then
			rarityLabel.Text = ""
		end
		local _, _, fill, textLabel, levelGainLabel, gradient = getProgressBarObjects(slot)
		if textLabel and textLabel:IsA("TextLabel") then
			textLabel.Text = ""
		end
		if levelGainLabel and levelGainLabel:IsA("TextLabel") then
			levelGainLabel.Text = ""
			levelGainLabel.Visible = false
		end
		if fill and fill:IsA("GuiObject") then
			fill.Size = UDim2.fromScale(0, 1)
		end
		if gradient and gradient:IsA("UIGradient") then
			gradient.Transparency = createFlatNumberSequence(1)
		end
		slot.Visible = false
	end

	function animateProgressSlot(slot, entry, order)
		local _, _, fill, _, _, gradient = getProgressBarObjects(slot)
		if not fill or not fill:IsA("GuiObject") then
			return
		end
		local ratio = math.clamp(entry.currentXP / math.max(entry.requiredXP, 1), 0, 1)
		fill.Size = UDim2.fromScale(0, 1)
		if gradient and gradient:IsA("UIGradient") then
			tweenGradientTransparency(gradient, 1, 0, 0.45)
		end
		task.delay(0.08 * (order - 1), function()
			TweenService:Create(fill, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromScale(ratio, 1)
			}):Play()
		end)
	end

	function updateEndScreenProgress(screen, rewards)
		local _, slots = getProgressSlots(screen)
		local entries = buildProgressEntries(rewards)
		for _, slot in slots do
			clearProgressSlot(slot)
		end
		if #entries <= 0 then
			return
		end
		for index = 1, math.min(#slots, #entries) do
			local slot = slots[index]
			local entry = entries[index]
			local profile = slot:FindFirstChild("Profile")
			local classLabel = slot:FindFirstChild("Class")
			local rarityLabel = slot:FindFirstChild("Rarity")
			local _, _, _, textLabel, levelGainLabel = getProgressBarObjects(slot)
			if profile then
				if profile:FindFirstChild("Lvl") then
					profile.Lvl.Text = "Level " .. tostring(entry.level)
				end
				local imageLabel = profile:FindFirstChild("ImageLabel")
				if imageLabel and imageLabel:IsA("ImageLabel") then
					imageLabel.Image = entry.image or ""
					imageLabel.Visible = (entry.image or "") ~= ""
				end
			end
			if classLabel and classLabel:IsA("TextLabel") then
				classLabel.Text = entry.name
			end
			if rarityLabel and rarityLabel:IsA("TextLabel") then
				rarityLabel.Text = entry.rarity
			end
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = "Level " .. tostring(entry.level) .. " (" .. tostring(entry.currentXP) .. "/" .. tostring(entry.requiredXP) .. ")"
			end
			if levelGainLabel and levelGainLabel:IsA("TextLabel") then
				if entry.levelGain > 0 then
					levelGainLabel.Text = "+" .. tostring(entry.levelGain)
					levelGainLabel.Visible = true
				else
					levelGainLabel.Text = ""
					levelGainLabel.Visible = false
				end
			end
			slot.Visible = true
			animateProgressSlot(slot, entry, index)
		end
	end

	function playEndScreenOpenAnimation(screen)

		local main = screen:FindFirstChild("Main")
		local header = screen:FindFirstChild("Header")
		if main then
			local mainScale = main:FindFirstChild("OpenScale")
			if not mainScale then
				mainScale = Instance.new("UIScale")
				mainScale.Name = "OpenScale"
				mainScale.Parent = main
			end
			local mainPosition = main.Position
			mainScale.Scale = 0.9
			main.Position = mainPosition + UDim2.fromScale(0, 0.04)
			TweenService:Create(mainScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1
			}):Play()
			TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = mainPosition
			}):Play()
		end
		if header then
			local headerScale = header:FindFirstChild("OpenScale")
			if not headerScale then
				headerScale = Instance.new("UIScale")
				headerScale.Name = "OpenScale"
				headerScale.Parent = header
			end
			local headerPosition = header.Position
			headerScale.Scale = 0.92
			header.Position = headerPosition + UDim2.fromScale(0, -0.025)
			TweenService:Create(headerScale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1
			}):Play()
			TweenService:Create(header, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = headerPosition
			}):Play()
		end
	end
	function showEndScreen(screen)
		EndScreenGUIDisable(false)
		if workspace.CurrentCamera:FindFirstChild("Blur") then
			workspace.CurrentCamera.Blur:Destroy()
		end
		local blurEffect = Instance.new("BlurEffect")
		blurEffect.Name = "Blur"
		blurEffect.Parent = workspace.CurrentCamera
		blurEffect.Size = 0
		blurEffect.Enabled = true
		TweenService:Create(blurEffect, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = 16
		}):Play()
		screen.Visible = true
		playEndScreenOpenAnimation(screen)
	end
	function setupEndScreen(screen, status, rewards)
		disconnectEndScreenConnections()
		hideAllEndScreens()
		activeEndScreen = screen
		local leftInfo = getEndScreenLeftInfo(screen)
		if leftInfo then
			if leftInfo:FindFirstChild("Title") then
				leftInfo.Title.Text = getEndScreenTitle()
			end
			if leftInfo:FindFirstChild("Act") then
				leftInfo.Act.Text = getEndScreenActText()
			end
			local details = leftInfo:FindFirstChild("Details")
			if details then
				local takedowns = getNumberFromSources({player, info}, {"Takedowns", "TakeDowns", "Kills", "Eliminations"})
				local moneyEarned = getNumberFromSources({player, info}, {"MoneyEarned", "EarnedMoney", "TotalMoneyEarned", "CashEarned"})
				if moneyEarned <= 0 then
					moneyEarned = playerMoney.Value
				end
				setEndScreenDetail(details:FindFirstChild("1"), "Units Placed:", tostring(placedTowers))
				setEndScreenDetail(details:FindFirstChild("2"), "Total Damage:", tostring(player.Damage.Value))
				setEndScreenDetail(details:FindFirstChild("3"), "Play Time:", formatTime(tick() - _G.Timestarted))
				setEndScreenDetail(details:FindFirstChild("4"), "Takedowns:", tostring(takedowns))
				setEndScreenDetail(details:FindFirstChild("5"), "Money Earned:", tostring(moneyEarned))
			end
		end
		local _, rewardSlots = getRewardSlots(screen)
		local rewardEntries = buildRewardEntries(rewards)
		for _, slot in rewardSlots do
			clearRewardSlot(slot)
		end
		for index = 1, math.min(#rewardSlots, #rewardEntries) do
			local slot = rewardSlots[index]
			local entry = rewardEntries[index]
			local nameLabel, amountLabel = getRewardSlotText(slot)
			local placeholder, imageLabel = getRewardSlotVisuals(slot)
			if nameLabel and nameLabel:IsA("TextLabel") then
				nameLabel.Text = entry.name or ""
			end
			if amountLabel and amountLabel:IsA("TextLabel") then
				amountLabel.Text = entry.secondaryText or ""
			end
			if entry.rarity then
				applyCardRarity(slot, entry.rarity)
			end
			if entry.kind == "Tower" and entry.name and placeholder then
				local viewport = ViewPortModule.CreateViewPort(entry.name, entry.shiny == true)
				viewport.Size = UDim2.fromScale(1, 1)
				viewport.Name = entry.name
				viewport.Parent = placeholder
			elseif entry.image and imageLabel and imageLabel:IsA("ImageLabel") then
				imageLabel.Image = tostring(entry.image)
				imageLabel.Visible = true
			end
			slot.Visible = true
		end
		updateEndScreenProgress(screen, rewards)
		local buttons = screen.Main.Content:FindFirstChild("Buttons")
		local nextButton = if buttons then buttons:FindFirstChild("1") else nil
		local replayButton = if buttons then buttons:FindFirstChild("2") else nil
		local lobbyButton = if buttons then buttons:FindFirstChild("3") else nil
		setEndScreenButtonText(nextButton, "Next")
		setEndScreenButtonText(replayButton, "Replay")
		setEndScreenButtonText(lobbyButton, "Back To Lobby")
		local canShowNext = status ~= "GAME OVER" and not info.Event.Value and not info.Versus.Value and info.ChallengeNumber.Value < 0
		local canShowReplay = not info.Versus.Value
		if info.ChallengeNumber.Value > 0 then
			canShowNext = false
			canShowReplay = true
		end
		setEndScreenButtonVisible(nextButton, canShowNext)
		setEndScreenButtonVisible(replayButton, canShowReplay)
		setEndScreenButtonVisible(lobbyButton, true)
		local eventsLocal = ReplicatedStorage:WaitForChild("Events")
		local exitEvent = eventsLocal:WaitForChild("ExitGame")
		local clicked = false
		connectEndScreenButton(lobbyButton, function()
			if clicked then
				return
			end
			clicked = true
			endScreenDisplayToken += 1
			exitEvent:FireServer("Return")
			if workspace.CurrentCamera:FindFirstChild("Blur") then
				workspace.CurrentCamera.Blur:Destroy()
			end
			hideAllEndScreens()
			EndScreenGUIDisable(true)
		end)
		connectEndScreenButton(replayButton, function()
			if clicked then
				return
			end
			clicked = true
			endScreenDisplayToken += 1
			exitEvent:FireServer("Replay")
			if workspace.CurrentCamera:FindFirstChild("Blur") then
				workspace.CurrentCamera.Blur:Destroy()
			end
			hideAllEndScreens()
			EndScreenGUIDisable(true)
		end)
		if canShowNext then
			connectEndScreenButton(nextButton, function()
				if clicked then
					return
				end
				clicked = true
				endScreenDisplayToken += 1
				exitEvent:FireServer("Next")
				if workspace.CurrentCamera:FindFirstChild("Blur") then
					workspace.CurrentCamera.Blur:Destroy()
				end
				hideAllEndScreens()
				EndScreenGUIDisable(true)
			end)
		end
		connectEndScreenButton(screen:FindFirstChild("Closebtn"), function()
			closeEndScreen(screen)
		end)
	end
	function DisplayEndScreen(status)
		endScreenDisplayToken += 1
		local displayToken = endScreenDisplayToken
		local endScreen = getResultScreen(status)
		setupEndScreen(endScreen, status, nil)
		task.wait(1)
		if gui.Parent:FindFirstChild("HatchInfo") then
			task.spawn(function()
				local startedWaiting = os.clock()
				while gui.Parent:FindFirstChild("HatchInfo") and os.clock() - startedWaiting < 12 do
					task.wait(0.2)
				end
				if displayToken == endScreenDisplayToken then
					showEndScreen(endScreen)
				end
			end)
			return
		end
		showEndScreen(endScreen)
	end
end

function SetupGameGui()
	if not info.GameRunning.Value then return end
	task.spawn(function()
		TweenService:Create(SkipUI, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = SKIP_HIDDEN_POSITION}):Play()
		task.wait(0.2)
		SkipUI.Visible = false
	end)
	local map = workspace.Map:FindFirstChildOfClass("Folder") or workspace
	local HealthFrame = IngameHud.Top.HealthBar
	local VersusHealth = IngameHud.Top:FindFirstChild("VersusHealth")
	local SpeedBtn = IngameHud.Top.Speed
	if not info.Versus.Value and not info.Competitive.Value then
		HealthFrame.Visible = true
		SpeedBtn.Visible = true
		if VersusHealth then VersusHealth.Visible = false end
		local BaseHumanoid = map:WaitForChild("Base"):WaitForChild("Humanoid") :: Humanoid
		function updateBaseHealth()
			HealthFrame.TextHealth.Text = "Health: " .. tostring(BaseHumanoid.Health .. "/" .. BaseHumanoid.MaxHealth)
			TweenService:Create(HealthFrame.Fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(math.clamp(BaseHumanoid.Health / BaseHumanoid.MaxHealth, 0, 1), 1)}):Play()
		end
		BaseHumanoid.HealthChanged:Connect(updateBaseHealth)
		BaseHumanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateBaseHealth)
		updateBaseHealth()
	else
		warn("[Game Controller] Awaiting for versus UI to be scripted sir")
		HealthFrame.Visible = false
		SpeedBtn.Visible = false
		if VersusHealth then
			VersusHealth.Visible = true
			local RedBase = map:WaitForChild("RedBase") :: Model
			local BlueBase = map:WaitForChild("BlueBase") :: Model
			local RedHumanoid = RedBase:WaitForChild("Humanoid") :: Humanoid
			local BlueHumanoid = BlueBase:WaitForChild("Humanoid") :: Humanoid
			function updateRedHealth()
				VersusHealth["Red"].Bar.Front.Size = UDim2.fromScale(math.clamp(RedHumanoid.Health / RedHumanoid.MaxHealth, 0, 1), 1)
				VersusHealth["Red"].Bar.NumberDisplay.Text = `Health: {RedHumanoid.Health}/{RedHumanoid.MaxHealth}`
			end
			function updateBlueHealth()
				VersusHealth["Blue"].Bar.Front.Size = UDim2.fromScale(math.clamp(BlueHumanoid.Health / BlueHumanoid.MaxHealth, 0, 1), 1)
				VersusHealth["Blue"].Bar.NumberDisplay.Text = `Health: {BlueHumanoid.Health}/{BlueHumanoid.MaxHealth}`
			end
			RedHumanoid.HealthChanged:Connect(updateRedHealth)
			RedHumanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateRedHealth)
			BlueHumanoid.HealthChanged:Connect(updateBlueHealth)
			BlueHumanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateBlueHealth)
			updateRedHealth()
			updateBlueHealth()
		end
	end
	if workspace.Info.ChallengeNumber.Value == 9 then
		HealthFrame.TextHealth.Text = "Health: 1/100"
		HealthFrame.Fill.Size = UDim2.fromScale(1 / 100, 1)
	end
	UpdatePlayerLevelBar()
	playerMoney.Changed:Connect(function()
		IngameHud.Bottom.AmountMoney.Text = playerMoney.Value .. "$"
	end)
	IngameHud.Bottom.AmountMoney.Text = playerMoney.Value .. "$"
	for Key, _ in KeyBinds do
		for _, button in Upgrade:GetDescendants() do
			if button.Name == "InfoText" then
				if CheckIfPc() then
					button.TextXAlignment = "Left"
				else
					button.TextXAlignment = "Center"
				end
			end
			if button:FindFirstChild(Key) then
				if not CheckIfPc() then
					button[Key].Visible = false
				else
					button[Key].Visible = true
				end
			end
		end
	end
	function stringToKeyCode(keyCodeString)
		local keyCode = Enum.KeyCode[keyCodeString]
		if keyCode then return keyCode end
		return nil
	end
	function setupConsoleButton(consoleButton, imageLabel)
		if consoleButton:GetAttribute("Input") then
			local enumKeyCode = stringToKeyCode(consoleButton:GetAttribute("Input"))
			if not enumKeyCode then return end
			local mappedIcon = UserInputService:GetImageForKeyCode(enumKeyCode)
			if not mappedIcon then return end
			if imageLabel then
				imageLabel.Image = mappedIcon
				imageLabel.Visible = true
			else
				consoleButton.Image = mappedIcon
				if consoleButton:FindFirstChildOfClass("TextLabel") then
					consoleButton:FindFirstChildOfClass("TextLabel").Visible = false
				elseif consoleButton:FindFirstChildWhichIsA("ImageLabel") then
					consoleButton:FindFirstChildOfClass("ImageLabel").Visible = false
				end
			end
		end
	end
	if UserInputService.GamepadEnabled then
		for _, consoleButton in pairs(CollectionService:GetTagged("Controller")) do
			if consoleButton:FindFirstChild("TOOLBAR") then
				consoleButton.TOOLBAR.Visible = false
				local imageLabel = consoleButton:FindFirstChildWhichIsA("ImageLabel")
				if imageLabel then setupConsoleButton(consoleButton, imageLabel) end
			elseif consoleButton:FindFirstChild("DisplayBind") then
				consoleButton.DisplayBind.Visible = false
				local imageLabel = consoleButton:FindFirstChild("Controller")
				if imageLabel then setupConsoleButton(consoleButton, imageLabel) end
			else
				if consoleButton:IsA("ImageLabel") or consoleButton:IsA("ImageButton") then
					setupConsoleButton(consoleButton)
				end
			end
		end
	end
	task.delay(2, function()
		refreshEquippedSlots()
	end)
end
function LoadGui()
	local gameOverd = false
	function handleGameOver(val)
		if val and not gameOverd then
			gameOverd = true
			local change = "GAME OVER"
			if info.Victory.Value then
				change = "VICTORY"
			end
			DisplayEndScreen(change)
		end
	end
	function handleMessage(change)
		if change ~= "" then
			if not string.find(change, "Wave") and not string.find(change, "Waiting") and not gameOverd then
				DisplayEndScreen(change)
			end
		end
	end
	info.GameOver.Changed:Connect(handleGameOver)
	info.Message.Changed:Connect(handleMessage)
	if info.GameOver.Value then
		task.defer(handleGameOver, info.GameOver.Value)
	elseif info.Message.Value ~= "" then
		task.defer(handleMessage, info.Message.Value)
	end
	SetupGameGui()
	info.GameRunning.Changed:Connect(SetupGameGui)
end
-- INIT
repeat task.wait() until player:FindFirstChild("DataLoaded")
local ownedTowersFolder = player:WaitForChild("OwnedTowers")
requestBottomSlotVisibility(false)
bindPersistentEndScreenClose(FailedScreen)
bindPersistentEndScreenClose(VictoryScreen)
for _, ownedTower in ownedTowersFolder:GetChildren() do
	watchOwnedTower(ownedTower)
end
ownedTowersFolder.ChildAdded:Connect(function(ownedTower)
	watchOwnedTower(ownedTower)
	refreshEquippedSlots()
end)
ownedTowersFolder.ChildRemoved:Connect(function(ownedTower)
	disconnectOwnedTowerConnections(ownedTower)
	refreshEquippedSlots()
end)
waitForOwnedTowersToSettle(5, 0.2)
refreshEquippedSlots()
slotUiReady = true
requestBottomSlotVisibility(true)
updateAbilityStatus()
AbilityStatus.Changed:Connect(updateAbilityStatus)
player.PlayerLevel.Changed:Connect(UpdatePlayerLevelBar)
player.PlayerLevel.Changed:Connect(refreshEquippedSlots)
player.PlayerExp.Changed:Connect(UpdatePlayerLevelBar)
updateWaveDisplays(info.Wave.Value)
info.Wave.Changed:Connect(updateWaveDisplays)
HideScoutToolbarsOnMobile()
local scoutButtons = getScoutButtonsSection()
if scoutButtons then
	scoutButtons.Upgrade.Btn.Activated:Connect(UpgradeFunc)
	scoutButtons.Sell.Btn.Activated:Connect(SellFunc)
	scoutButtons.Target.Btn.Activated:Connect(TargetFunc)
else
	warn("Scout UI sem Buttons:", Upgrade:GetFullName())
end
bindPreviewSpectateButtons()
Upgrade.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "TOOLBAR" and descendant:IsA("GuiObject") then
		HideScoutToolbarsOnMobile()
	end
end)
gui.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "Spectate" or descendant.Name == "PreviewFrame" or descendant.Name == "Preview" then
		task.defer(bindPreviewSpectateButtons)
	end
end)
playerguix.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "Spectate" or descendant.Name == "PreviewFrame" or descendant.Name == "Preview" then
		task.defer(bindPreviewSpectateButtons)
	end
end)
UserInputService.InputBegan:Connect(onKeyBindPress)
SkipUI.Button.Yes.Btn.Activated:Connect(function()
	UIHandler.PlaySound("Skip")
	if not SkipUI.Visible then return end

	local skipContext = SkipUI:GetAttribute("InteractionContext")
	if skipContext == "WaveSkip" then
		local result = ReplicatedStorage.Functions.VoteForSkip:InvokeServer("ManualButton")
		if result == true then
			task.spawn(function()
				TweenService:Create(SkipUI, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = SKIP_HIDDEN_POSITION}):Play()
				task.wait(0.2)
				SkipUI.Visible = false
			end)
		elseif typeof(result) == "string" then
			if result == "Cannot skip on the final wave!" then
				task.spawn(function()
					TweenService:Create(SkipUI, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = SKIP_HIDDEN_POSITION}):Play()
					task.wait(0.2)
					SkipUI.Visible = false
				end)
			end
			_G.Message(result, Color3.new(0.831373, 0, 0))
		end
		return
	end

	if skipContext ~= "StartGame" then
		return
	end

	events.Client.VoteStartGame:FireServer()
	task.spawn(function()
		TweenService:Create(SkipUI, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = SKIP_HIDDEN_POSITION}):Play()
		task.wait(0.2)
		SkipUI.Visible = false
	end)
end)
SkipUI.Button.No.Btn.Activated:Connect(function()
	SkipUI:SetAttribute("InteractionContext", nil)
	TweenService:Create(SkipUI, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = SKIP_HIDDEN_POSITION}):Play()
	task.wait(0.2)
	SkipUI.Visible = false
end)
function updateSpeedText()
	if workspace.Info.SpeedCD.Value then
		return
	end

	local gamSped = workspace.Info.GameSpeed
	SpeedButton.TextSpeed.Text = "Speed: " .. gamSped.Value .. "x"
end

local cooldownToken = 0
function startCooldown()
	cooldownToken += 1
	local token = cooldownToken
	SpeedButton.Interactable = false

	local remaining = 3.2
	while workspace.Info.SpeedCD.Value and token == cooldownToken do
		SpeedButton.TextSpeed.Text = string.format("Cooldown: %.1f", math.max(remaining, 0))
		task.wait(0.1)
		remaining -= 0.1
	end

	if token == cooldownToken then
		SpeedButton.Interactable = true
		updateSpeedText()
	end
end

updateSpeedText()
workspace.Info.GameSpeed.Changed:Connect(updateSpeedText)
workspace.Info.SpeedCD.Changed:Connect(function()
	if workspace.Info.SpeedCD.Value then
		task.spawn(startCooldown)
	else
		cooldownToken += 1
		SpeedButton.Interactable = true
		updateSpeedText()
	end
end)

if workspace.Info.SpeedCD.Value then
	task.spawn(startCooldown)
end

SpeedButton.Activated:Connect(function()
	if workspace.Info.SpeedCD.Value == true then
		_G.Message("Please Wait Before Changing Speed!", Color3.fromRGB(255, 0, 0))
		return
	end
	local changeSuccess, failReason = game.ReplicatedStorage.Functions.SpeedRemote:InvokeServer()
	if not changeSuccess then
		_G.Message(failReason, Color3.fromRGB(255, 0, 0))
	end
end)
local function resolveStartDifficultyLabel(modeValue, difficultyValue, isInfinity)
	if type(difficultyValue) == "string" and difficultyValue ~= "" then
		return difficultyValue
	end

	if isInfinity then
		return "Hard"
	end

	if modeValue == 3 then
		return "Hellfire"
	elseif modeValue == 2 then
		return "Hard"
	end

	return "Normal"
end

local function applyStartDifficultyStyle(modeTextLabel, difficultyLabel)
	modeTextLabel.HardGradient.Enabled = false
	modeTextLabel.ChallangeGradient.Enabled = false
	modeTextLabel.NormalGradient.Enabled = false

	if difficultyLabel == "Normal" then
		modeTextLabel.NormalGradient.Enabled = true
	elseif difficultyLabel == "Hard" then
		modeTextLabel.HardGradient.Enabled = true
	else
		modeTextLabel.ChallangeGradient.Enabled = true
	end
end

events.Client.StartGUI.OnClientEvent:Connect(function(Bool, payload)
	local WorldValue = StoryModeStats.Worlds[info.World.Value]
	local levelValue = info.Level.Value
	local modeValue = info.Mode.Value
	local raidValue = info.Raid.Value
	local infinityValue = info.Infinity.Value
	local eventValue = info.Event.Value
	local challengeNumber = info.ChallengeNumber.Value
	local difficultyValue = info:FindFirstChild("Difficulty") and info.Difficulty.Value or ""

	if type(payload) == "table" then
		WorldValue = payload.WorldString ~= "" and payload.WorldString or (payload.World and StoryModeStats.Worlds[payload.World]) or WorldValue
		levelValue = if type(payload.Level) == "number" then payload.Level else levelValue
		modeValue = if type(payload.Mode) == "number" then payload.Mode else modeValue
		raidValue = if type(payload.Raid) == "boolean" then payload.Raid else raidValue
		infinityValue = if type(payload.Infinity) == "boolean" then payload.Infinity else infinityValue
		eventValue = if type(payload.Event) == "boolean" then payload.Event else eventValue
		challengeNumber = if type(payload.ChallengeNumber) == "number" then payload.ChallengeNumber else challengeNumber
		difficultyValue = if type(payload.Difficulty) == "string" then payload.Difficulty else difficultyValue
	elseif info.Raid.Value then
		warn(info.WorldString.Value)
		WorldValue = info.WorldString.Value
	end

	local Frame = script.Parent.Start.StartFrame
	local resolvedDifficulty = resolveStartDifficultyLabel(modeValue, difficultyValue, infinityValue)
	Frame.Visible = true
	if challengeNumber > 0 then
		Frame.InformationFrame.ModeText.Text = ChallengeModule.Data[challengeNumber].Name
		applyStartDifficultyStyle(Frame.InformationFrame.ModeText, "Challenge")
	elseif eventValue then
		warn("Event Textttttt")
		Frame.InformationFrame.ModeText.Text = "Event"
		applyStartDifficultyStyle(Frame.InformationFrame.ModeText, "Event")
	else
		Frame.InformationFrame.ModeText.Text = resolvedDifficulty
		applyStartDifficultyStyle(Frame.InformationFrame.ModeText, resolvedDifficulty)
	end
	if WorldValue then
		Frame.InformationFrame.StoryName.Text = WorldValue
	else
		Frame.InformationFrame.StoryName.Text = "Destroyed Kamino"
	end
	if infinityValue then
		Frame.InformationFrame.ActName.Text = "Infinity Mode"
	elseif raidValue then
		Frame.InformationFrame.ActName.Text = "Act " .. levelValue .. " - " .. RaidModeStats.LevelName[WorldValue][levelValue]
	elseif eventValue then
		Frame.InformationFrame.ActName.Text = "Best Of Luck In Defeating This Foe."
	else
		Frame.InformationFrame.ActName.Text = "Act " .. levelValue .. " - " .. StoryModeStats.LevelName[WorldValue][levelValue]
	end
	TweenService:Create(Frame.InformationFrame.StoryName, TweenInfo.new(0.25, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	TweenService:Create(Frame.InformationFrame.StoryName.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Exponential), {Transparency = 0.18}):Play()
	task.wait(0.5)
	TweenService:Create(Frame.InformationFrame.Separation, TweenInfo.new(0.75, Enum.EasingStyle.Linear), {ImageTransparency = 0}):Play()
	task.wait(0.5)
	TweenService:Create(Frame.InformationFrame.ActName, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	TweenService:Create(Frame.InformationFrame.ActName.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0.18}):Play()
	task.wait(0.5)
	TweenService:Create(Frame.InformationFrame.ModeText, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {TextTransparency = 0}):Play()
	TweenService:Create(Frame.InformationFrame.ModeText.UIStroke, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {Transparency = 0.18}):Play()
	task.wait(4)
	TweenService:Create(Frame.InformationFrame.StoryName, TweenInfo.new(0.85, Enum.EasingStyle.Linear), {TextTransparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.StoryName.UIStroke, TweenInfo.new(0.85, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.Separation, TweenInfo.new(0.85, Enum.EasingStyle.Linear), {ImageTransparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.ActName, TweenInfo.new(0.85, Enum.EasingStyle.Linear), {TextTransparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.ActName.UIStroke, TweenInfo.new(0.85, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.ModeText, TweenInfo.new(0.85, Enum.EasingStyle.Linear), {TextTransparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.ModeText.UIStroke, TweenInfo.new(0.85, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
	task.wait(0.9)
	Frame.Visible = false
end)
local arrowCoroutine = coroutine.create(function()
	local mapFolder = workspace:WaitForChild("Map")
	local mainMap
	while mainMap == nil do
		mainMap = mapFolder:GetChildren()[1]
		task.wait()
	end
	while true do
		for i = 1, 5 do
			local arrow = game.ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Arrow"):Clone()
			arrow.Parent = mainMap
			arrow.ArrowScript.Enabled = true
			task.wait(0.5)
		end
		task.wait(2)
	end
end)
coroutine.resume(arrowCoroutine)
_G.Timestarted = tick()
events.Client.VoteStartGame.OnClientEvent:Connect(function(secondsLeft, YesVote, lastCall, UpdatedArgument)
	if UpdatedArgument then
		SkipUI:SetAttribute("InteractionContext", "StartGame")
		SkipUI.Position = SKIP_CENTER_POSITION
		SkipUI.Visible = true
		return
	end
	if lastCall then
		coroutine.close(arrowCoroutine)
		_G.Message("Game has started!", Color3.fromRGB(255, 170, 0), nil, true)
		UIHandler.PlaySound("WaveComplete")
		SkipUI:SetAttribute("InteractionContext", nil)
		task.spawn(function()
			TweenService:Create(SkipUI, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = SKIP_HIDDEN_POSITION}):Play()
			task.wait(0.2)
			SkipUI.Visible = false
		end)
	end
end)
if not info.Versus.Value and not info.Competitive.Value then
	task.spawn(function()
		for i, v in game.Workspace.Mobs:GetChildren() do
			health.Setup(v)
		end
	end)
	workspace.Mobs.ChildAdded:Connect(function(mob)
		health.Setup(mob)
	end)
else
	task.spawn(function()
		for i, v in workspace:WaitForChild("RedMobs"):GetChildren() do health.Setup(v) end
		for i, v in workspace:WaitForChild("BlueMobs"):GetChildren() do health.Setup(v) end
	end)
	workspace:WaitForChild("RedMobs").ChildAdded:Connect(function(mob) health.Setup(mob) end)
	workspace:WaitForChild("BlueMobs").ChildAdded:Connect(function(mob) health.Setup(mob) end)
end
function InputBegan(input, processed)
	if processed then
		if towerToSpawn then
			PlacementDebug.log("InputBegan:ignored-processed", "inputType=", tostring(input.UserInputType), "keyCode=", tostring(input.KeyCode), "tower=", towerToSpawn.Name, "canPlace=", canPlace)
		end
		return
	end
	if player:GetAttribute("PossessingTower") ~= nil then
		if towerToSpawn then
			PlacementDebug.log("InputBegan:ignored-possessing", "inputType=", tostring(input.UserInputType), "keyCode=", tostring(input.KeyCode), "tower=", towerToSpawn.Name)
		end
		return
	end
	if towerToSpawn then
		PlacementDebug.log("InputBegan:placing", "inputType=", tostring(input.UserInputType), "keyCode=", tostring(input.KeyCode), "tower=", towerToSpawn.Name, "canPlace=", canPlace, "cframe=", PlacementDebug.formatCFrame(towerToSpawn:GetPivot()))
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonX then
			SpawnNewTower()
		elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then
			rotation += 90
			PlacementDebug.log("InputBegan:rotate", "tower=", towerToSpawn.Name, "rotation=", rotation)
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then
			RemovePlaceholderTower()
		end
	elseif hoveredInstance and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonX) then
		local model = resolveTowerFromInstance(hoveredInstance)
		if canSelectTower(model) then
			if model == selectedTower then
				selectedTower = nil
			else
				selectedTower = model
			end
		else
			selectedTower = nil
		end
		toggleTowerInfo()
	end
	local keys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six}
	for i, v in keys do
		if input.KeyCode == v then
			local towerselected = SelectedTowers[i]
			if towerselected == nil then continue end
			local tower = GetUnitModel[towerselected.Name]
			if tower == nil then continue end
			local allowedToSpawn = true
			PlacementDebug.log("InputBegan:slot-key", "slot=", i, "tower=", towerselected.Name, "unitValue=", PlacementDebug.getInstancePath(towerselected), "allowedLocal=", allowedToSpawn)
			if allowedToSpawn then
				towerToSpawnValue = towerselected
				AddPlaceholderTower(tower.Name, towerselected)
			end
		end
	end
end
UserInputService.InputBegan:Connect(InputBegan)
script.Parent.PhoneControls.Place.TouchTap:Connect(function()
	InputBegan({UserInputType = Enum.UserInputType.MouseButton1})
end)
script.Parent.PhoneControls.Rotate.TouchTap:Connect(function()
	InputBegan({KeyCode = Enum.KeyCode.R})
end)
script.Parent.PhoneControls.Cancel.TouchTap:Connect(function()
	InputBegan({KeyCode = Enum.KeyCode.Q})
end)
RunService.Heartbeat:Connect(function()
	local MousePos = game:GetService("UserInputService"):GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
	local getGUI = player:WaitForChild("PlayerGui"):GetGuiObjectsAtPosition(MousePos.X, MousePos.Y)
	local result = MouseRaycast(towerToSpawn)
	local usedLastValidResult = false
	for _, ui in getGUI do
		if ui:IsA("GuiButton") then
			result = lastValidResult
			usedLastValidResult = true
			break
		end
	end
	if result and result.Instance then
		lastValidResult = result
		if towerToSpawn then
			hoveredInstance = nil
			if lastHighlight then
				lastHighlight:Destroy()
				lastHighlight = nil
			end
			canPlace = isPlacementResultValid(result, towerToSpawn)
			setPlacementVFXEnabled(towerToSpawn, canPlace)
			local height = towerToSpawn:WaitForChild("HumanoidRootPart").Size.Y * 1.5
			local x = result.Position.X
			local y = result.Position.Y + height
			local z = result.Position.Z
			local cframe = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rotation), 0)
			towerToSpawn:SetPrimaryPartCFrame(cframe)
			if towerToSpawn:FindFirstChild("VFXTowerBasePart", true) then
				towerToSpawn:FindFirstChild("VFXTowerBasePart", true).CFrame = cframe
			end
			PlacementDebug.state(usedLastValidResult and "Heartbeat:placement-using-last-result-over-gui" or "Heartbeat:placement-raycast", result, towerToSpawn, cframe)
		else
			local hoveredTower = resolveTowerFromInstance(result.Instance)
			if canSelectTower(hoveredTower) then
				hoveredInstance = hoveredTower
				prepareTowerSelectionParts(hoveredTower)
				if not lastHighlight then
					createHoverHighlight()
				elseif lastHighlight.Parent ~= hoveredTower then
					lastHighlight:Destroy()
					lastHighlight = nil
					createHoverHighlight()
				end
			else
				hoveredInstance = nil
				if lastHighlight then
					lastHighlight:Destroy()
					lastHighlight = nil
				end
			end
		end
	else
		if towerToSpawn then
			PlacementDebug.state("Heartbeat:no-raycast-result", nil, towerToSpawn, towerToSpawn:GetPivot())
		end
		hoveredInstance = nil
		if lastHighlight then
			lastHighlight:Destroy()
			lastHighlight = nil
		end
	end
end)
ReplicatedStorage.Events.Client.Timer.OnClientEvent:Connect(function(round, restTime)
	waveTimerToken += 1
	local thisTimerToken = waveTimerToken
	local gameSpeed = workspace.Info.GameSpeed.Value
	if round ~= 1 then
		_G.Message("Wave Completed!", Color3.fromRGB(255, 170, 0), nil, true)
		UIHandler.PlaySound("WaveComplete")
	end
	updateWaveDisplays(round)
	IngameHud.Top.TextWave.Visible = true
	for _ = restTime, 1, -1 do
		if thisTimerToken ~= waveTimerToken then
			return
		end
		IngameHud.Top.TextWave.Text = "Wave " .. round
		TweenService:Create(IngameHud.Top.TextWave, TweenInfo.new(0.25 / gameSpeed, Enum.EasingStyle.Exponential), {TextColor3 = Color3.new(1, 0, 0)}):Play()
		task.wait(0.25 / gameSpeed)
		if thisTimerToken ~= waveTimerToken then
			return
		end
		TweenService:Create(IngameHud.Top.TextWave, TweenInfo.new(0.25 / gameSpeed, Enum.EasingStyle.Exponential), {TextColor3 = Color3.new(1, 1, 1)}):Play()
		task.wait(0.75 / gameSpeed)
	end
	if thisTimerToken ~= waveTimerToken then
		return
	end
	IngameHud.Top.TextWave.Visible = true
	updateWaveDisplays(round)
	_G.Message("Wave " .. round .. " Begins!", Color3.fromRGB(255, 170, 0), nil, true)
	UIHandler.PlaySound("WaveStart")
	if round == info.MaxWaves.Value and not info.Versus.Value then
		task.delay(1 / gameSpeed, function()
			_G.Message("FINAL WAVE!", Color3.fromRGB(255, 170, 0), nil, true)
			UIHandler.PlaySound("WaveStart")
		end)
	end
end)
events.Client.Teleporting.OnClientEvent:Connect(function(...)
	TeleportService:SetTeleportGui(UIMapLoadingScreenModule.CreateLoadingGui(...))
end)
ReplicatedStorage.Events.Client.ReceiveRewards.OnClientEvent:Connect(function(rewards, dontShowGui, isFirstTime)
	if type(rewards) ~= "table" then
		rewards = {}
	end
	task.spawn(function()
		local infoLocal = workspace:FindFirstChild("Info")
		if not infoLocal then return end
		local unit = infoLocal:FindFirstChild("DisplayingUnit")
		if unit and unit.Value then
			task.delay(7, function()
				local delayedUnit = workspace:FindFirstChild("Info") and workspace.Info:FindFirstChild("DisplayingUnit")
				if delayedUnit then delayedUnit.Value = false end
			end)
			repeat task.wait(0.1) until not (unit and unit.Value)
		end
	end)
	local EndScreen = getActiveEndScreen()
	local status = if info.Victory.Value then "VICTORY" else "GAME OVER"
	setupEndScreen(EndScreen, status, rewards)
	function EndScreenGUIDisableLocal(value)
		EndScreenGUIDisable(value)
	end
	if not dontShowGui then
		showEndScreen(EndScreen)
	end
	local RewardsFrame = EndScreen.Main.Content:FindFirstChild("Rewards")
	local isHidden = true
	local rewardsDisplaySuccess, rewardsDisplayError = pcall(function()
		for reward, amount in rewards do
			if reward == "FriendBonus" then
				if type(amount) == "table" and _G.Message then
					local gemsBonus = amount.Gems or 0
					local xpBonus = amount.PlayerXP or 0
					local messageParts = {}
					if gemsBonus > 0 then
						table.insert(messageParts, "+" .. tostring(gemsBonus) .. " Gems")
					end
					if xpBonus > 0 then
						table.insert(messageParts, "+" .. tostring(xpBonus) .. " XP")
					end
					if #messageParts > 0 then
						_G.Message("Friend Bonus: " .. table.concat(messageParts, " / "), Color3.fromRGB(85, 255, 127))
					end
				end
			elseif reward == "Items" then
				for item, quantity in amount do
					if quantity <= 0 then continue end
					for _ = 1, quantity do
						local nextItem = false
						if isHidden then
							EndScreen.Visible = false
							isHidden = false
						end
						local itemStats = itemModule[item]
						if workspace.CurrentCamera:FindFirstChild("Blur") then
							workspace.CurrentCamera.Blur:Destroy()
						end
						EndScreenGUIDisableLocal(true)
						ViewModule.Item({itemStats, nil, function() nextItem = true end})
						repeat task.wait() until nextItem
					end
				end
			elseif reward == "OwnedTowers" then
				for _, tower in amount do
					local goNext = false
					local success = pcall(function()
						local unitStats = upgradesModule[tower.Name]
						ViewModule.Hatch({unitStats, tower, function() goNext = true end})
					end)
					if not success then goNext = true end
					repeat task.wait() until goNext
				end
			elseif reward == "Tower" then
				local tower = amount.unit
				local goNext = false
				if workspace.CurrentCamera:FindFirstChild("Blur") then
					workspace.CurrentCamera.Blur:Destroy()
				end
				EndScreen.Visible = false
				EndScreenGUIDisableLocal(true)
				local success, err = pcall(function()
					local unitStats = upgradesModule[tower.Name]
					ViewModule.Hatch({unitStats, tower, function() goNext = true end})
				end)
				if not success then
					warn(err)
					goNext = true
				end
				repeat task.wait() until goNext
				_G.Message("A mysterious unit has been added to your collection", Color3.fromRGB(255, 46, 46), "Mystery")
			elseif reward == "CompReward" then
				local compFrame = EndScreen:FindFirstChild("InformationFrame", true)
				if compFrame and compFrame:FindFirstChild("Comp") then
					local currentELO = if type(amount) == "table" then amount.ELO or amount.NewELO or amount.CurrentELO else nil
					local previousELO = if type(amount) == "table" then amount.oldELO or amount.OldELO or amount.PreviousELO else nil
					local EPChanged = if type(amount) == "table" then amount.DeltaELO or amount.ELODelta else nil
					local playerELO = player:FindFirstChild("ELO")
					currentELO = if type(currentELO) == "number" then currentELO elseif playerELO then playerELO.Value else 0
					previousELO = if type(previousELO) == "number" then previousELO else currentELO
					EPChanged = if type(EPChanged) == "number" then EPChanged else currentELO - previousELO
					local nowRank, division = RankCalculator.getRankAndDivision(currentELO)
					local rankConfigs = ReplicatedStorage.CompetitiveData:FindFirstChild("CompetitiveRankConfigurations")
					local CompRankConfig = rankConfigs and rankConfigs:FindFirstChild(nowRank)
					local InformationFrame = compFrame.Comp
					InformationFrame.Rank.Text = nowRank .. " " .. RomanNumeralsConverter.toRoman(division)
					if CompRankConfig then
						InformationFrame.Bar.UIGradient.Color = CompRankConfig.UIGradient.Color
						InformationFrame.Bar.Front.UIGradient.Color = CompRankConfig.UIGradient.Color
						InformationFrame.Icon.Image = CompRankConfig.Image
					end
					InformationFrame.Bar.TextLabel.Text = convertNum(currentELO) .. "/100 EP"
					InformationFrame.Bar.Front.Size = UDim2.fromScale(convertNum(currentELO) / 100, 1)
					if EPChanged < 0 then
						InformationFrame.EPAmount.Text = "-" .. tostring(math.abs(EPChanged))
					else
						InformationFrame.EPAmount.Text = tostring(EPChanged)
					end
				end
			else
				if amount <= 0 then continue end
				if reward == "fdasfasfsafsd" then
					local itemStats = itemModule.Star
					for _ = 1, amount do
						local nextItem = false
						ViewModule.Item({itemStats, nil, function() nextItem = true end})
						repeat task.wait() until nextItem
					end
				elseif RewardsFrame and RewardsFrame:FindFirstChild(reward) then
					local icon = RewardsFrame[reward]
					local displayNameLabel = icon:FindFirstChild("Button", true) and icon.Button:FindFirstChild("DisplayNameLabel", true)
					local countLabel = icon:FindFirstChild("Button", true) and icon.Button:FindFirstChild("ItemCount", true) and icon.Button.ItemCount:FindFirstChild("CountLabel")
					if displayNameLabel and displayNameLabel:IsA("TextLabel") then
						displayNameLabel.Text = reward
					end
					if countLabel and countLabel:IsA("TextLabel") then
						countLabel.Text = amount .. "x"
					end
					icon.Visible = true
				end
			end
		end
	end)
	if not rewardsDisplaySuccess then
		warn("[EndScreen] Failed to display reward animation:", rewardsDisplayError)
	end
	if workspace.Info.Infinity.Value then
		print("MEDAL_CLIP_TRIGGER_GAMEOVER:{INFINITY}")
	else
		print("MEDAL_CLIP_TRIGGER_GAMEOVER:{STORY}")
	end
	showEndScreen(EndScreen)
end)
player:GetAttributeChangedSignal("PossessingTower"):Connect(function()
	if player:GetAttribute("PossessingTower") ~= nil then
		if towerToSpawn then RemovePlaceholderTower() end
		selectedTower = nil
		toggleTowerInfo()
	end
end)
LoadGui()

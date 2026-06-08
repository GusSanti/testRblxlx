------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local modulesFolder: Folder = ReplicatedStorage:WaitForChild("Modules") :: Folder
local dictionaryFolder: Folder = modulesFolder:WaitForChild("Dictionary") :: Folder
local librariesFolder: Folder = modulesFolder:WaitForChild("Libraries") :: Folder
local assetsFolder: Folder = ReplicatedStorage:WaitForChild("Assets") :: Folder
local weaponsFolder: Folder = assetsFolder:WaitForChild("Weapons") :: Folder

local ItemsDataDictionary = require(dictionaryFolder:WaitForChild("ItemsDataDictionary"))
local WeaponSettings = require(librariesFolder:WaitForChild("WeaponSettings"))

local CANONICAL_FORWARD = Vector3.new(1, 0, 0)
local CANONICAL_UP = Vector3.new(0, 1, 0)
local DEFAULT_VIEWPORT_AMBIENT = Color3.fromRGB(112, 116, 124)
local DEFAULT_VIEWPORT_LIGHT_COLOR = Color3.fromRGB(255, 244, 228)
local DEFAULT_VIEWPORT_LIGHT_DIRECTION = Vector3.new(-0.8, -0.55, -0.45)
local VIEWPORT_Y_OFFSET_ATTRIBUTE = "ViewportYOffset"
local VIEWPORT_DISTANCE_OFFSET_ATTRIBUTE = "ViewportDistanceOffset"

type ViewPreset = {
	pitch: number,
	yaw: number,
	roll: number,
	fieldOfView: number,
	distanceScale: number,
	cameraVector: Vector3,
	focusOffset: Vector3,
}

export type WeaponAssetEntry = {
	sourceName: string,
	assetName: string,
	asset: Instance,
	resolvedWeaponKey: string?,
}

local VIEW_PRESETS: { [string]: ViewPreset } = {
	Default = {
		pitch = 0,
		yaw = 0,
		roll = 0,
		fieldOfView = 23,
		distanceScale = 2.28,
		cameraVector = Vector3.new(0.22, 0.08, 1),
		focusOffset = Vector3.new(0.04, -0.08, 0),
	},
	CompactPistol = {
		pitch = 0,
		yaw = 0,
		roll = 0,
		fieldOfView = 23,
		distanceScale = 2.14,
		cameraVector = Vector3.new(0.2, 0.07, 1),
		focusOffset = Vector3.new(0.04, -0.09, 0),
	},
	HeavyPistol = {
		pitch = 0,
		yaw = 0,
		roll = 0,
		fieldOfView = 23,
		distanceScale = 2.22,
		cameraVector = Vector3.new(0.22, 0.08, 1),
		focusOffset = Vector3.new(0.05, -0.09, 0),
	},
	Revolver = {
		pitch = 0,
		yaw = 0,
		roll = 0,
		fieldOfView = 23,
		distanceScale = 2.24,
		cameraVector = Vector3.new(0.22, 0.08, 1),
		focusOffset = Vector3.new(0.05, -0.08, 0),
	},
	SMG = {
		pitch = 0,
		yaw = 0,
		roll = 0,
		fieldOfView = 22,
		distanceScale = 2.35,
		cameraVector = Vector3.new(0.24, 0.08, 1),
		focusOffset = Vector3.new(0.05, -0.07, 0),
	},
	Rifle = {
		pitch = 0,
		yaw = 0,
		roll = 0,
		fieldOfView = 21,
		distanceScale = 2.48,
		cameraVector = Vector3.new(0.26, 0.09, 1),
		focusOffset = Vector3.new(0.07, -0.06, 0),
	},
	Shotgun = {
		pitch = 0,
		yaw = 0,
		roll = 0,
		fieldOfView = 21,
		distanceScale = 2.56,
		cameraVector = Vector3.new(0.27, 0.09, 1),
		focusOffset = Vector3.new(0.07, -0.06, 0),
	},
	Taser = {
		pitch = 0,
		yaw = 0,
		roll = 0,
		fieldOfView = 23,
		distanceScale = 2.08,
		cameraVector = Vector3.new(0.2, 0.07, 1),
		focusOffset = Vector3.new(0.03, -0.08, 0),
	},
}

local PRESET_BY_WEAPON_NAME: { [string]: string } = {
	["19XSwitch"] = "CompactPistol",
	["22"] = "CompactPistol",
	["357Magnum"] = "Revolver",
	["38SP"] = "Revolver",
	["AA12"] = "Shotgun",
	["ARP"] = "Rifle",
	["Cougar"] = "HeavyPistol",
	["DE"] = "HeavyPistol",
	["DFR"] = "SMG",
	["Draco"] = "Rifle",
	["G17"] = "CompactPistol",
	["G19ST"] = "CompactPistol",
	["G20"] = "HeavyPistol",
	["G29"] = "HeavyPistol",
	["G34"] = "HeavyPistol",
	["Hellcat"] = "CompactPistol",
	["HKUSP"] = "CompactPistol",
	["KTP11"] = "CompactPistol",
	["LCP"] = "CompactPistol",
	["LCR"] = "Revolver",
	["M1900"] = "HeavyPistol",
	["MK422"] = "SMG",
	["Mossberg590"] = "Shotgun",
	["P7K3"] = "CompactPistol",
	["PD19x"] = "CompactPistol",
	["STAR45"] = "HeavyPistol",
	["Taser"] = "Taser",
}

------------------//VARIABLES
local WeaponViewport = {}

------------------//FUNCTIONS
local function normalize_lookup_token(value: string): string
	local normalized = string.lower(value)
	return string.gsub(normalized, "[^%w]", "")
end

local function split_path(path: string): { string }
	local pieces: { string } = {}

	for token in string.gmatch(path, "[^%.]+") do
		table.insert(pieces, token)
	end

	return pieces
end

local function find_descendant_by_path(root: Instance?, path: string): Instance?
	local current = root

	for _, token in split_path(path) do
		if not current then
			return nil
		end

		current = current:FindFirstChild(token)
	end

	return current
end

local function is_weapon_tool(instance: Instance?): boolean
	return instance ~= nil and instance:IsA("Tool") and instance:FindFirstChild("WeaponConfig") ~= nil
end

local function get_tool_from_instance(instance: Instance?): Tool?
	if not instance then
		return nil
	end

	if is_weapon_tool(instance) then
		return instance :: Tool
	end

	local nestedTool = instance:FindFirstChildWhichIsA("Tool", true)
	if is_weapon_tool(nestedTool) then
		return nestedTool :: Tool
	end

	return nil
end

local function get_display_asset_from_instance(instance: Instance?): Instance?
	if not instance then
		return nil
	end

	local tool = get_tool_from_instance(instance)
	if tool then
		return tool
	end

	if instance:IsA("Model") then
		return instance
	end

	local nestedModel = instance:FindFirstChildWhichIsA("Model", true)
	if nestedModel then
		return nestedModel
	end

	if instance:FindFirstChildWhichIsA("BasePart", true) then
		return instance
	end

	return nil
end

local function get_weapon_config_from_tool(tool: Tool?): { [string]: any }?
	if not tool then
		return nil
	end

	local configModule = tool:FindFirstChild("WeaponConfig")
	if not configModule or not configModule:IsA("ModuleScript") then
		return nil
	end

	local success, config = pcall(require, configModule)
	if not success or typeof(config) ~= "table" then
		return nil
	end

	return config
end

local function build_asset_entry_from_instance(sourceInstance: Instance): WeaponAssetEntry?
	local asset = get_display_asset_from_instance(sourceInstance)
	if not asset then
		return nil
	end

	local resolvedWeaponKey: string? = nil
	if asset:IsA("Tool") then
		resolvedWeaponKey = WeaponSettings.ResolveTool(asset)
	else
		resolvedWeaponKey = WeaponSettings.ResolveWeaponKey(asset.Name)
	end

	return {
		sourceName = sourceInstance.Name,
		assetName = asset.Name,
		asset = asset,
		resolvedWeaponKey = resolvedWeaponKey,
	}
end

local function find_baseparts(model: Model): { BasePart }
	local parts: { BasePart } = {}

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end

	return parts
end

local function find_largest_part(model: Model): BasePart?
	local largestPart: BasePart? = nil
	local largestVolume = 0

	for _, part in find_baseparts(model) do
		local size = part.Size
		local volume = size.X * size.Y * size.Z

		if volume > largestVolume then
			largestVolume = volume
			largestPart = part
		end
	end

	return largestPart
end

local function find_reference_part(model: Model): BasePart?
	local handle = model:FindFirstChild("Handle", true)
	if handle and handle:IsA("BasePart") then
		return handle
	end

	return find_largest_part(model)
end

local function find_attachment_by_name(model: Model, attachmentName: string): Attachment?
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Attachment") and descendant.Name == attachmentName then
			return descendant
		end
	end

	return nil
end

local function find_muzzle_attachment(model: Model, sourceAsset: Instance?): Attachment?
	local sourceTool = get_tool_from_instance(sourceAsset)
	local config = get_weapon_config_from_tool(sourceTool)
	local referencePart = find_reference_part(model)

	local attachmentPath: string? = nil
	if config and typeof(config.Attachments) == "table" and typeof(config.Attachments.Muzzle) == "string" then
		attachmentPath = config.Attachments.Muzzle
	elseif typeof(WeaponSettings.Default.Attachments) == "table" and typeof(WeaponSettings.Default.Attachments.Muzzle) == "string" then
		attachmentPath = WeaponSettings.Default.Attachments.Muzzle
	end

	if attachmentPath then
		local directAttachment = find_descendant_by_path(model, attachmentPath)
		if directAttachment and directAttachment:IsA("Attachment") then
			return directAttachment
		end

		local partAttachment = find_descendant_by_path(referencePart, attachmentPath)
		if partAttachment and partAttachment:IsA("Attachment") then
			return partAttachment
		end

		local lastToken = split_path(attachmentPath)
		local attachmentName = lastToken[#lastToken]
		if attachmentName then
			local fallbackAttachment = find_attachment_by_name(model, attachmentName)
			if fallbackAttachment then
				return fallbackAttachment
			end
		end
	end

	return find_attachment_by_name(model, "Muzzle")
		or find_attachment_by_name(model, "MuzzleAttachment")
		or find_attachment_by_name(model, "Attachment")
end

local function get_model_center(model: Model): Vector3
	local boundsCFrame = select(1, model:GetBoundingBox())
	return boundsCFrame.Position
end

local function get_dominant_axis_vector(part: BasePart, model: Model): Vector3
	local axisDescriptors = {
		{ size = part.Size.X, vector = part.CFrame.RightVector },
		{ size = part.Size.Y, vector = part.CFrame.UpVector },
		{ size = part.Size.Z, vector = part.CFrame.LookVector },
	}

	table.sort(axisDescriptors, function(a, b)
		return a.size > b.size
	end)

	local axisVector: Vector3 = axisDescriptors[1].vector
	local positiveExtent = 0
	local negativeExtent = 0
	local origin = part.Position

	for _, basePart in find_baseparts(model) do
		local offset = basePart.Position - origin
		local projection = offset:Dot(axisVector)

		if projection >= 0 then
			positiveExtent = math.max(positiveExtent, projection)
		else
			negativeExtent = math.max(negativeExtent, -projection)
		end
	end

	if negativeExtent > positiveExtent then
		return -axisVector
	end

	return axisVector
end

local function project_axis_onto_plane(axis: Vector3, normal: Vector3): Vector3?
	local projected = axis - normal * axis:Dot(normal)
	if projected.Magnitude <= 0.001 then
		return nil
	end

	return projected.Unit
end

local function score_axis_vertical_balance(model: Model, origin: Vector3, axis: Vector3): number
	local positiveExtent = 0
	local negativeExtent = 0

	for _, basePart in find_baseparts(model) do
		local offset = basePart.Position - origin
		local projection = offset:Dot(axis)

		if projection >= 0 then
			positiveExtent = math.max(positiveExtent, projection)
		else
			negativeExtent = math.max(negativeExtent, -projection)
		end
	end

	return negativeExtent - positiveExtent
end

local function choose_stable_up_vector(model: Model, referencePart: BasePart, origin: Vector3, forward: Vector3): Vector3
	local candidateAxes = {
		referencePart.CFrame.UpVector,
		referencePart.CFrame.RightVector,
		referencePart.CFrame.LookVector,
		Vector3.yAxis,
		Vector3.zAxis,
		Vector3.xAxis,
	}

	local bestAxis: Vector3? = nil
	local bestScore = -math.huge

	for _, axis in candidateAxes do
		local projectedAxis = project_axis_onto_plane(axis, forward)
		if not projectedAxis then
			continue
		end

		local verticalBias = math.abs(projectedAxis:Dot(Vector3.yAxis))
		local balanceScore = math.abs(score_axis_vertical_balance(model, origin, projectedAxis))
		local totalScore = verticalBias * 3 + balanceScore

		if totalScore > bestScore then
			bestScore = totalScore
			bestAxis = projectedAxis
		end
	end

	if not bestAxis then
		local fallbackAxis = project_axis_onto_plane(referencePart.CFrame.UpVector, forward)
		if fallbackAxis then
			bestAxis = fallbackAxis
		else
			bestAxis = CANONICAL_UP
		end
	end

	local balance = score_axis_vertical_balance(model, origin, bestAxis)
	if balance < 0 then
		bestAxis = -bestAxis
	end

	return bestAxis
end

local function build_reference_frame(model: Model, sourceAsset: Instance?): CFrame?
	local referencePart = find_reference_part(model)
	if not referencePart then
		return nil
	end

	local muzzleAttachment = find_muzzle_attachment(model, sourceAsset)
	local origin = get_model_center(model)
	local forward: Vector3
	local up: Vector3

	if muzzleAttachment then
		local muzzlePosition = muzzleAttachment.WorldPosition
		local centerToMuzzle = muzzlePosition - origin
		local muzzleLook = muzzleAttachment.WorldCFrame.LookVector

		if centerToMuzzle.Magnitude > 0.01 then
			forward = centerToMuzzle.Unit

			if muzzleLook.Magnitude > 0.01 and forward:Dot(muzzleLook.Unit) < 0 then
				forward = -forward
			end
		elseif muzzleLook.Magnitude > 0.01 then
			forward = muzzleLook.Unit
		else
			forward = get_dominant_axis_vector(referencePart, model)
		end
	else
		forward = get_dominant_axis_vector(referencePart, model)
	end

	up = choose_stable_up_vector(model, referencePart, origin, forward)

	return CFrame.lookAt(origin, origin + forward, up)
end

local function clone_display_asset(instance: Instance): Model?
	local originalArchivable = instance.Archivable
	instance.Archivable = true

	local success, cloneResult = pcall(function()
		return instance:Clone()
	end)

	instance.Archivable = originalArchivable

	if not success or not cloneResult or not cloneResult:IsA("Instance") then
		return nil
	end

	local clone: Instance = cloneResult
	local model: Model

	if clone:IsA("Model") then
		model = clone
	else
		model = Instance.new("Model")
		model.Name = clone.Name

		for _, child in clone:GetChildren() do
			child.Parent = model
		end

		clone:Destroy()
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	if not model:FindFirstChildWhichIsA("BasePart", true) then
		model:Destroy()
		return nil
	end

	return model
end

local function build_placeholder_weapon_model(): Model
	local model = Instance.new("Model")
	model.Name = "WeaponPlaceholder"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.6, 0.4, 0.55)
	body.Color = Color3.fromRGB(65, 65, 70)
	body.Material = Enum.Material.SmoothPlastic
	body.CFrame = CFrame.new(0, 0.35, 0)
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = false
	body.Parent = model

	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(1.2, 0.18, 0.18)
	barrel.Color = Color3.fromRGB(160, 160, 165)
	barrel.Material = Enum.Material.Metal
	barrel.CFrame = CFrame.new(1.75, 0.42, 0)
	barrel.Anchored = true
	barrel.CanCollide = false
	barrel.CanTouch = false
	barrel.CanQuery = false
	barrel.Parent = model

	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Size = Vector3.new(0.4, 0.9, 0.32)
	grip.Color = Color3.fromRGB(150, 150, 150)
	grip.Material = Enum.Material.Metal
	grip.CFrame = CFrame.new(-0.55, -0.3, 0) * CFrame.Angles(0, 0, math.rad(18))
	grip.Anchored = true
	grip.CanCollide = false
	grip.CanTouch = false
	grip.CanQuery = false
	grip.Parent = model

	return model
end

local function center_model_at_origin(model: Model): ()
	local currentPivot = model:GetPivot()
	local boundsCFrame = select(1, model:GetBoundingBox())
	local translationToOrigin = CFrame.new(-boundsCFrame.Position)

	model:PivotTo(translationToOrigin * currentPivot)
end

local function get_view_preset(weaponName: string?): ViewPreset
	if weaponName then
		local presetName = PRESET_BY_WEAPON_NAME[weaponName]
		if presetName and VIEW_PRESETS[presetName] then
			return VIEW_PRESETS[presetName]
		end
	end

	return VIEW_PRESETS.Default
end

local function get_numeric_viewport_attribute(sourceAsset: Instance?, displayModel: Model?, attributeName: string): number
	local function read_offset(instance: Instance?): number?
		if not instance then
			return nil
		end

		local attributeValue = instance:GetAttribute(attributeName)
		if typeof(attributeValue) == "number" then
			return attributeValue
		end

		return nil
	end

	local current = sourceAsset
	while current do
		local offset = read_offset(current)
		if offset ~= nil then
			return offset
		end

		if current == weaponsFolder then
			break
		end

		current = current.Parent
	end

	local modelValue = read_offset(displayModel)
	if modelValue ~= nil then
		return modelValue
	end

	return 0
end

local function get_viewport_y_offset(sourceAsset: Instance?, displayModel: Model?): number
	return get_numeric_viewport_attribute(sourceAsset, displayModel, VIEWPORT_Y_OFFSET_ATTRIBUTE)
end

local function get_viewport_distance_offset(sourceAsset: Instance?, displayModel: Model?): number
	return get_numeric_viewport_attribute(sourceAsset, displayModel, VIEWPORT_DISTANCE_OFFSET_ATTRIBUTE)
end

local function align_model_for_preview(model: Model, sourceAsset: Instance?, weaponName: string?): ViewPreset
	center_model_at_origin(model)

	local previewPreset = get_view_preset(weaponName)

	local previewRotation = CFrame.Angles(
		math.rad(previewPreset.pitch),
		math.rad(previewPreset.yaw),
		math.rad(previewPreset.roll)
	)
	model:PivotTo(previewRotation * model:GetPivot())

	return previewPreset
end

local function resolve_render_input(renderInput: any): (Instance?, string?)
	if typeof(renderInput) == "string" then
		local assetEntries = WeaponViewport.get_available_weapon_assets()
		local assetEntry = WeaponViewport.resolve_asset_entry_for_weapon(renderInput, assetEntries, {})

		if assetEntry then
			return assetEntry.asset, renderInput
		end

		return nil, renderInput
	end

	if typeof(renderInput) == "table" then
		local sourceName = if typeof(renderInput.sourceName) == "string" then renderInput.sourceName else nil
		local asset = renderInput.asset

		if typeof(asset) == "Instance" then
			return asset, sourceName
		end
	end

	return nil, nil
end

local function resolve_entry_from_model_path(
	weaponName: string,
	assetEntries: { WeaponAssetEntry },
	assignedAssets: { [number]: boolean }
): WeaponAssetEntry?
	local configuredModel = ItemsDataDictionary.get_weapon_model(weaponName)
	if not configuredModel then
		return nil
	end

	for index, entry in assetEntries do
		if not assignedAssets[index] and entry.sourceName == configuredModel.Name then
			assignedAssets[index] = true
			return entry
		end
	end

	local directEntry = build_asset_entry_from_instance(configuredModel)
	return directEntry
end

------------------//MAIN FUNCTIONS
function WeaponViewport.clear_viewport(viewport: ViewportFrame): ()
	for _, child in viewport:GetChildren() do
		child:Destroy()
	end

	viewport.CurrentCamera = nil
end

function WeaponViewport.get_available_weapon_assets(): { WeaponAssetEntry }
	local entries: { WeaponAssetEntry } = {}
	local seen: { [string]: boolean } = {}

	for _, child in weaponsFolder:GetChildren() do
		local asset = get_display_asset_from_instance(child)

		if not asset then
			continue
		end

		local sourceName = child.Name
		local assetName = asset.Name
		local dedupeKey = sourceName .. "|" .. assetName

		if seen[dedupeKey] then
			continue
		end

		seen[dedupeKey] = true

		local resolvedWeaponKey: string? = nil
		if asset:IsA("Tool") then
			resolvedWeaponKey = WeaponSettings.ResolveTool(asset)
		else
			resolvedWeaponKey = WeaponSettings.ResolveWeaponKey(assetName)
		end

		table.insert(entries, {
			sourceName = sourceName,
			assetName = assetName,
			asset = asset,
			resolvedWeaponKey = resolvedWeaponKey,
		})
	end

	return entries
end

function WeaponViewport.resolve_asset_entry_for_weapon(
	weaponName: string,
	assetEntries: { WeaponAssetEntry },
	assignedAssets: { [number]: boolean }
): WeaponAssetEntry?
	if weaponName == "" then
		return nil
	end

	local configuredEntry = resolve_entry_from_model_path(weaponName, assetEntries, assignedAssets)
	if configuredEntry then
		return configuredEntry
	end

	local normalizedWeaponName = normalize_lookup_token(weaponName)
	local resolvedWeaponKey = WeaponSettings.ResolveWeaponKey(weaponName)

	local function collect_matches(predicate: (WeaponAssetEntry) -> boolean): { { index: number, entry: WeaponAssetEntry } }
		local matches: { { index: number, entry: WeaponAssetEntry } } = {}

		for index, entry in assetEntries do
			if not assignedAssets[index] and predicate(entry) then
				table.insert(matches, {
					index = index,
					entry = entry,
				})
			end
		end

		return matches
	end

	local directMatches = collect_matches(function(entry: WeaponAssetEntry): boolean
		return entry.sourceName == weaponName or entry.assetName == weaponName
	end)

	if #directMatches == 1 then
		local match = directMatches[1]
		assignedAssets[match.index] = true
		return match.entry
	end

	local normalizedMatches = collect_matches(function(entry: WeaponAssetEntry): boolean
		return normalize_lookup_token(entry.sourceName) == normalizedWeaponName
			or normalize_lookup_token(entry.assetName) == normalizedWeaponName
	end)

	if #normalizedMatches == 1 then
		local match = normalizedMatches[1]
		assignedAssets[match.index] = true
		return match.entry
	end

	if resolvedWeaponKey then
		local keyMatches = collect_matches(function(entry: WeaponAssetEntry): boolean
			return entry.resolvedWeaponKey == resolvedWeaponKey
		end)

		if #keyMatches == 1 then
			local match = keyMatches[1]
			assignedAssets[match.index] = true
			return match.entry
		end
	end

	return nil
end

function WeaponViewport.has_weapon_asset(weaponName: string): boolean
	local assetEntries = WeaponViewport.get_available_weapon_assets()
	return WeaponViewport.resolve_asset_entry_for_weapon(weaponName, assetEntries, {}) ~= nil
end

function WeaponViewport.get_display_name(weaponName: string): string
	local withWordBreaks = string.gsub(weaponName, "(%l)(%u)", "%1 %2")
	withWordBreaks = string.gsub(withWordBreaks, "(%a)(%d)", "%1 %2")
	withWordBreaks = string.gsub(withWordBreaks, "(%d)(%a)", "%1 %2")
	return withWordBreaks
end

function WeaponViewport.render_weapon_viewport(viewport: ViewportFrame, renderInput: any): boolean
	WeaponViewport.clear_viewport(viewport)

	viewport.Ambient = DEFAULT_VIEWPORT_AMBIENT
	viewport.LightColor = DEFAULT_VIEWPORT_LIGHT_COLOR
	viewport.LightDirection = DEFAULT_VIEWPORT_LIGHT_DIRECTION

	local sourceAsset, weaponName = resolve_render_input(renderInput)
	local displayModel = if sourceAsset then clone_display_asset(sourceAsset) else nil

	if not displayModel then
		displayModel = build_placeholder_weapon_model()
	end

	local previewPreset = align_model_for_preview(displayModel, sourceAsset, weaponName)

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport
	displayModel.Parent = worldModel

	local camera = Instance.new("Camera")
	camera.FieldOfView = previewPreset.fieldOfView
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local boundsCFrame, boundsSize = displayModel:GetBoundingBox()
	local maxAxis = math.max(boundsSize.X, boundsSize.Y, boundsSize.Z, 1)
	local manualViewportYOffset = get_viewport_y_offset(sourceAsset, displayModel)
	local manualViewportDistanceOffset = get_viewport_distance_offset(sourceAsset, displayModel)
	local focusOffset = Vector3.new(
		boundsSize.X * previewPreset.focusOffset.X,
		(boundsSize.Y * previewPreset.focusOffset.Y) + manualViewportYOffset,
		boundsSize.Z * previewPreset.focusOffset.Z
	)
	local focusPosition = boundsCFrame.Position + focusOffset
	local cameraDirection = if previewPreset.cameraVector.Magnitude > 0
		then previewPreset.cameraVector.Unit
		else Vector3.new(0.3, 0.15, 1).Unit
	local finalDistanceScale = math.max(0.35, previewPreset.distanceScale + manualViewportDistanceOffset)
	local cameraOffset = cameraDirection * (maxAxis * finalDistanceScale)

	camera.CFrame = CFrame.lookAt(focusPosition + cameraOffset, focusPosition)

	return sourceAsset ~= nil
end

return WeaponViewport

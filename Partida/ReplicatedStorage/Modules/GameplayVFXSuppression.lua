local workspace = game:GetService("Workspace")

local module = {}

local TARGET_CONTAINER_NAMES = {
	VFX = true,
	ItemCache = true,
}

local activeSources = {}
local trackedStates = setmetatable({}, {__mode = "k"})
local containerConnections = setmetatable({}, {__mode = "k"})
local changedEvent = Instance.new("BindableEvent")

local function is_suppressed(): boolean
	return next(activeSources) ~= nil
end

local function save_state(instance: Instance)
	local state = trackedStates[instance]
	if state then
		return state
	end

	state = {}
	trackedStates[instance] = state
	return state
end

local function suppress_visual(instance: Instance)
	if instance:IsA("BasePart") then
		local state = save_state(instance)
		if state.LocalTransparencyModifier == nil then
			state.LocalTransparencyModifier = instance.LocalTransparencyModifier
		end
		instance.LocalTransparencyModifier = 1
		return
	end

	if instance:IsA("Decal") or instance:IsA("Texture") then
		local state = save_state(instance)
		if state.Transparency == nil then
			state.Transparency = instance.Transparency
		end
		instance.Transparency = 1
		return
	end

	if instance:IsA("ParticleEmitter") then
		local state = save_state(instance)
		if state.Enabled == nil then
			state.Enabled = instance.Enabled
		end
		instance.Enabled = false
		instance:Clear()
		return
	end

	if instance:IsA("Beam")
		or instance:IsA("Trail")
		or instance:IsA("Highlight")
		or instance:IsA("PointLight")
		or instance:IsA("SpotLight")
		or instance:IsA("SurfaceLight")
		or instance:IsA("Smoke")
		or instance:IsA("Fire")
		or instance:IsA("Sparkles")
	then
		local state = save_state(instance)
		if state.Enabled == nil then
			state.Enabled = instance.Enabled
		end
		instance.Enabled = false
	end
end

local function suppress_tree(instance: Instance)
	suppress_visual(instance)

	for _, descendant in instance:GetDescendants() do
		suppress_visual(descendant)
	end
end

local function restore_all()
	local trackedInstances = {}

	for instance in trackedStates do
		table.insert(trackedInstances, instance)
	end

	for _, instance in trackedInstances do
		local state = trackedStates[instance]
		if not state then
			continue
		end

		if instance and instance.Parent then
			if state.LocalTransparencyModifier ~= nil and instance:IsA("BasePart") then
				instance.LocalTransparencyModifier = state.LocalTransparencyModifier
			end

			if state.Transparency ~= nil and (instance:IsA("Decal") or instance:IsA("Texture")) then
				instance.Transparency = state.Transparency
			end

			if state.Enabled ~= nil then
				if instance:IsA("ParticleEmitter")
					or instance:IsA("Beam")
					or instance:IsA("Trail")
					or instance:IsA("Highlight")
					or instance:IsA("PointLight")
					or instance:IsA("SpotLight")
					or instance:IsA("SurfaceLight")
					or instance:IsA("Smoke")
					or instance:IsA("Fire")
					or instance:IsA("Sparkles")
				then
					instance.Enabled = state.Enabled
				end
			end
		end

		trackedStates[instance] = nil
	end
end

local function bind_container(container: Instance)
	if containerConnections[container] then
		return
	end

	local connections = {}

	table.insert(connections, container.DescendantAdded:Connect(function(descendant)
		if is_suppressed() then
			suppress_tree(descendant)
		end
	end))

	table.insert(connections, container.AncestryChanged:Connect(function(_, parent)
		if parent ~= nil then
			return
		end

		local active = containerConnections[container]
		if not active then
			return
		end

		for _, connection in active do
			connection:Disconnect()
		end

		containerConnections[container] = nil
	end))

	containerConnections[container] = connections

	if is_suppressed() then
		suppress_tree(container)
	end
end

local function bind_target_containers()
	for _, child in workspace:GetChildren() do
		if TARGET_CONTAINER_NAMES[child.Name] then
			bind_container(child)
		end
	end
end

workspace.ChildAdded:Connect(function(child)
	if TARGET_CONTAINER_NAMES[child.Name] then
		bind_container(child)
	end
end)

bind_target_containers()

function module.IsSuppressed(): boolean
	return is_suppressed()
end

function module.SetSuppressed(source: string, shouldSuppress: boolean): ()
	local wasSuppressed = is_suppressed()

	if shouldSuppress then
		activeSources[source] = true
	else
		activeSources[source] = nil
	end

	local nowSuppressed = is_suppressed()
	if wasSuppressed == nowSuppressed then
		return
	end

	if nowSuppressed then
		bind_target_containers()
		for container in containerConnections do
			if container and container.Parent then
				suppress_tree(container)
			end
		end
	else
		restore_all()
	end

	changedEvent:Fire(nowSuppressed)
end

function module.GetChangedSignal(): RBXScriptSignal
	return changedEvent.Event
end

return module

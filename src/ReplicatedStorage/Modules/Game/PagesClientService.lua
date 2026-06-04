------------------//SERVICES
local Players: Players = game:GetService("Players")

------------------//VARIABLES
local PagesClientService = {}

type PageChangePayload = {
	activePageName: string?,
	hasOpenPage: boolean,
}

local started = false
local isApplying = false

local playerGui: PlayerGui? = nil
local lobbyGui: ScreenGui? = nil
local pagesGui: ScreenGui? = nil
local lobbyHolder: GuiObject? = nil
local lobbyHolderDefaultVisible = true

local pagesByName: { [string]: GuiObject } = {}
local pageVisibilityConnections: { [string]: RBXScriptConnection } = {}
local pageChangeListeners: { (PageChangePayload) -> () } = {}

------------------//FUNCTIONS
local function clone_payload(payload: PageChangePayload): PageChangePayload
	return {
		activePageName = payload.activePageName,
		hasOpenPage = payload.hasOpenPage,
	}
end

local function get_current_open_page_name(): string?
	for pageName, pageObject in pagesByName do
		if pageObject.Visible then
			return pageName
		end
	end

	return nil
end

local function apply_holder_visibility(): ()
	local openPageName = get_current_open_page_name()
	local hasOpenPage = openPageName ~= nil

	if lobbyHolder then
		if hasOpenPage then
			lobbyHolder.Visible = false
		else
			lobbyHolder.Visible = lobbyHolderDefaultVisible
		end
	end

	if pagesGui then
		pagesGui.Enabled = true
	end

	local payload: PageChangePayload = {
		activePageName = openPageName,
		hasOpenPage = hasOpenPage,
	}

	for _, callback in pageChangeListeners do
		callback(clone_payload(payload))
	end
end

local function set_only_page_open(targetPageName: string?): ()
	if isApplying then
		return
	end

	isApplying = true

	for pageName, pageObject in pagesByName do
		local shouldOpen = targetPageName ~= nil and pageName == targetPageName

		if pageObject.Visible ~= shouldOpen then
			pageObject.Visible = shouldOpen
		end
	end

	isApplying = false
	apply_holder_visibility()
end

local function on_registered_page_visibility_changed(pageName: string): ()
	if isApplying then
		return
	end

	local pageObject = pagesByName[pageName]

	if not pageObject then
		return
	end

	if pageObject.Visible then
		set_only_page_open(pageName)
		return
	end

	apply_holder_visibility()
end

local function remove_page_listener(callback: (PageChangePayload) -> ()): ()
	for index, listener in pageChangeListeners do
		if listener == callback then
			table.remove(pageChangeListeners, index)
			return
		end
	end
end

------------------//MAIN FUNCTIONS
function PagesClientService.start(): ()
	if started then
		return
	end

	started = true
	local player = Players.LocalPlayer
	playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	lobbyGui = playerGui:WaitForChild("Lobby") :: ScreenGui

	local holder = lobbyGui:FindFirstChild("Holder")

	if holder and holder:IsA("GuiObject") then
		lobbyHolder = holder
		lobbyHolderDefaultVisible = holder.Visible
	end

	local pagesScreen = playerGui:FindFirstChild("Pages")

	if pagesScreen and pagesScreen:IsA("ScreenGui") then
		pagesGui = pagesScreen
		pagesGui.Enabled = true
	end

	apply_holder_visibility()
end

function PagesClientService.register_page(pageName: string, pageObject: GuiObject): ()
	PagesClientService.start()

	local existingConnection = pageVisibilityConnections[pageName]

	if existingConnection then
		existingConnection:Disconnect()
		pageVisibilityConnections[pageName] = nil
	end

	pagesByName[pageName] = pageObject

	pageVisibilityConnections[pageName] = pageObject:GetPropertyChangedSignal("Visible"):Connect(function()
		on_registered_page_visibility_changed(pageName)
	end)

	if pageObject.Visible then
		set_only_page_open(pageName)
		return
	end

	apply_holder_visibility()
end

function PagesClientService.unregister_page(pageName: string): ()
	local existingConnection = pageVisibilityConnections[pageName]

	if existingConnection then
		existingConnection:Disconnect()
		pageVisibilityConnections[pageName] = nil
	end

	pagesByName[pageName] = nil
	apply_holder_visibility()
end

function PagesClientService.open_page(pageName: string): ()
	set_only_page_open(pageName)
end

function PagesClientService.close_page(pageName: string): ()
	local pageObject = pagesByName[pageName]

	if not pageObject then
		apply_holder_visibility()
		return
	end

	if not pageObject.Visible then
		apply_holder_visibility()
		return
	end

	set_only_page_open(nil)
end

function PagesClientService.toggle_page(pageName: string): ()
	local pageObject = pagesByName[pageName]

	if not pageObject then
		return
	end

	if pageObject.Visible then
		set_only_page_open(nil)
		return
	end

	set_only_page_open(pageName)
end

function PagesClientService.close_all_pages(): ()
	set_only_page_open(nil)
end

function PagesClientService.is_page_open(pageName: string): boolean
	local pageObject = pagesByName[pageName]

	if not pageObject then
		return false
	end

	return pageObject.Visible
end

function PagesClientService.get_state(): PageChangePayload
	local openPageName = get_current_open_page_name()

	return {
		activePageName = openPageName,
		hasOpenPage = openPageName ~= nil,
	}
end

function PagesClientService.on_page_changed(callback: (PageChangePayload) -> ()): (() -> ())
	table.insert(pageChangeListeners, callback)

	return function()
		remove_page_listener(callback)
	end
end

return PagesClientService

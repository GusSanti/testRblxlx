------------------//SERVICES
local StarterGui: StarterGui = game:GetService("StarterGui")

------------------//CONSTANTS
local RETRY_COUNT: number = 10
local RETRY_WAIT: number = 0.25

------------------//VARIABLES
local coreGuiTypes = {
	Enum.CoreGuiType.All,
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Chat,
	Enum.CoreGuiType.Health,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.EmotesMenu,
}

------------------//FUNCTIONS
local function disable_core_gui(): boolean
	local success = pcall(function()
		StarterGui:SetCore("TopbarEnabled", false)

		for _, coreGuiType in coreGuiTypes do
			StarterGui:SetCoreGuiEnabled(coreGuiType, false)
		end
	end)

	return success
end

------------------//INIT
for attempt = 1, RETRY_COUNT do
	if disable_core_gui() then
		break
	end

	task.wait(RETRY_WAIT)
end

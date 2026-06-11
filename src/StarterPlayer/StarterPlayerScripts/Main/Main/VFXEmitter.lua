local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VFXPlayer = require(ReplicatedStorage.AceLib.VFXPlayer)
local GameplayVFXSuppression = require(ReplicatedStorage.Modules:WaitForChild("GameplayVFXSuppression"))

local function syncVFXState(obj: Instance)
	if GameplayVFXSuppression.IsSuppressed() then
		VFXPlayer.cutVFX(obj)
		return
	end

	if obj:GetAttribute("ClientVFXPlayed") then
		VFXPlayer.emitVFX(obj)
	else
		VFXPlayer.cutVFX(obj)
	end
end

workspace:WaitForChild('ItemCache').DescendantAdded:Connect(function(obj)
	if obj:GetAttribute('ClientVFXPlay') then
		syncVFXState(obj)

		obj:GetAttributeChangedSignal('ClientVFXPlayed'):Connect(function()
			syncVFXState(obj)
		end)
	end	
end)

return {}

------------------//VARIABLES
local ModuleCache = {}
local loadedModules: {[ModuleScript]: any} = {}

------------------//FUNCTIONS
function ModuleCache.require(moduleScript: ModuleScript): any
	local loadedModule = loadedModules[moduleScript]
	if loadedModule ~= nil then
		return loadedModule
	end

	local requiredModule = require(moduleScript)
	loadedModules[moduleScript] = requiredModule
	return requiredModule
end

------------------//INIT
return ModuleCache

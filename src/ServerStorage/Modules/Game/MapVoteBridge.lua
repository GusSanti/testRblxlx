------------------//VARIABLES
local mapVoteHandler: ((Player, string) -> ())? = nil

------------------//MAIN FUNCTIONS
local MapVoteBridge = {}

function MapVoteBridge.set_handler(handler: ((Player, string) -> ())?): ()
	mapVoteHandler = handler
end

function MapVoteBridge.get_handler(): ((Player, string) -> ())?
	return mapVoteHandler
end

------------------//INIT
return MapVoteBridge

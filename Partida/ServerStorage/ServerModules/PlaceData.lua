local info


local differentPlaces = {
	MainId = {
		Lobby = 106561972655062,
		Game = 84146955347112,
		AFKChamber = 109641882079491,
	},
	TestId = {
		Lobby = 117137931466956,
		Game = 77187363960578,
		AFKChamber = 74141954893736
	}
}

for _, data in differentPlaces do
	for placeName, placeId in data do
		if placeId == game.PlaceId then
			return data
		end
	end
end


------------------//CONSTANTS
local MapDictionary = {}

export type MapConfig = {
	id: string,
	displayName: string,
	path: string,
	image: string,
}

MapDictionary.MAPS = {
	{
		id = "GasStation",
		displayName = "Gas Station",
		path = "ReplicatedStorage.Assets.Maps.GasStation",
		image = "rbxassetid://8974551912",
	},
	{
		id = "Red",
		displayName = "Red",
		path = "ReplicatedStorage.Assets.Maps.Red",
		image = "rbxassetid://9065765396",
	},
	{
		id = "Yellow",
		displayName = "Yellow",
		path = "ReplicatedStorage.Assets.Maps.Yellow",
		image = "rbxassetid://13611088396",
	},
}

------------------//FUNCTIONS
function MapDictionary.get_maps(): { MapConfig }
	local maps: { MapConfig } = {}

	for _, mapConfig: MapConfig in MapDictionary.MAPS do
		table.insert(maps, mapConfig)
	end

	return maps
end

function MapDictionary.get_map_by_id(mapId: string): MapConfig?
	for _, mapConfig: MapConfig in MapDictionary.MAPS do
		if mapConfig.id == mapId then
			return mapConfig
		end
	end

	return nil
end

return MapDictionary

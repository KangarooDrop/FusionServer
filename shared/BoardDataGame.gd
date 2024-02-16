extends BoardDataBase

class_name BoardDataGame

func getTerritoryScript() -> Script:
	return TerritoryDataGame

func setPlayers(playerIDs : Array) -> void:
	for td in territories:
		td.setPlayers(playerIDs)

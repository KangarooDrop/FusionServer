extends BoardDataGame

class_name BoardDataServer

signal territory_won(territory : TerritoryDataServer)
signal territory_lost(territory : TerritoryDataServer)

signal before_territory_invade(territory : TerritoryDataServer)
signal after_territory_invade(territory : TerritoryDataServer)

signal before_territory_defend(territory : TerritoryDataServer)
signal after_territory_defend(territory : TerritoryDataServer)

signal before_move()

func getTerritoryScript() -> Script:
	return TerritoryDataServer

func getPossibleBets(playerID : int) -> Array:
	var rtn : Array = []
	for i in territories.size():
		var td : TerritoryDataServer = territories[i]
		if td.canPlayerBet(playerID):
			rtn.append(i)
	return rtn

func getPossibleMoves(playerID : int) -> Dictionary:
	var rtn : Dictionary = {}
	return rtn

func getPossibleReveals(playerID : int) -> Dictionary:
	var rtn : Dictionary = {}
	for i in territories.size():
		var td : TerritoryDataServer = territories[i]
		for j in td.playerIdToCreatures[playerID].size():
			var cardData : CardDataGame = td.playerIdToCreatures[playerID][j]
			if cardData.canReveal():
				if not rtn.has(i):
					rtn[i] = []
				rtn[i].append(j)
	return rtn

func connectAllSignals(main) -> void:
	pass

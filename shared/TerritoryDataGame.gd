extends TerritoryDataBase

class_name TerritoryDataGame

var controller : int = -1
var playerIdToCreatures : Dictionary = {}
var creatureToPlayerID : Dictionary = {}

func setPlayers(playerIDs : Array) -> void:
	controller = -1
	playerIdToCreatures.clear()
	creatureToPlayerID.clear()
	for id in playerIDs:
		playerIdToCreatures[id] = []

func isAtCapacity(playerID : int) -> bool:
	return playerIdToCreatures[playerID].size() >= size

func hasCreature(cardData : CardDataGame) -> bool:
	return creatureToPlayerID.has(cardData)

func getFuseTargets(cardData : CardDataGame, playerID) -> Array:
	var rtn : Array = []
	for id in playerIdToCreatures.keys():
		var otherCardData : CardDataGame = playerIdToCreatures[id]
		if cardData.canFuseTo(otherCardData):
			rtn.append(otherCardData)
	return rtn

func addCreature(playerID : int, cardData : CardDataGame) -> bool:
	if not isAtCapacity(playerID):
		creatureToPlayerID[playerID].append(cardData)
		playerIdToCreatures[cardData].append(playerID)
		return true
	return false

func removeCreature(cardData : CardDataGame) -> bool:
	if hasCreature(cardData):
		var playerID : int = creatureToPlayerID[cardData]
		creatureToPlayerID.erase(cardData)
		playerIdToCreatures.erase(cardData)
		return true
	return false

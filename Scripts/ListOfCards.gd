extends Node

const cardFilePath : String = "res://Data/CardsServer.csv"
var cards : Array = []

func matchElementsFromSave(saveString : String) -> Array:
	var split : Array = saveString.split(" ")
	var data : Array = []
	for s in split:
		if CardObject.ELEMENT.has(s):
			data.append(CardObject.ELEMENT[s])
		else:
			data.append(CardObject.ELEMENT.NULL)
	return data

func matchAbilitiesFromSave(saveString : String) -> Array:
	return []

func _ready():
	var allCardData : Array = FileIO.readCSV(cardFilePath)
	var keys : Array = allCardData[0]
	for i in range(1, allCardData.size()-1):
		var cardData : Array = allCardData[i]
		var dict : Dictionary = {'uuid':i-1}
		for j in range(cardData.size()):
			var k : String = keys[j]
			var datum = cardData[j]
			if k == 'power' or k == 'toughness':
				datum = int(datum)
			elif k == 'elements':
				datum = matchElementsFromSave(datum)
			elif k == 'abilities':
				datum = matchAbilitiesFromSave(datum)
			dict[keys[j]] = datum
		var card : CardObject = CardObject.makeCard(dict)
		cards.append(card)

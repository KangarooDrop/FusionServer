
class_name HandObject

var player : PlayerObject = null
var cards : Array = []

signal beforeAdd(cardData : CardObject)
signal afterAdd(cardData : CardObject)

signal beforeRemove(cardData : CardObject)
signal afterRemove(cardData : CardObject)

func _init(player : PlayerObject):
	self.player = player

func addCard(cardData : CardObject):
	pass

func removeCard(card):
	pass

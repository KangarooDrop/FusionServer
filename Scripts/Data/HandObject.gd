
class_name HandObject

var player = null
var deck = null

var cards : Array = []

####################################################################################################

signal before_add(card)
signal after_add(card)

signal before_remove(card)
signal after_remove(card)

####################################################################################################

func setPlayer(player) -> HandObject:
	self.player = player
	return self

func setDeck(deck) -> HandObject:
	self.deck = deck
	return self

####################################################################################################

func addCard(card):
	emit_signal("before_add", card)
	cards.append(card)
	emit_signal("after_add", card)

func removeCard(card):
	emit_signal("before_remove", card)
	cards.erase(card)
	emit_signal("after_remove", card)

####################################################################################################

func getPossibleFuses(boardData : BoardDataServer) -> Dictionary:
	var rtn : Dictionary = {}
	return rtn

func getPossibleReveals(boardData : BoardDataServer) -> Dictionary:
	var rtn : Dictionary = {}
	return rtn


class_name GraveObject

var player = null
var cards : Array = []

####################################################################################################

signal before_add(player : PlayerObject, card)
signal after_add(player : PlayerObject, card)

signal before_remove(player : PlayerObject, card)
signal after_remove(player : PlayerObject, card)

####################################################################################################

func setPlayer(player) -> GraveObject:
	self.player = player
	return self

####################################################################################################

func addCard(card):
	emit_signal("before_add", player, card)
	cards.append(card)
	emit_signal("after_add", player, card)

func removeCard(card):
	emit_signal("before_remove", player, card)
	cards.erase(card)
	emit_signal("after_remove", player, card)

####################################################################################################


class_name DeckObject

var player : PlayerObject = null
var hand : HandObject = null
var grave : GraveObject = null

var cards : Array = []

####################################################################################################

signal before_draw(player : PlayerObject, card)
signal after_draw(player : PlayerObject, card)

signal before_remove(player : PlayerObject, card)
signal after_remove(player : PlayerObject, card)

signal before_shuffle(player : PlayerObject, deckCards : Array)
signal after_shuffle(player : PlayerObject, deckCards : Array)

signal before_reset(player : PlayerObject, deckCards : Array, graveyCards : Array)
signal after_reset(player : PlayerObject, deckCards : Array, graveyCards : Array)

####################################################################################################

func setPlayer(player : PlayerObject) -> DeckObject:
	self.player = player
	return self

func setHand(hand : HandObject) -> DeckObject:
	self.hand = hand
	return self

func setGrave(grave : GraveObject) -> DeckObject:
	self.grave = grave
	return self

####################################################################################################

func deserialize(data : Dictionary) -> DeckObject:
	#TODO
	return self

####################################################################################################

func draw() -> void:
	var cardToDraw = null
	if self.cards.size() <= 0:
		reset()
	if self.cards.size() > 0:
		cardToDraw = self.cards.pop_front()
		
	emit_signal("before_draw", player, cardToDraw)
	hand.addCard(cardToDraw)
	emit_signal("after_draw", player, cardToDraw)

func removeCard(cardData):
	var index : int = self.cards.find(cardData)
	if index != -1:
		removeAt(index)

func removeAt(index : int):
	if index >= 0 and index < self.cards.size():
		var cardToRemove = cards[index]
		emit_signal("before_remove", player, cardToRemove)
		self.cards.erase(cardToRemove)
		emit_signal("after_remove", player, cardToRemove)

func shuffle() -> void:
	emit_signal("before_shuffle", player, self.cards)
	cards.shuffle()
	emit_signal("after_shuffle", player, self.cards)

func reset():
	emit_signal("before_reset", player, self.cards, grave.cards)
	self.cards += grave.cards
	grave.cards.clear()
	shuffle()
	emit_signal("after_reset", player, self.cards, grave.cards)

func getElements() -> Array:
	var elements : Array = []
	for card in cards:
		for element in card.elements:
			if not element in elements:
				elements.append(element)
	if elements.size() == 0:
		return [CardDataBase.ELEMENT.NULL]
	else:
		return elements

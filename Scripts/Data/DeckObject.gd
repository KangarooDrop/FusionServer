
class_name DeckObject

var player = null
var hand = null

var cards : Array = []

####################################################################################################

signal before_draw(card)
signal after_draw(card)

signal before_remove(card)
signal after_remove(card)

signal before_shuffle(cards : Array)
signal after_shuffle(cards : Array)

signal before_reset(cards : Array, graveyard : Array)
signal after_reset(cards : Array, graveyard : Array)

####################################################################################################

func setHand(hand) -> DeckObject:
	self.hand = hand
	return self

func setPlayer(player) -> DeckObject:
	self.player = player
	return self

####################################################################################################

func deserialize(data : Dictionary) -> DeckObject:
	#TODO
	return self

####################################################################################################

func draw() -> void:
	var cardToDraw = null
	if cards.size() > 0:
		cardToDraw = cards.pop_front()
	emit_signal("beforeDraw", cardToDraw)
	hand.addCard(cardToDraw)
	emit_signal("afterDraw")

func removeCard(cardData):
	var index : int = cards.find(cardData)
	if index != -1:
		removeAt(index)

func removeAt(index : int):
	if index >= 0 and index < cards.size():
		var cardToRemove = cards[index]
		emit_signal("beforeRemove", cardToRemove)
		cards.erase(cardToRemove)
		emit_signal("afterRemove", cardToRemove)

func shuffle() -> void:
	emit_signal("beforeShuffle", cards)
	cards.shuffle()
	emit_signal("afterShuffle", cards)

func reset(graveyard : Array):
	emit_signal("beforeReset", cards, graveyard)
	cards += graveyard
	graveyard.clear()
	shuffle()
	emit_signal("afterReset", cards, graveyard)

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

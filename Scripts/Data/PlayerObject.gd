
class_name PlayerObject

var playerID : int = -1
var color : Color = Color(1.0, 0.0, 1.0, 1.0)

var deck : DeckObject
var hand : HandObject

####################################################################################################

func _init(playerID : int):
	self.playerID = playerID
	self.deck = DeckObject.new()
	self.hand = HandObject.new()
	
	hand.setPlayer(self).setDeck(deck)
	deck.setPlayer(self).setHand(hand)

func setColor(color : Color) -> PlayerObject:
	self.color = color
	return self

####################################################################################################

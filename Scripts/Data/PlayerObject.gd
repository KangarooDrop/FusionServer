
extends PlayerBase

class_name PlayerObject

var deck : DeckObject
var hand : HandObject
var grave : Array = []

####################################################################################################

func _init(playerID : int, color : Color, username : String):
	super._init(playerID, color, username)
	self.deck = DeckObject.new()
	self.hand = HandObject.new()
	
	hand.setPlayer(self).setDeck(deck)
	deck.setPlayer(self).setHand(hand)

####################################################################################################

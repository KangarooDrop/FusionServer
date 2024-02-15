
extends PlayerBase

class_name PlayerObject

var deck : DeckObject
var hand : HandObject

####################################################################################################

func _init(playerID : int, color : Color, username : String):
	super._init(playerID, color, username)
	
	hand.setPlayer(self).setDeck(deck)
	deck.setPlayer(self).setHand(hand)

####################################################################################################

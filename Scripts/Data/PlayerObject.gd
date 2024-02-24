
extends PlayerBase

class_name PlayerObject

var deck : DeckObject
var hand : HandObject
var grave : GraveObject

####################################################################################################

func _init(playerID : int, color : Color, username : String):
	super._init(playerID, color, username)
	self.deck = DeckObject.new()
	self.hand = HandObject.new()
	self.grave = GraveObject.new()
	
	grave.setPlayer(self)
	hand.setPlayer(self)
	deck.setPlayer(self).setHand(hand).setGrave(grave)

####################################################################################################

func connectAllSignals(main) -> void:
	deck.connect("after_add", main.afterAddHand)

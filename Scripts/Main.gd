extends Node

var players : Dictionary = {}

func _ready():
	Connector.connect("player_connected", self.onPlayerConnect)
	Connector.connect("player_disconnected", self.onPlayerDisconnect)

func onPlayerConnect(playerID : int) -> void:
	players[playerID] = PlayerObject.new(playerID)

func onPlayerDisconnect(playerID : int) -> void:
	players.erase(playerID)
	if players.size() <= 1:
		Server.disconnectAndQuit()

####################################################################################################

enum GAME_STATE {PRE_GAME, IN_GAME, END_GAME}
enum PHASE {START, DRAW, BET, ACTION, REVEAL, INVADE, END}

####################################################################################################
###   ANY TIME   ###

@rpc("any_peer", "call_remote", "reliable")
func onConcede() -> void:
	var playerID : int = multiplayer.get_remote_sender_id()
	print("CONCEDE PRESSED by " + str(playerID))

@rpc("any_peer", "call_remote", "reliable")
func onQuit() -> void:
	var playerID : int = multiplayer.get_remote_sender_id()
	print("QUIT PRESSED by " + str(playerID))
	Server.serverPeer.disconnect_peer(playerID)
	Connector.onPlayerRemove(playerID)

####################################################################################################
###   PRE-GAME   ###

@rpc("any_peer", "call_remote", "reliable")
func setDeck(deckData : Dictionary) -> void:
	var playerID : int = multiplayer.get_remote_sender_id()
	if not Validator.validateDeck(deckData):
		print("ERROR: Could not validate deck of player " + str(playerID))
		return
	players[playerID].deck.deserialize(deckData)

@rpc("any_peer", "call_remote", "reliable")
func voteBoard(name : String) -> void:
	pass

####################################################################################################
###   IN-GAME   ###

####################################################################################################
###   DUMMY FUNCTIONS FOR RPC   ###

@rpc("authority", "call_remote", "reliable")
func onQuitAnswered():
	pass

@rpc("authority", "call_remote", "reliable")
func onGetOpponentElements(elements : Array):
	pass

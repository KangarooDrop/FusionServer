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

@rpc("any_peer", "call_remote", "reliable")
func onConcede() -> void:
	var playerID : int = multiplayer.get_remote_sender_id()
	print("CONCEDE PRESSED by " + str(playerID))

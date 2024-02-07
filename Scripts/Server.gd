extends Node

var serverPeer : ENetMultiplayerPeer = null
var port : int = -1
var numPlayers : int = -1

var playerIDs : Array = []

signal peer_connected(id : int)
signal peer_disconnected(id : int)

func _ready():
	if port == -1:
		print("ERROR: Could not start game. No port given")
		get_tree().quit()
		return
	elif numPlayers < 1:
		print("ERROR: Could not start game. No player addresses given")
		get_tree().quit()
		return
	
	serverPeer = ENetMultiplayerPeer.new()
	serverPeer.create_server(port, numPlayers + 1)
	multiplayer.multiplayer_peer = serverPeer
	serverPeer.connect("peer_connected", self.onPeerConnected)
	serverPeer.connect("peer_disconnected", self.onPeerDisconnected)

func onPeerConnected(id : int):
	emit_signal("peer_connected", id)

func onPeerDisconnected(id : int):
	emit_signal("peer_disconnected", id)

func lockServer() -> void:
	serverPeer.refuse_new_connections = true

func unlockServer() -> void:
	serverPeer.refuse_new_connections = false

func disconnectAndQuit() -> void:
	print("Disconnecting users and quitting")
	for id in playerIDs:
		serverPeer.disconnect_peer(id, true)
	get_tree().quit()


extends Node

var waitingFor : Array = []
var serverPeer : ENetMultiplayerPeer = null
var port : int = -1
var numPlayers : int = -1
var isAllConnected : bool = false

const CONNECT_MAX_TIME : float = 16.0
var connectTimer : float = CONNECT_MAX_TIME

const DISCONNECT_MAX_TIME : float = 60.0
var disconnectTimer : Dictionary = {}

var connectedPlayers : Dictionary = {}

signal onPlayerConnect(playerID : int)
signal onPlayerDisconnect(playerID : int)

func _ready():
	if port == -1:
		print("ERROR: Could not start game. No port given")
		get_tree().quit()
		return
	elif numPlayers == -1:
		print("ERROR: Could not start game. No player count given")
		get_tree().quit()
		return
	
	serverPeer = ENetMultiplayerPeer.new()
	serverPeer.create_server(port, numPlayers + 1)
	multiplayer.multiplayer_peer = serverPeer
	serverPeer.connect("peer_connected", self.onPeerConnected)
	serverPeer.connect("peer_disconnected", self.onPeerDisconnected)

func onPeerConnected(id : int):
	emit_signal("onPlayerConnect", id)

func onPeerDisconnected(id : int):
	emit_signal("onPlayerDisconnect", id)

func _process(delta):
	if not isAllConnected:
		connectTimer -= delta
		if connectTimer <= 0:
			print("ERROR: Could not establish connection with all users!")
			endMatch()
	else:
		for user in disconnectTimer.keys():
			disconnectTimer[user] -= delta
			if disconnectTimer[user] <= 0:
				print("ERROR: User could not reconnect")
				endMatch()

func endMatch() -> void:
	for id in connectedPlayers.keys():
		serverPeer.disconnect_peer(id, true)
	get_tree().quit()


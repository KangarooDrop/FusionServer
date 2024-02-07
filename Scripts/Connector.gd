extends Node


var waitingFor : Array = []
var connectTimer : float = CONNECT_MAX_TIME
var isAllConnected : bool = false

var idToAddress : Dictionary = {}
var addressToID : Dictionary = {}
var connectedPlayers : Array = []

var disconnectTimers : Dictionary = {}


const CONNECT_MAX_TIME : float = 16.0
const DISCONNECT_MAX_TIME : float = 60.0

####################################################################################################

signal player_connected(playerID : int)
signal player_reconnected(playerID : int)
signal player_disconnected(playerID : int)
signal player_rejected(playerID : int)
signal start_game()

####################################################################################################

func _init():
	var args : Array = OS.get_cmdline_args()
	var i : int = 0
	while i < args.size():
		var arg : String = args[i]
		if i < args.size() - 1:
			if arg == "-p":
				i += 1
				if (args[i] as String).is_valid_int():
					Server.port = int(args[i])
			elif arg == "-c":
				i += 1
				var userAddress : UserAddress = UserAddress.strip(args[i])
				if userAddress != null:
					waitingFor.append(userAddress)
		i += 1
	
	Server.numPlayers = waitingFor.size()
	
	print("Waiting for users: ")
	for user in waitingFor:
		print("  >  ", user)

func _ready():
	Server.connect("peer_connected", self.onPeerConnect)
	Server.connect("peer_disconnected", self.onPeerDisconnect)

####################################################################################################

func onPeerConnect(playerID : int):
	var playerIP : String = Server.serverPeer.get_peer(playerID).get_remote_address()
	var playerPort : int = Server.serverPeer.get_peer(playerID).get_remote_port()
	
	for userAddress in disconnectTimers.keys():
		if userAddress.matches(playerIP, playerPort):
			onPlayerReconnect(addressToID[userAddress], playerID)
			return
	
	if not playerID in connectedPlayers:
		for i in range(waitingFor.size()-1, -1, -1):
			if waitingFor[i].matches(playerIP, playerPort):
				var userAddress : UserAddress = waitingFor[i]
				waitingFor.remove_at(i)
				onPlayerConnect(playerID, userAddress)
				return
		
	print("REJECTED: User(" + playerIP + ":" + str(playerPort) + ")")
	emit_signal("player_rejected", playerID)
	Server.serverPeer.disconnect_peer(playerID, true)

func onPeerDisconnect(playerID : int):
	if playerID in connectedPlayers:
		onPlayerDisconnect(playerID)

func _process(delta):
	if not isAllConnected:
		connectTimer -= delta
		if connectTimer <= 0:
			print("ERROR: Could not establish connection with all users!")
			Server.disconnectAndQuit()
	else:
		for user in disconnectTimers.keys():
			disconnectTimers[user] -= delta
			if disconnectTimers[user] <= 0:
				onPlayerRemove(addressToID[user])


func onPlayerConnect(playerID : int, userAddress : UserAddress):
	Server.playerIDs.append(playerID)
	connectedPlayers.append(playerID)
	idToAddress[playerID] = userAddress
	addressToID[userAddress] = playerID
	emit_signal("player_connected", playerID)
	print("ACCEPTED: " + str(userAddress))
	
	if waitingFor.size() == 0:
		print("Starting Game!")
		isAllConnected = true
		Server.lockServer()
		emit_signal("start_game")

func onPlayerDisconnect(playerID : int):
	Server.unlockServer()
	var userAddress : UserAddress = idToAddress[playerID]
	disconnectTimers[userAddress] = DISCONNECT_MAX_TIME
	print(str(userAddress) + " disconnected.")

func onPlayerRemove(playerID : int):
	print("ERROR: User could not reconnect")
	emit_signal("player_disconnected", playerID)
	disconnectTimers.erase(idToAddress[playerID])
	connectedPlayers.erase(playerID)
	addressToID.erase(idToAddress[playerID])
	idToAddress.erase(playerID)
	if disconnectTimers.size() == 0:
		Server.lockServer()

func onPlayerReconnect(oldID : int, newID : int):
	var userAddress : UserAddress = idToAddress[oldID]
	idToAddress.erase(oldID)
	connectedPlayers.erase(oldID)
	
	disconnectTimers.erase(userAddress)
	idToAddress[newID] = userAddress
	addressToID[userAddress] = newID
	connectedPlayers.append(newID)
	if disconnectTimers.size() == 0:
		Server.lockServer()
	
	print("RECONNECT: " + str(userAddress))
	emit_signal("player_reconnected", oldID, newID)

extends Node

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
				var userCon : UserConnection = UserConnection.strip(args[i])
				if userCon != null:
					Server.waitingFor.append(userCon)
		i += 1
	
	Server.numPlayers = Server.waitingFor.size()
	
	print("Waiting for users: ")
	for user in Server.waitingFor:
		print("  >  ", user)

func _ready():
	Server.connect("onPlayerConnect", self.onPlayerConnect)
	Server.connect("onPeerDisconnect", self.onPeerDisconnect)

func onPlayerConnect(playerID : int):
	var playerIP : String = Server.serverPeer.get_peer(playerID).get_remote_address()
	var playerPort : int = Server.serverPeer.get_peer(playerID).get_remote_port()
	
	if not playerID in Server.connectedPlayers.keys():
		for i in range(Server.waitingFor.size()):
			if Server.waitingFor[i].matches(playerIP, playerPort):
				Server.waitingFor.remove_at(i)
				Server.connectedPlayers[playerID] = [playerIP, playerPort]
				print("ACCEPTED: User(" + playerIP + ":" + str(playerPort) + ")")
				if Server.waitingFor.size() == 0:
					print("Starting Match!")
					Server.isAllConnected = true
				return
	else:
		for userCon in Server.disconnectTimer.keys():
			if userCon.matches(playerIP, playerPort):
				Server.disconnectTimer.erase(userCon)
				print("RECONNECT: User(" + playerIP + ":" + str(playerPort) + ")")
				return
		
	print("REJECTED: User(" + playerIP + ":" + str(playerPort) + ")")
	Server.serverPeer.disconnect_peer(playerID, true)

func onPeerDisconnect(playerID : int):
	if playerID in Server.connectedPlayers.keys():
		var playerIP : String = Server.connectedPlayers[playerID][0]
		var playerPort : int = Server.connectedPlayers[playerID][1]
		Server.disconnectTimer[UserConnection.new(playerIP, playerPort)] = Server.DISCONNECT_MAX_TIME
		print("User(" + playerIP + ":" + str(playerPort) + ") disconnected.")


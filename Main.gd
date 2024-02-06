extends Node

class UserConnection:
	var ip : String = ""
	var port : int = -1
	
	func _init(ip : String = "", port : int = -1):
		self.ip = ip
		self.port = port
	
	func matches(ip : String, port : int) -> bool:
		return self.ip == ip and self.port == port
	
	func _to_string():
		return ip + ":" + str(port)
	
	static func strip(data : String) -> UserConnection:
		var split : Array = data.split(':')
		if split.size() != 2:
			return null
		return UserConnection.new(split[0], int(split[1]))

var waitingFor : Array = []
var serverPeer : ENetMultiplayerPeer = null
var port : int = -1
var numPlayers : int = -1

func _init():
	var args : Array = OS.get_cmdline_args()
	var i : int = 0
	while i < args.size():
		var arg : String = args[i]
		if i < args.size() - 1:
			if arg == "-c":
				i += 1
				var userCon : UserConnection = UserConnection.strip(args[i])
				if userCon != null:
					waitingFor.append(userCon)
			elif arg == "-p":
				i += 1
				if (args[i] as String).is_valid_int():
					port = int(args[i])
			elif arg == "-n":
				i += 1
				if (args[i] as String).is_valid_int():
					numPlayers = int(args[i])
		i += 1
	
	print("Waiting for users: ")
	for user in waitingFor:
		print("  >  ", user)

func _ready():
	serverPeer = ENetMultiplayerPeer.new()
	serverPeer.create_server(port, numPlayers)
	multiplayer.multiplayer_peer = serverPeer
	serverPeer.connect("peer_connected", self.onPeerConnected)

func onPeerConnected(id : int):
	print(id)

#TODO:
#  Reject anyone not in waitingFor list
#  Add timer to wait for players
#
#

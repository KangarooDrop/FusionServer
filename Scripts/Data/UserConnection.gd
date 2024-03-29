
class_name UserAddress

var ip : String = ""
var port : int = -1

func _init(ip : String = "", port : int = -1):
	self.ip = ip
	self.port = port

func matches(ip : String, port : int) -> bool:
	return self.ip == ip# and self.port == port

func _to_string():
	return ip + ":" + str(port)

static func strip(data : String) -> UserAddress:
	var split : Array = data.split(':')
	if split.size() != 2:
		return null
	return UserAddress.new(split[0], int(split[1]))

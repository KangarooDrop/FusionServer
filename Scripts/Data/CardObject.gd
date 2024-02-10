
extends CardData

class_name CardObject

var revealed : bool = false
var damage : int = 0
var zone : int = ZONES.NONE

var owner = null
var controller = null

func setDamage(damage : int) -> void:
	self.damage = damage

func setZone(zone : int) -> void:
	self.zone = zone

enum ZONES {NONE, DECK, HAND, GRAVEYARD, TERRITORY, QUEUE, FUSED}

####################################################################################################

func serialize() -> Dictionary:
	var data : Dictionary = super.serialize()
	data["revealed"] = revealed
	data["damage"] = damage
	data["zone"] = zone
	data["owner"] = owner
	data["controller"] = controller
	return data

func deserialize(data : Dictionary) -> void:
	if data.has('revealed'):
		self.revealed = data['revealed']
	if data.has('damage'):
		self.damage = data['damage']
	if data.has('zone'):
		self.zone = data['zone']
	if data.has('owner'):
		self.owner = data['owner']
	if data.has('controller'):
		self.controller = data['controller']

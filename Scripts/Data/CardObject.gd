
class_name CardObject

var uuid : int = -1

var name : String = "_NONE"

var power : int = -1
var toughness : int = -1
var damage : int = 0

var elements : Array = []

var abilities : Array = []

var owner = null
var controller = null

var node = null

enum ZONES {NONE, DECK, HAND, GRAVEYARD, TERRITORY, QUEUE, FUSED}
var zone : int = ZONES.NONE

enum ELEMENT {NULL = 0, FIRE = 1, WATER = 2, ROCK = 3, NATURE = 4, DEATH = 5, TECH = 6}

####################################################################################################

func _init(uuid : int, name : String, power : int, toughness : int, elements : Array, abilities : Array):
	self.uuid = uuid
	self.name = name
	self.power = power
	self.toughness = toughness
	self.elements = elements
	self.abilities = abilities

func setOwner(owner) -> void:
	self.owner = owner

func setController(controller) -> void:
	self.controller = controller

func setDamage(damage : int) -> void:
	self.damage = damage

func setZone(zone : int) -> void:
	self.zone = zone

####################################################################################################

func copy() -> CardObject:
	return CardObject.new(uuid, name, power, toughness, elements, abilities)

static func makeCard(data : Dictionary) -> CardObject:
	return CardObject.new(data['uuid'], data['name'], data['power'], data['toughness'], data['elements'], data['abilities'])

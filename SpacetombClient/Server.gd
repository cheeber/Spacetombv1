extends Node
onready var opponent = preload("res://opponent.tscn")
onready var bullet = preload("res://BaseBullet.tscn")
onready var player
onready var enemy1 = preload("res://enemy1.tscn")

onready var entityDict = {
	"player" : opponent,
	"enemy1" : enemy1
}
#connect to server
func _ready():
	var network = NetworkedMultiplayerENet.new()
	
	#local ip for testing on your own device
	network.create_client("127.0.0.1", 1909)
	
	#current server ip 
	#note, everytime the aws server is restarted the ip will change
	#network.create_client("18.204.44.52", 1909)
	
	get_tree().set_network_peer(network)
	
	network.connect("connection_failed", self, "OnConnectionFailed")
	network.connect("connection_succeeded", self, "_OnConnectionSucceeded")
	
	
#connection failed message
func _OnConnectionFailed():
	print("Failed to connect")

#connection suceeded message
func _OnConnectionSucceeded():
	print("Succesfully connected")	




#sends player initial position and velocity to server, which will then update other players using returnEntityMovement()
func playerMove(initialPosition, velocity):
	rpc_unreliable_id(1, "playerMove", initialPosition, velocity)

#sends shot info to server, which then sends to all other players using returnShots()
func shoot(directionVector, positionVector, shotSpeed): 
	rpc_id(1, "shoot", directionVector, positionVector, shotSpeed)

func debugSpawnEnemy():
	rpc_id(1, "debugEnemySpawn")

func sendPlayerRotation(rotation):
	rpc_unreliable_id(1, "sendPlayerRotation", rotation)

remote func returnEntityRotation(entity_id, rotation):
	get_parent().get_node(str(entity_id)).setRotation(rotation)

#Takes position and velocity of an entity that was sent by the server and maps it local gamestate
remote func returnEntityMovement(entity_id, initialPosition, velocity):
	var entity = get_parent().get_node_or_null(str(entity_id))
	if entity:
		if entity.has_method("setInitialPosition"):
			entity.setInitialPosition(initialPosition)
		if entity.has_method("setVelocity"):
			entity.setVelocity(velocity)

#loads an entity scene of the correct type and names it
remote func loadEntity(entity_id, entity_type):
	var entity_scene = entityDict.get(entity_type).instance()
	if entity_scene != null:
		entity_scene.set_name(str(entity_id))
		get_parent().add_child(entity_scene)
	
#gets signal from server that an entity is dead, and calls die() function on it
remote func returnDeadEntity(entity_id, source):
	if get_parent().get_node_or_null(str(entity_id)):
		get_parent().get_node(str(entity_id)).die(source)
	
#gets signal from server that the player has died and calls the die() function on it
remote func die(source):
	player.die(source)
	
#sets the health of the an entity to a value sent by the server
remote func setEntityHealth(entity_id, health, source):
	#the null is because set health needs a source and if i don't put that it will crash
	get_parent().get_node(str(entity_id)).setHealth(health, source)

#sets the players health to a specific value
remote func setHealth(health, source):
	player.setHealth(health, source)

#retrieves shot and creates a bullet object using position, velocity and speed
remote func returnShots(directionVector, positionVector, shotSpeed, bulletName):
	var bulletScene = bullet.instance()
	bulletScene.initialize(directionVector, positionVector, shotSpeed)
	bulletScene.set_name(bulletName)
	
	get_parent().add_child(bulletScene)
	

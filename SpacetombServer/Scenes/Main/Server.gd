extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 100
onready var player = preload("res://Scenes/players.tscn")
onready var bullet = preload("res://Scenes/Bullet.tscn")
onready var enemy = preload("res://Scenes/enemy1.tscn")
onready var serverData = get_node("/root/ServerData")
var enemiesDict = {
	1 : "enemy1"
}

func _ready():
	StartServer()
	
	

#sets up and initializes server for connection
func StartServer():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	print("Server started")
	
	network.connect("peer_connected", self, "_Peer_Connected")
	network.connect("peer_disconnected", self, "_Peer_Disconnected")

func _Peer_Connected(player_id):
	#connects player and ads ID to server data list
	serverData.playerIDS.append(player_id)
	print("User " + str(player_id) + " Connected")
	print(serverData.playerIDS)
	
	#create player puppet object
	var playerScene = player.instance()
	playerScene.set_name(str(player_id))
	get_parent().add_child(playerScene)
	
	#loads opponents for other players
	loadLocalEntity(player_id, "player")
	catchUp(player_id)
	
	
func _Peer_Disconnected(player_id):
	#send the disconnect signal to all other players
	serverData.playerIDS.erase(player_id)
	if get_parent().get_node_or_null(str(player_id)): 
		get_parent().get_node_or_null(str(player_id)).queue_free()
	
	for id in serverData.playerIDS:
		rpc_id(id, "returnDeadEntity", player_id, "Disconnect")
	
	print("User " + str(player_id) + " Disconnected")



func loadLocalEntity(entity_id, entityType):
	#send new player id to all other players
	if entityType == "player":
		for player_id in serverData.playerIDS:	
			if player_id != entity_id:
				rpc_id(player_id, "loadEntity", entity_id, entityType)
				rpc_id(entity_id, "loadEntity", player_id, entityType)
	else:
		for player_id in serverData.playerIDS:	
			rpc_id(player_id, "loadEntity", entity_id, entityType)


func returnEntityMovement(entity_id, initialPosition, velocity):
	for player_id in serverData.playerIDS:
		if player_id != entity_id:
			rpc_unreliable_id(player_id, "returnEntityMovement", entity_id, initialPosition, velocity)


func entityDead(entity_id, source):
	for player_id in serverData.playerIDS:
		if player_id != entity_id:
			rpc_id(player_id, "returnDeadEntity", entity_id, source)
		else:
			 rpc_id(entity_id, "die", source)

func setHealth(entity_id, health, source):
	for player_id in serverData.playerIDS:
		if player_id != entity_id:
			rpc_id(player_id, "setEntityHealth", entity_id, health, source)
		else:
			 rpc_id(entity_id, "setHealth", health, source)
			
func catchUp(playerID):
	for enemy_id in serverData.enemyIDS:
		rpc_id(playerID, "loadEntity", enemy_id, enemiesDict.get(enemy_id /1000))
			
remote func playerMove(initialPosition, velocity):
	var sender_id = get_tree().get_rpc_sender_id()	
	var sendingPlayer = get_parent().get_node_or_null(str(sender_id))
	#map player's movement to object
	if sendingPlayer != null:
		sendingPlayer.setInitialPosition(initialPosition)
		sendingPlayer.setVelocity(velocity)
	
	#send update to all other players
	returnEntityMovement(sender_id, initialPosition, velocity)
			
			
remote func shoot(directionVector, positionVector, shotSpeed):
	var sender_id = get_tree().get_rpc_sender_id()

	#create bullet object
	var bulletScene = bullet.instance()
	bulletScene.initialize(directionVector, positionVector, sender_id)
	get_parent().add_child(bulletScene)
	
	#send bullet to other players
	for player_id in serverData.playerIDS:
		if player_id != sender_id:
			rpc_id(player_id, "returnShots", directionVector, positionVector, shotSpeed, bulletScene.name)
			
remote func sendPlayerRotation(rotation):
	var sender_id = get_tree().get_rpc_sender_id()
	
	for player_id in serverData.playerIDS:
		if player_id != sender_id:
			rpc_unreliable_id(player_id, "returnEntityRotation", sender_id, rotation)
	
	
remote func debugEnemySpawn():
	
	serverData.enemyCount += 1
	var enemyID = 1000 + serverData.enemyCount
	serverData.enemyIDS.append(enemyID)
	#print(serverData.enemyIDS)
	
	var enemyScene = enemy.instance()
	enemyScene.set_name(str(enemyID))
	enemyScene.initialize(Vector2.ZERO)
	
	get_parent().add_child(enemyScene)
	loadLocalEntity(enemyScene.name, "enemy1")
	

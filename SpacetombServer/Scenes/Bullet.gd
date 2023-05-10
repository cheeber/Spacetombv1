extends KinematicBody2D
var velocity
var source
export var lifetime = 2000
export var damage = 5
onready var server = get_node("/root/Server")
onready var serverData = get_node("/root/ServerData")

func getClass():
	return "Bullet"

func initialize(velocityVector, positionVector, playerSource):
	source = str(playerSource)
	position = positionVector
	velocity = velocityVector

func _process(delta):
	
	# Bullet moves along velocity vector
	var collision = move_and_collide(velocity)
	#when it collides with a body that isn't the player, or another bullet
	if collision:
		if collision.collider.name != source and collision.collider.getClass() != "Bullet":
			if collision.collider.has_method("takeDamage"):
				collision.collider.takeDamage(damage, "Bullet")
			
			queue_free()
	
	# destroys self when lifetime is up, used to reduce lag from too many bullets existing
	if lifetime <= 0:
		queue_free()
	
	# lifetime goes down by 1 every frame
	lifetime -= 1

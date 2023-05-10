extends KinematicBody2D

# vars
var normDirection
var velocity
export var lifetime = 2000
export var damage = 2
var debug = 0
onready var usesEnemyLayer
#onready var player = get_node("../Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# function takes a target position and a speed and sets the bullet's velocity to the given speed towards that point
func initialize(directionVector, positionVector, speed):
	position = positionVector
	normDirection = directionVector.normalized()
	velocity = normDirection * speed
	
	# Could not get working correctly; uncomment and FIX if bullet is not a circle
	#rotation = acos(directionVector.dot(Vector2(1, 0))) + deg2rad(90)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	# Bullet moves along velocity vector
	var collision = move_and_collide(velocity)
	
	#collision detection
	if collision:
		# destroys self
		queue_free()
	
	# destroys self when lifetime is up, used to reduce lag from too many bullets existing
	if lifetime <= 0:
		queue_free()
	
	# lifetime goes down by 1 every frame
	lifetime -= 1

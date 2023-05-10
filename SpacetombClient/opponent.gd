extends KinematicBody2D


# vars
var velocity = Vector2.ZERO
var speed = 1000
var health = 100
var color

func setInitialPosition(p):
	position = p

func setVelocity(v):
	velocity = move_and_slide(v)

func setHealth(h, source):
	health = h
	
func die(source):
	queue_free()

func setRotation(r):
	get_node("Sprite").rotation = r


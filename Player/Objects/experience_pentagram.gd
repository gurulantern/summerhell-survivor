extends Area2D

@export var exp = 1

var target = null
var speed = -1

@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
@onready var snd_collected = preload("res://Audio/SFX/WAV/pentagram_pickup.wav")

func _ready():
	if exp < 5:
		return
	elif exp < 15:
		sprite.play("blue")
	elif exp < 30:
		sprite.play("red")
	elif exp < 60:
		sprite.play("green")
	elif exp < 120:
		sprite.play("gold")
	elif exp < 200:
		sprite.play("black")

func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 2*delta

func collect():
	SoundManager.play_sound(snd_collected)
	collision.set_deferred("disabled", true)
	sprite.visible = false
	return exp

func _on_snd_collected_finished():
	queue_free()

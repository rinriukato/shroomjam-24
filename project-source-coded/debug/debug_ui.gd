extends Control

@export var player : CharacterBody3D

var timer = 0.0
const POLLING_RATE = 2.0 # How often to update UI


func _process(delta: float) -> void:
	poll_fps(delta)
	poll_velocity()

func poll_fps(delta):
	timer += delta
	if timer > POLLING_RATE:
		timer = 0.0
		%FPS.text = 'FPS: '  + str(Engine.get_frames_per_second())

func poll_velocity():
	%Velocity.text = 'Velocity: '  + str(player.velocity.length())

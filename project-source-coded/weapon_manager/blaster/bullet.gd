extends Node3D

const BULLET_SPEED : float = 50.0
const MAX_LIFETIME_MS = 5000

@export var target_pos := Vector3(0,0,0)
@export var tracer_length = 1

@onready var spawn_time = Time.get_ticks_msec()

# Bullet flies forward
func _process(delta: float) -> void:
	var diff = target_pos - self.global_position
	var add = diff.normalized() * BULLET_SPEED * delta
	add = add.limit_length(diff.length())
	self.global_position += add
	
	#
	if (target_pos - self.global_position).length() <= tracer_length or Time.get_ticks_msec() - spawn_time > MAX_LIFETIME_MS:
		self.queue_free()

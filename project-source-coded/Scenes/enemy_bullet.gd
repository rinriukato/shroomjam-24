extends RigidBody3D
class_name Bullet

var speed = 30.0

var damage = 1

func _ready():
	linear_velocity = transform.basis * Vector3(0,0,-speed)
	$Timer.start()
	print('bullet')

func _on_body_entered(body):
	print('hit by enemy?')
	if body.has_method('take_damage'):
		body.take_damage(damage)
	queue_free()


func _on_timer_timeout():
	if !is_queued_for_deletion():
		queue_free()

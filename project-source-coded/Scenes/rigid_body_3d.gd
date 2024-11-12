extends RigidBody3D

@export var hp = 1000

func _process(_delta: float) -> void:
	$"../Label3D".text = 'HP: ' + str(hp)

func take_damage(amount : int):
	hp -= amount
	
	if hp <= 0:
		$"..".queue_free()
		#self.queue_free()

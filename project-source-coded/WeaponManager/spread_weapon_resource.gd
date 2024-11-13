class_name SpreadWeaponResource
extends WeaponResource

@export var shot_spread : float

func fire_shot():
	weapon_manager.play_sound(shoot_sound)
	#weapon_manager.queue_anim(view_shoot_anim)
	#weapon_manager.queue_anim(view_idle_anim)
	
	
	var raycasts = weapon_manager.shotgun_raycasts
	
	# Randomize all raycasts before firing:
	for r in raycasts:
		r.target_position.x = randf_range(shot_spread,-shot_spread)
		r.target_position.y = randf_range(shot_spread,-shot_spread)
		r.force_raycast_update()
	#NOTE: This is potentially computationally heavy. So please use force raycast and disable raycasts.
	
	# Furtherest point bullet can travel based on raycast
	for r in raycasts:
		if r.is_colliding():
			print('pellet hit!')
			var object = r.get_collider()
			var normal = r.get_collision_normal()
			var point = r.get_collision_point()
			
			# Apply force to physics objects, not necessary rn
			if object is RigidBody3D:
			# 5.0 is force applied to physics objects
				object.apply_impulse(-normal * 5.0 / object.mass, point - object.global_position)
			
			# Damage enemy
			if object.has_method('take_damage'):
				
				if is_purify:
					# Do some effect to enemy's purify function
					pass
				
				if is_corrupt:
					# do some effect to enemy's corrupt function
					pass
				
				object.take_damage(self.damage)

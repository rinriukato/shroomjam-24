class_name ProjectileWeaponResource
extends WeaponResource

@export var projectile : PackedScene
@export var projectile_relative_velocity := Vector3(0,0,-15)
@export var projectile_relative_spawn_pos := Vector3(0,0,-1) # Spawn slightly infront of player
@export var projectile_relative_spawn_rotation := Vector3(0,0,0)

func fire_shot():
	weapon_manager.play_sound(shoot_sound)
	weapon_manager.queue_anim(view_shoot_anim)
	weapon_manager.queue_anim(view_idle_anim)
	
	# Currently none functional.
	#weapon_manager.make_bullet_trail()
	
	var raycast = weapon_manager.bullet_raycast
	raycast.target_position = projectile_relative_spawn_pos
	raycast.force_raycast_update()
	
	var rel_spawn_pos = projectile_relative_spawn_pos
	# Furtherest point bullet can travel based on raycast
	if raycast.is_colliding():
		# Make sure don't spawn in wall
		rel_spawn_pos = raycast.global_transform.affine_inverse() * raycast.get_collision_point()
		rel_spawn_pos = rel_spawn_pos.limit_length(rel_spawn_pos.length() - 0.5)
	
	var obj = projectile.instantiate()
	weapon_manager.player.add_sibling(obj)
	
	obj.global_transform = raycast.global_transform * Transform3D(
		Basis.from_euler(projectile_relative_spawn_rotation), rel_spawn_pos)
		
	#obj.linear_velocity = weapon_manager.player.velocity + raycast.global_transform.basis * projectile_relative_velocity

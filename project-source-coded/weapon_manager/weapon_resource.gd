class_name WeaponResource
extends Resource

# First person persective gun model
@export var view_model : PackedScene

@export var view_model_pos : Vector3
@export var view_model_rot : Vector3
@export var view_model_scale := Vector3(1,1,1)

# Animations
@export var view_idle_anim : String
@export var view_equip_anim : String
@export var view_shoot_anim : String
@export var view_reload_anim : String

# Sounds
@export var shoot_sound : AudioStream
@export var unholster_sound : AudioStream

# Weapon properties
@export var damage = [10, 20, 40]
@export var xp_to_level = [10, 20, 30]
@export var fire_rate = 1
var weapon_manager : WeaponManager

# Bullet Tracer/Projectile
@export var bullet : PackedScene

# Weapon Logic
var trigger_down := false :
	set(v):
		if trigger_down != v:
			trigger_down = v
			
			if trigger_down:
				on_trigger_down()
			else:
				on_trigger_up()

var is_equipped := false : 
	set(v):
		if is_equipped != v:
			is_equipped = v
			if is_equipped:
				on_equip()
			else:
				on_unequip()

func on_trigger_down():
	fire_shot(weapon_manager.get_gun_level())

func on_trigger_up():
	pass

func on_equip():
	# Play animations for equipping here, example below
	weapon_manager.queue_anim(view_idle_anim)
	pass

func on_unequip():
	pass

func fire_shot(gun_level : int):
	weapon_manager.play_sound(shoot_sound)
	weapon_manager.queue_anim(view_shoot_anim)
	weapon_manager.queue_anim(view_idle_anim)
	
	# Currently none functional.
	#weapon_manager.make_bullet_trail()
	
	var raycast = weapon_manager.bullet_raycast
	raycast.force_raycast_update()
	
	# Furtherest point bullet can travel based on raycast
	if raycast.is_colliding():
		var object = raycast.get_collider()
		var normal = raycast.get_collision_normal()
		var point = raycast.get_collision_point()
		
		# Apply force to physics objects, not necessary rn
		if object is RigidBody3D:
		# 5.0 is force applied to physics objects
			object.apply_impulse(-normal * 5.0 / object.mass, point - object.global_position)
		
		# Damage enemy
		if object.has_method('take_damage'):
			object.take_damage(self.damage[gun_level])

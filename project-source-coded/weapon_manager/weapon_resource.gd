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
@export var damage = 10
var weapon_manager : WeaponManager
const RAYCAST_DIST : float = 9999

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
	fire_shot()

func on_trigger_up():
	pass

func on_equip():
	# Play animations for equipping here, example below
	#weapon_manager.play_anim(current_weapon.view_idle_anim)
	pass

func on_unequip():
	pass

func fire_shot():
	weapon_manager.play_sound(shoot_sound)
	# Play shooting animation here?
	# Queue idle animation here
	
	var raycast = weapon_manager.bullet_raycast
	raycast.target_position = Vector3(0,0,-abs(RAYCAST_DIST))
	raycast.force_raycast_update()
	
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
			object.take_damage(self.damage)

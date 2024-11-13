class_name WeaponManager
extends Node3D

enum weapon {
	RAIL_GUN, ROCKET_LAUNCHER, SHOTGUN, MACHINE_GUN 
}

# For stopping weapon shooting while menus are open
@export var allow_shoot : bool = true

# Set weapon
@export var current_weapon : WeaponResource
@export var arsenal : Array[WeaponResource]

@export var player : CharacterBody3D
@export var bullet_raycast : RayCast3D
@export var bullet_raycast_end : Node3D

@export var shotgun_raycasts : Array[RayCast3D]

# Just view model for now...
@export var view_model_container : Node3D

var current_weapon_view_model : Node3D
var current_weapon_view_model_muzzle : Node3D

@onready var audio_stream_player = $AudioStreamPlayer3D
@onready var hud = $"../HUD"

@onready var fire_rate_cooldown_timer = $FireRateCooldown
var is_ready_to_shoot : bool

# Update weapon model on spawn or on change
func update_weapon_model() -> void:
	if current_weapon != null:
		current_weapon.weapon_manager = self
		# If container is set properly (to player) and there is a model avaliable...
		if view_model_container and current_weapon.view_model:
			# Spawn model, and add to container
			current_weapon_view_model = null
			current_weapon_view_model = current_weapon.view_model.instantiate()
			view_model_container.add_child(current_weapon_view_model)
			
			current_weapon_view_model.position = current_weapon.view_model_pos
			current_weapon_view_model.rotation = current_weapon.view_model_rot
			current_weapon_view_model.scale = current_weapon.view_model_scale
			
		if player.has_method('update_view_model_masks'):
			player.update_view_model_masks()
		
		current_weapon.is_equipped = true
		current_weapon_view_model_muzzle = view_model_container.find_child("Muzzle", true, false) if current_weapon_view_model else null

# NOTE: Bullet doesn't spawn at intended location???? Idk why
func make_bullet_trail(target_pos : Vector3):
	if current_weapon_view_model_muzzle == null:
		return
	var muzzle = current_weapon_view_model_muzzle
	var bullet_dir = (target_pos - muzzle.global_position).normalized()
	var start_pos = muzzle.global_position + bullet_dir*0.25
	if (target_pos - start_pos).length() > 3.0:
		var bullet_tracer = preload("res://Scenes/bullet_trail.tscn").instantiate()
		player.add_sibling(bullet_tracer)
		bullet_tracer.global_position = start_pos
		bullet_tracer.target_pos = target_pos
		bullet_tracer.look_at(target_pos)
	
	
func play_sound(sound : AudioStream):
	if sound :
		if audio_stream_player.stream != sound:
			audio_stream_player.stream = sound
		audio_stream_player.play()

func stop_sounds():
	audio_stream_player.stop()
	
func queue_anim(anim_name : String):
	var anim_player : AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer2")
	# The model itself MUST have the animation player node
	if not anim_player: return
	anim_player.queue(anim_name)
	
func _unhandled_input(event: InputEvent) -> void:
	# Weapon Switching:
	if event.is_action_pressed("weapon_1") and current_weapon != arsenal[weapon.RAIL_GUN]:
		current_weapon = arsenal[weapon.RAIL_GUN]
		update_weapon_model()
		hud.displayWeapon(weapon.RAIL_GUN)
	if event.is_action_pressed("weapon_2") and current_weapon != arsenal[weapon.ROCKET_LAUNCHER]:
		current_weapon = arsenal[weapon.ROCKET_LAUNCHER]
		update_weapon_model()
		hud.displayWeapon(weapon.ROCKET_LAUNCHER)
	if event.is_action_pressed("weapon_3"):
		current_weapon = arsenal[weapon.SHOTGUN]
		update_weapon_model()
		hud.displayWeapon(weapon.SHOTGUN)
	if event.is_action_pressed("weapon_4") and current_weapon != arsenal[weapon.MACHINE_GUN]:
		current_weapon = arsenal[weapon.MACHINE_GUN]
		update_weapon_model()
		hud.displayWeapon(weapon.MACHINE_GUN)
	
	# Single fire functionality 
	# NOTE: Consider if semi-automatic fire is what you *really* want in a fast shooter?
	if current_weapon and is_inside_tree():
		if not current_weapon.is_auto:
			if event.is_action_pressed('shoot') and allow_shoot and is_ready_to_shoot:
				current_weapon.trigger_down = true
				set_fire_rate_cooldown(current_weapon.fire_rate)
			elif event.is_action_released('shoot'):
				current_weapon.trigger_down = false

func _ready() -> void:
	update_weapon_model()
	is_ready_to_shoot = true
	#hud.displayWeapon(weapon.RAIL_GUN) # For some reason this makes the HUD think a label doesn't exist yet? Race condition maybe?

func _process(_delta: float) -> void:
	if hud == null: return

# This is PURELY for auto fire functionality
func _physics_process(_delta: float) -> void:
	if not current_weapon.is_auto: return
	
	# NOTE: This is a bit of a scuffed method for full-auto, but it works and
	# should interface with the existing trigger_down and up methods.
	if Input.is_action_pressed('shoot') and allow_shoot and is_ready_to_shoot:
		current_weapon.on_trigger_down()
		current_weapon.trigger_down = true
		set_fire_rate_cooldown(current_weapon.fire_rate)
		
	elif Input.is_action_just_released('shoot'):
		current_weapon.trigger_down = false
			

func set_fire_rate_cooldown(wait_time : float):
	fire_rate_cooldown_timer.wait_time = wait_time
	fire_rate_cooldown_timer.start()
	is_ready_to_shoot = false

func _on_fire_rate_cooldown_timeout() -> void:
	is_ready_to_shoot = true

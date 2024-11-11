class_name WeaponManager
extends Node3D

# For stopping weapon shooting while menus are open
@export var allow_shoot : bool = true

# Set weapon
@export var current_weapon : WeaponResource

@export var player : CharacterBody3D
@export var bullet_raycast : RayCast3D
@export var bullet_raycast_end : Node3D

# Just view model for now...
@export var view_model_container : Node3D

var current_weapon_view_model : Node3D
var current_weapon_view_model_muzzle : Node3D

@onready var audio_stream_player = $AudioStreamPlayer3D
@onready var hud = $"../HUD"

# Update weapon model on spawn or on change
func update_weapon_model() -> void:
	if current_weapon != null:
		current_weapon.weapon_manager = self
		# If container is set properly (to player) and there is a model avaliable...
		if view_model_container and current_weapon.view_model:
			# Spawn model, and add to container
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
func make_bullet_trail():
	if current_weapon_view_model_muzzle == null:
		return
	
	var bullet_instance = current_weapon.bullet.instantiate()
	#print('muzzle pos: ' + str(current_weapon_view_model_muzzle.global_position))
	#print('target pos:' + str(target_pos))
	bullet_instance.init(current_weapon_view_model_muzzle.global_position, bullet_raycast.get_collision_point())
	get_parent().add_child(bullet_instance)
	
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
	if current_weapon and is_inside_tree():
		if event.is_action_pressed('shoot') and allow_shoot:
			current_weapon.trigger_down = true
		elif event.is_action_released('shoot'):
			current_weapon.trigger_down = false


func _ready() -> void:
	update_weapon_model()

func _process(_delta: float) -> void:
	if hud == null: return
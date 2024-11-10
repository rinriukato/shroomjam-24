class_name WeaponManager
extends Node3D

# For stopping weapon shooting while menus are open
@export var allow_shoot : bool = true

# Set weapon
@export var current_weapon : WeaponResource

@export var player : CharacterBody3D
@export var bullet_raycast : RayCast3D

# Just view model for now...
@export var view_model_container : Node3D

var current_weapon_view_model : Node3D
var current_weapon_view_model_muzzle : Node3D

@onready var audio_stream_player = $AudioStreamPlayer3D

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

func make_bullet_trail(target_pos : Vector3):
	if current_weapon_view_model_muzzle == null:
		return
	var muzzle = current_weapon_view_model_muzzle
	var bullet_dir = (target_pos - muzzle.global_position).normalized()
	var start_pos = muzzle.global_position + bullet_dir * 0.25 # slightly infront of muzzle position
	
	if (target_pos - start_pos).length() > 3.0:
		var bullet_tracer = preload("res://weapon_manager/blaster/bullet.tscn").instantiate()
		player.add_sibling(bullet_tracer)
		
		bullet_tracer.target_pos = target_pos
		bullet_tracer.look_at(target_pos)

func play_sound(sound : AudioStream):
	if sound:
		if audio_stream_player.stream != sound:
			audio_stream_player.stream = sound
		audio_stream_player.play()

func stop_sounds():
	audio_stream_player.stop()

func _unhandled_input(event: InputEvent) -> void:
	if current_weapon and is_inside_tree():
		if event.is_action_pressed('shoot') and allow_shoot:
			current_weapon.trigger_down = true
		elif event.is_action_released('shoot'):
			current_weapon.trigger_down = false

func _ready() -> void:
	update_weapon_model()

func _process(_delta: float) -> void:
	pass

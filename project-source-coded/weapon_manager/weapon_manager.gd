extends Node3D

# Set weapon
@export var current_weapon : WeaponResource

@export var player : CharacterBody3D
@export var bullet_raycast : RayCast3D

# Just view model for now...
@export var view_model_container : Node3D

var current_weapon_view_model : Node3D

# Update weapon model on spawn or on change
func update_weapon_model() -> void:
	if current_weapon != null:
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

func _ready() -> void:
	update_weapon_model()


func _process(_delta: float) -> void:
	pass

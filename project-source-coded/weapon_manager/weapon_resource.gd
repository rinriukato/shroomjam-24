class_name WeaponResource
extends Resource

# First person persective gun model
@export var view_model : PackedScene

@export var view_model_pos : Vector3
@export var view_model_rot : Vector3
@export var view_model_scale := Vector3(1,1,1)

# Weapon properties
@export var damage = 10

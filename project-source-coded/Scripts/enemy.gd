extends CharacterBody3D

@export var player_path : NodePath
@export var color : Color
@export var aggro_range := 50.0
@export var fire_speed := 0.6
@export var damage := 10

var health = 100
var material
var player = null
var bullet = preload("res://Scenes/enemy_bullet.tscn")

@onready var gun = $Gun
@onready var nav = $NavigationAgent3D
@onready var sight = $RayCast3D
@onready var engagedTimer = $Engaged

var lastShot := 0.0
var speed := 10.0

var startPos
var engaged = false

func _ready():
	player = get_node(player_path)
	startPos = global_position
	var mat = StandardMaterial3D.new()
	mat.set_albedo(color)
	mat.emission_enabled = true
	%Body.set_surface_override_material(0,mat)
	%Nose.set_surface_override_material(0,mat)
	material = mat
	
func take_damage(dmg):
	health -= dmg
	engaged = true
	engagedTimer.start()
	if health < 1:
		queue_free()
	var tween = get_tree().create_tween()
	tween.tween_property(material, "emission",Color(2,1,1,1), 0.02)
	tween.tween_property(material, "emission",Color(0,0,0,1), 0.2)

func _fire():
	var now := Time.get_ticks_msec()/1000.0
	if now < lastShot+fire_speed: return
	
	lastShot = now
	var b = bullet.instantiate()
	b.damage = damage
	b.global_transform = gun.global_transform
	get_parent().add_child(b)

func _process(delta):
	velocity = Vector3.ZERO
	if self.global_position.distance_to(player.global_position) < aggro_range and player.health >0 or engaged: 
		nav.set_target_position(player.global_transform.origin)
		if sight.get_collider() is PlayerCharacter:
			_fire()
		look_at(Vector3(player.global_position.x, player.global_position.y,player.global_position.z),Vector3.UP)
	elif global_position.distance_to(startPos) > 5:
		nav.set_target_position(startPos)
		look_at(Vector3(startPos.x, startPos.y,startPos.z),Vector3.UP)
	
	var nextPos = nav.get_next_path_position()
	
	velocity = (nextPos - global_transform.origin).normalized()
	
	move_and_slide()
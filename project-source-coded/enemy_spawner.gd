extends Node3D

@export var spawn_locations : Array[Node3D]
@export var enemys : Array[PackedScene]
@export var player_path : NodePath
@export var is_spawning : bool

@export var enemies_to_spawn : int
var current_enemies : int = 0

@onready var wave_timer := $Timer


func _ready() -> void:
	SignalBus.enemy_died.connect(_on_enemy_died)
	_spawn_wave_of_enemies()

func _spawn_wave_of_enemies():
	if is_spawning:
		for location in spawn_locations:
			var new_enemy = enemys.pick_random().instantiate()
			new_enemy.global_position = location.global_position
			new_enemy.player_path = player_path
			call_deferred("add_sibling", new_enemy)
			current_enemies += 1

func _on_enemy_died():
	print('enemy died')
	current_enemies -= 1
	
	if current_enemies <= 0:
		wave_timer.start()

func _on_timer_timeout() -> void:
	print('spawning new wave...')
	_spawn_wave_of_enemies()

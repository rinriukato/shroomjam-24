extends CharacterBody3D

@export var look_sensitivity : float = 0.006
@export var jump_velocity := 6.0
@export var dash_power := 20.0

# Air Movement Settings
@export var air_cap := 0.85
@export var air_accel := 800.0
@export var air_move_speed := 500.0

# Ground Momvement Settings
@export var walk_speed := 10.0
@export var ground_accel := 14.0
@export var ground_decel := 10.0
@export var ground_friction := 6.0

# Store input direction for multiple usage
var wish_dir := Vector3.ZERO

func _ready():
	# Hide player model from camera
	for child in %WorldModel.find_children('*', 'VisualInstance3D'):
		child.set_layer_mask_value(1,false)
		child.set_layer_mask_value(2,true)

# Using this instead of input to allow for character controller use UI when mouse is captured
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed('ui_cancel'):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Move camera based on mouse movement
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			# Left and right camera movement
			rotate_y(-event.relative.x * look_sensitivity)
			# Up and down camera movement
			%Camera3D.rotate_x(-event.relative.y * look_sensitivity)
			# Clamp camera rotation to not go too far
			%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			
func _process(delta):
	pass

func _handle_ground_physics(delta) -> void:
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = walk_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * walk_speed
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
	
	# Apply friction
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed

func _handle_air_physics(delta) -> void:
	self.velocity.y -= ProjectSettings.get_setting('physics/3d/default_gravity') * delta
	
	# Movement recipe based on source/quake air movement.
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)

	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap) 
		self.velocity += accel_speed * wish_dir

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector('left', 'right', 'up', 'down').normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	
	if Input.is_action_just_pressed("dash"):
		self.velocity.x = wish_dir.x * dash_power
		self.velocity.z = wish_dir.z * dash_power
	
	if is_on_floor():
		# NOTE: using 'is_action_pressed' here allows for auto 'bhopping'. 
		if Input.is_action_pressed("jump"):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	move_and_slide()

extends CharacterBody3D

# State Variables
enum states {
	IDLE, RUN, INAIR, DASHING
}
var current_state

@export var look_sensitivity : float = 0.006
@export var dash_power := 20.0

# Jump Settings
@export var jump_height : float = 5.0
@export var jump_time_to_peak : float = 1.0
@export var jump_time_to_fall : float = 1.0
@onready var jump_velocity : float = (2.0 * jump_height) / jump_time_to_fall

# Gravity Settings
@onready var jump_gravity : float = (-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity : float = (-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)

# Air Movement Settings
@export var air_cap := 0.85
@export var air_accel := 800.0
@export var air_move_speed := 500.0

# Ground Movement Settings
@export var walk_speed := 10.0
@export var ground_accel := 14.0
@export var ground_decel := 10.0
@export var ground_friction := 6.0

# Head Bobbing
const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 1.4
var headbob_time := 0.0

const MAX_STEP_HEIGHT = 0.5
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor = -INF

const VIEW_MODEL_LAYER = 9 
const WORLD_MODEL_LAYER = 2

# Store input direction for multiple usage
var wish_dir := Vector3.ZERO

func _ready():
	# Hide player model from camera
	update_view_model_masks()
	current_state = states.IDLE

func update_view_model_masks():
	for child in %WorldModel.find_children('*', 'VisualInstance3D'):
		child.set_layer_mask_value(1,false)
		child.set_layer_mask_value(WORLD_MODEL_LAYER,true)
	
	# Disable shadows for weapon models
	for child in %ViewModel.find_children('*', 'VisualInstance3D', true, false):
		if child is GeometryInstance3D:
			child.cast_shadow = false


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
			
#func _process(_delta):
#	pass

var _saved_camera_global_pos = null
func _save_camera_pos_for_smoothing():
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = %CameraSmooth.global_position

func _slide_camera_smooth_back_to_origin(delta):
	if _saved_camera_global_pos == null: return
	%CameraSmooth.global_position.y = _saved_camera_global_pos.y
	%CameraSmooth.position.y = clampf(%CameraSmooth.position.y, -0.7, 0.7) # Clamp incase teleported
	var move_amount = max(self.velocity.length() * delta, walk_speed/2 * delta)
	%CameraSmooth.position.y = move_toward(%CameraSmooth.position.y, 0.0, move_amount)
	_saved_camera_global_pos = %CameraSmooth.global_position
	if %CameraSmooth.position.y == 0:
		_saved_camera_global_pos = null # Stop smoothing camera

func _handle_ground_physics(delta) -> void:
	
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = walk_speed - cur_speed_in_wish_dir
	_headbob_effect(delta)
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * walk_speed
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		if self.velocity.length() > 1.0:
			current_state = states.RUN
	
	# Apply friction
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed

func _handle_air_physics(delta) -> void:
	current_state = states.INAIR
	
	if self.velocity.y >= 0.0:
		self.velocity.y += jump_gravity * delta
	else:
		self.velocity.y += fall_gravity * delta
	
	# Movement recipe based on source/quake air movement.
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)

	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap) 
		self.velocity += accel_speed * wish_dir
	

# Handle jump, potential double jump functionality here...
func _handle_jump():
	self.velocity.y = jump_velocity

func is_surface_too_steep(normal : Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle

# Tests if the player can fall to a stair below
func _run_body_test_motion(from : Transform3D, motion : Vector3, result = null) -> bool:
	if not result: 
		result = PhysicsTestMotionResult3D.new()
		
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result)

func _snap_up_stairs_check(delta) -> bool:
	if not is_on_floor() and not _snapped_to_stairs_last_frame: return false
	# Don't snap stairs if trying to jump, also no need to check for stairs ahead if not moving
	if self.velocity.y > 0 or (self.velocity * Vector3(1,0,1)).length() == 0: return false
	var expected_move_motion = self.velocity * Vector3(1,0,1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	# Run a body_test_motion slightly above the pos we expect to move to, towards the floor.
	#  We give some clearance above to ensure there's ample room for the player.
	#  If it hits a step <= MAX_STEP_HEIGHT, we can teleport the player on top of the step
	#  along with their intended motion forward.
	var down_check_result = KinematicCollision3D.new()
	if (self.test_move(step_pos_with_clearance, Vector3(0,-MAX_STEP_HEIGHT*2,0), down_check_result)
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		# Note I put the step_height <= 0.01 in just because I noticed it prevented some physics glitchiness
		# 0.02 was found with trial and error. Too much and sometimes get stuck on a stair. Too little and can jitter if running into a ceiling.
		# The normal character controller (both jolt & default) seems to be able to handled steps up of 0.1 anyway
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_position() - self.global_position).y > MAX_STEP_HEIGHT: return false
		%StairsAheadRayCast3D.global_position = down_check_result.get_position() + Vector3(0,MAX_STEP_HEIGHT,0) + expected_move_motion.normalized() * 0.1
		%StairsAheadRayCast3D.force_raycast_update()
		if %StairsAheadRayCast3D.is_colliding() and not is_surface_too_steep(%StairsAheadRayCast3D.get_collision_normal()):
			_save_camera_pos_for_smoothing()
			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			_snapped_to_stairs_last_frame = true
			return true
	return false

func _snap_down_to_stairs_check() -> void:
	var did_snap := false
	
	# Prevent snapping down if nothing below
	var floor_below : bool = %StairsBelowRayCast3D.is_colliding() and not is_surface_too_steep(%StairsBelowRayCast3D.get_collision_normal())
	
	var was_on_floor_last_frame = Engine.get_physics_frames() - _last_frame_was_on_floor == 1
	if not is_on_floor() and velocity.y <= 0 and (was_on_floor_last_frame or _snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = PhysicsTestMotionResult3D.new()
		
		# Found a stair below player, translate player down to the bottom stair
		if _run_body_test_motion(self.global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), body_test_result):
			_save_camera_pos_for_smoothing()
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	_snapped_to_stairs_last_frame = did_snap

func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	%Camera3D.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)

func _physics_process(delta: float):
	
	# If not moving, set to idle
	if current_state != states.IDLE:
		if self.velocity.length() < 1.0:
			current_state = states.IDLE

	
	if is_on_floor():
		_last_frame_was_on_floor = Engine.get_physics_frames()
	
	var input_dir = Input.get_vector('left', 'right', 'up', 'down').normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	
	if Input.is_action_just_pressed("dash"):
		self.velocity.x = wish_dir.x * dash_power
		self.velocity.z = wish_dir.z * dash_power
		current_state = states.DASHING
	
	if is_on_floor() or _snapped_to_stairs_last_frame:
		# NOTE: using 'is_action_pressed' here allows for auto 'bhopping'. 
		if Input.is_action_pressed("jump"):
			_handle_jump()
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	# NOTE: _snap_up_stairs_check() moves body manually, so we shouldn't call move_and_slide when this happens
	if not _snap_up_stairs_check(delta):
		move_and_slide()
		_snap_down_to_stairs_check()
	
	_slide_camera_smooth_back_to_origin(delta)

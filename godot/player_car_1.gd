extends CharacterBody3D

@export var speed: float = 6
@export var rotation_speed: float = 4
@export var gravity: float = 3
@export var jump_impulse: float = 0.8     
@export var ramp_boost_factor: float = 0.2  

var was_on_floor: bool = false

var is_recording: bool = false
var telemetry_data: Array = []
var telemetry_time = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_dir.x != 0:
		rotate_y(-input_dir.x * rotation_speed * delta)

	var forward = -global_transform.basis.x.normalized()
	var move_dir = forward * input_dir.y * speed

	velocity.x = move_dir.x
	velocity.z = move_dir.z

	move_and_slide()

	var now_on_floor = is_on_floor()

	if was_on_floor and not now_on_floor:
		var boost = abs(input_dir.y) * speed * ramp_boost_factor
		velocity.y = jump_impulse + boost

	if is_recording:
		# --- MODIFICARE 1: Incrementăm timpul relativ al cursei cu delta time ---
		telemetry_time += delta
		record_telemetry_frame()

	was_on_floor = now_on_floor

func start_recording() -> void:
	telemetry_time = 0.0
	telemetry_data.clear()
	is_recording = true

func stop_recording() -> Array:
	is_recording = false
	return telemetry_data

func record_telemetry_frame() -> void:
	var rotation_quat = global_transform.basis.get_rotation_quaternion()
	var frame = {
		# --- MODIFICARE 2: Salvăm timpul relativ (telemetry_time) în loc de cel absolut ---
		"t": telemetry_time,
		"px": global_position.x, "py": global_position.y, "pz": global_position.z,
		"rx": rotation_quat.x, "ry": rotation_quat.y, "rz": rotation_quat.z, "rw": rotation_quat.w
	}
	telemetry_data.append(frame)

extends CharacterBody3D

@export var speed: float = 6
@export var rotation_speed: float = 4
@export var gravity: float = 3
@export var jump_impulse: float = 0.8       # Ajustat de la 1400 la o viteză inițială realistă (m/s)
@export var ramp_boost_factor: float = 0.2  # Ajustat de la 1200 (procentaj din viteza curentă)

var was_on_floor: bool = false

# --- TELEMETRIE ---
var is_recording: bool = false
var telemetry_data: Array = []

func _physics_process(delta: float) -> void:
	# GRAVITY
	if not is_on_floor():
		velocity.y -= gravity * delta

	# INPUT
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# ROTATION
	if input_dir.x != 0:
		rotate_y(-input_dir.x * rotation_speed * delta)

	# MOVE DIRECȚIE
	var forward = -global_transform.basis.x.normalized()
	var move_dir = forward * input_dir.y * speed

	velocity.x = move_dir.x
	velocity.z = move_dir.z

	# MOVE (FOARTE IMPORTANT: înainte de jump check)
	move_and_slide()

	# 🔥 DETECTĂM DUPĂ MOVE
	var now_on_floor = is_on_floor()

	if was_on_floor and not now_on_floor:
		# tocmai ai părăsit solul
		var boost = abs(input_dir.y) * speed * ramp_boost_factor
		velocity.y = jump_impulse + boost

	# TELEMETRIE
	if is_recording:
		record_telemetry_frame()

	# update stare
	was_on_floor = now_on_floor

func start_recording() -> void:
	telemetry_data.clear()
	is_recording = true


func stop_recording() -> Array:
	is_recording = false
	return telemetry_data


func record_telemetry_frame() -> void:
	var rotation_quat = global_transform.basis.get_rotation_quaternion()
	var frame = {
		"t": Time.get_ticks_msec() / 1000.0,
		"px": global_position.x, "py": global_position.y, "pz": global_position.z,
		"rx": rotation_quat.x, "ry": rotation_quat.y, "rz": rotation_quat.z, "rw": rotation_quat.w
	}
	telemetry_data.append(frame)

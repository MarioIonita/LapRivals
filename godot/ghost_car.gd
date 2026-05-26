extends Node3D

@onready var network_client = $NetworkClient

var telemetry_data: Array = []
var is_playing: bool = false
var speed_multiplier: float = 1.0 
var current_time: float = 0.0
var current_frame_index: int = 0

var is_download_complete: bool = false
var is_race_triggered: bool = false

func _ready():
	if GameManager.current_mode == GameManager.GameMode.MULTIPLAYER:
		set_process(false)
		set_physics_process(false)
		return
	GameManager.race_started.connect(_on_race_started_signal)
	
	if is_download_complete:
		print("Ghost Car log : Spawned as a bot ")
		return 

	if GameManager.current_mode == GameManager.GameMode.SINGLE_PLAYER:
		queue_free()
		return
		
	await get_tree().create_timer(0.5).timeout 
	network_client.request_completed.connect(_on_download_completed)
	download_ghost_data(GameManager.current_track_id)

func download_ghost_data(track_id: int):
	var url = "http://127.0.0.1:8000/api/v1/get_ghost/" + str(track_id)
	var headers = GameManager.get_auth_headers()
	network_client.request(url, headers, HTTPClient.METHOD_GET)

func _on_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("telemetry"):
			telemetry_data = json["telemetry"]
			is_download_complete = true
			
			if telemetry_data.size() > 0:
				_apply_frame(telemetry_data[0])
			
			if is_race_triggered:
				start_playback()
				
	elif response_code == 401:
		print("Server declined new user (401 Unauthorized)!")
		queue_free()
		
	elif response_code == 404:
		print("Ghost Car log: No races yet (404 Not Found).")
		queue_free()
		
	else:
		print("LOG [GhostCar]: Server response code ", response_code)
		queue_free()

func _on_race_started_signal():
	is_race_triggered = true
	if is_download_complete:
		start_playback()

func start_playback():
	if telemetry_data.size() < 2: return
	current_time = 0.0 
	current_frame_index = 0
	is_playing = true

func _process(delta: float):
	if not is_playing: return
	
	current_time += delta * speed_multiplier
	
	while current_frame_index < telemetry_data.size() - 1 and telemetry_data[current_frame_index + 1].t < current_time:
		current_frame_index += 1
		
	if current_frame_index >= telemetry_data.size() - 1:
		is_playing = false
		return
		
	var frame_A = telemetry_data[current_frame_index]
	var frame_B = telemetry_data[current_frame_index + 1]
	
	var time_diff = frame_B.t - frame_A.t
	var alpha = 0.0
	if time_diff > 0:
		alpha = (current_time - frame_A.t) / time_diff
		
	var pos_A = Vector3(frame_A.px, frame_A.py, frame_A.pz)
	var pos_B = Vector3(frame_B.px, frame_B.py, frame_B.pz)
	var quat_A = Quaternion(frame_A.rx, frame_A.ry, frame_A.rz, frame_A.rw)
	var quat_B = Quaternion(frame_B.rx, frame_B.ry, frame_B.rz, frame_B.rw)
	
	global_position = pos_A.lerp(pos_B, alpha)
	quaternion = quat_A.slerp(quat_B, alpha)

func _apply_frame(frame: Dictionary):
	global_position = Vector3(frame.px, frame.py, frame.pz)
	quaternion = Quaternion(frame.rx, frame.ry, frame.rz, frame.rw)
	
func set_car_color(new_color: Color) -> void:
	var material = StandardMaterial3D.new()
	material.albedo_color = new_color
	material.metallic = 0.6
	material.roughness = 0.2
	
	if has_node("Sketchfab_Scene"):
		_apply_material_recursive($Sketchfab_Scene, material)
	else:
		print("No SketchFab node for coloring.")

func _apply_material_recursive(current_node: Node, mat: Material) -> void:
	if current_node is MeshInstance3D:
		current_node.set_surface_override_material(0, mat)
		
	for child in current_node.get_children():
		_apply_material_recursive(child, mat)

extends Node3D

@onready var network_client = $NetworkClient

var telemetry_data: Array = []
var is_playing: bool = false
var current_time: float = 0.0
var current_frame_index: int = 0

var is_download_complete: bool = false
var is_race_triggered: bool = false

func _ready():
	if GameManager.current_mode != GameManager.GameMode.TIME_TRIAL:
		queue_free()
		return

	# Conectăm semnalul global de start
	GameManager.race_started.connect(_on_race_started_signal)

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
			
			# Poziționăm fantoma vizual la linia de start (cadrul 0) în stare de așteptare
			if telemetry_data.size() > 0:
				_apply_frame(telemetry_data[0])
			
			# Dacă jucătorul a plecat deja în timp ce descărcam, pornim playback-ul direct
			if is_race_triggered:
				start_playback()
	elif response_code == 404:
		queue_free()

func _on_race_started_signal():
	is_race_triggered = true
	if is_download_complete:
		start_playback()

func start_playback():
	if telemetry_data.size() < 2: return
	current_time = 0.0 # <--- Sincronizare perfectă cu HUD-ul (0.0)
	current_frame_index = 0
	is_playing = true

func _process(delta: float):
	if not is_playing: return
	
	current_time += delta
	
	# Căutăm cadrele între care ne aflăm în funcție de current_time
	while current_frame_index < telemetry_data.size() - 1 and telemetry_data[current_frame_index + 1].t < current_time:
		current_frame_index += 1
		
	if current_frame_index >= telemetry_data.size() - 1:
		is_playing = false
		return
		
	# Interpolare liniară (LERP/SLERP) pentru mișcare fluidă între cadre
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

# Funcție utilitară pentru a seta poziția inițială
func _apply_frame(frame: Dictionary):
	global_position = Vector3(frame.px, frame.py, frame.pz)
	quaternion = Quaternion(frame.rx, frame.ry, frame.rz, frame.rw)

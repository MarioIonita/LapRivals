extends HTTPRequest

var server_url = "http://127.0.0.1:8000/api/v1/upload_race"

func _ready():
	if not request_completed.is_connected(_on_request_completed):
		request_completed.connect(_on_request_completed)

func send_telemetry_data(track_id: int, final_time: float, telemetry_array: Array):
	print("LOG [Network]: Pregatim pachetul JSON securizat pentru server...")
	
	var data = {
		"track_id": track_id,
		"final_time": final_time,
		"game_mode": GameManager.get_mode_string(), 
		"telemetry": telemetry_array
	}
	
	var json_query = JSON.stringify(data)
	
	var headers = GameManager.get_auth_headers()
	
	var error = request(server_url, headers, HTTPClient.METHOD_POST, json_query)
	
	if error != OK:
		print("EROARE CRITICA: Godot nu a putut initia cererea HTTP. Cod eroare: ", error)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var response_json = JSON.parse_string(body.get_string_from_utf8())
		print("SUCCES! Datele au ajuns in Postgres. Serverul a raspuns: ", response_json)
	else:
		print("EROARE LA SERVER! Cod HTTP: ", response_code)
		print("Mesaj server: ", body.get_string_from_utf8())

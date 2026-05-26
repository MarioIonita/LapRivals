extends HTTPRequest

var server_url = "http://127.0.0.1:8000/api/v1/upload_race"

func _ready() -> void:
	if not request_completed.is_connected(_on_request_completed):
		request_completed.connect(_on_request_completed)
		print("LOG [Network]: HTTPRequest signal connected successfully.")

func send_telemetry_data(track_id: int, final_time: float, telemetry_array: Array):
	if not request_completed.is_connected(_on_request_completed):
		request_completed.connect(_on_request_completed)

	print("LOG [Network]: Preparing the secured JSON package for server...")
	
	var data = {
		"track_id": track_id,
		"final_time": final_time,
		"game_mode": "TIME_TRIAL",
		"telemetry": telemetry_array
	}
	
	var json_query = JSON.stringify(data)
	var headers = GameManager.get_auth_headers()
	
	var error = request(server_url, headers, HTTPClient.METHOD_POST, json_query)
	if error != OK:
		print("Critical Error: HTTP request not sent: ", error)
		return
		
	await request_completed
	print("LOG [Network]: The Request was completed.")
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("LOG [Network]: Response from server; Status code : ", response_code)
	
	if response_code == 200 or response_code == 201:
		var response_json = JSON.parse_string(body.get_string_from_utf8())
		print("SUCCESS! Data has been sent to PostGres; Response : ", response_json)
	elif response_code == 401:
		print("EROARE REȚEA (401 Unauthorized): Token-ul noului user este invalid sau expirat!")
		print("Detalii server: ", body.get_string_from_utf8())
	elif response_code == 422:
		print("EROARE REȚEA (422 Unprocessable Entity): Structura JSON-ului trimis din Godot nu se potrivește cu schema din FastAPI!")
		print("Detalii validare Python: ", body.get_string_from_utf8())
	else:
		print("EROARE LA SERVER! Cod HTTP neașteptat: ", response_code)
		print("Mesaj brut de la server: ", body.get_string_from_utf8())

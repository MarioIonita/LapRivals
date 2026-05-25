extends HTTPRequest

var server_url = "http://127.0.0.1:8000/api/v1/upload_race"

func _ready() -> void:
	# Conectăm semnalul nativ al nodului HTTPRequest către funcția noastră de procesare
	if not request_completed.is_connected(_on_request_completed):
		request_completed.connect(_on_request_completed)
		print("LOG [Network]: Semnalul HTTPRequest a fost conectat cu succes la start.")

func send_telemetry_data(track_id: int, final_time: float, telemetry_array: Array):
	if not request_completed.is_connected(_on_request_completed):
		request_completed.connect(_on_request_completed)

	print("LOG [Network]: Pregatim pachetul JSON securizat pentru server...")
	
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
		print("EROARE CRITICA: Cererea HTTP nu a putut pleca: ", error)
		return
		
	# Îi spunem funcției să AȘTEPTE până când semnalul nativ request_completed este emis
	await request_completed
	print("LOG [Network]: Request-ul s-a finalizat complet în siguranță.")
# --- FUNCȚIA DE CALLBACK CONECTATĂ (LIPSĂ ÎN RULAREA ANTERIOARĂ) ---
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("LOG [Network]: Răspuns primit de la server! Cod status HTTP: ", response_code)
	
	if response_code == 200 or response_code == 201:
		var response_json = JSON.parse_string(body.get_string_from_utf8())
		print("SUCCES! Datele au ajuns în Postgres. Serverul a răspuns: ", response_json)
	elif response_code == 401:
		print("EROARE REȚEA (401 Unauthorized): Token-ul noului user este invalid sau expirat!")
		print("Detalii server: ", body.get_string_from_utf8())
	elif response_code == 422:
		print("EROARE REȚEA (422 Unprocessable Entity): Structura JSON-ului trimis din Godot nu se potrivește cu schema din FastAPI!")
		print("Detalii validare Python: ", body.get_string_from_utf8())
	else:
		print("EROARE LA SERVER! Cod HTTP neașteptat: ", response_code)
		print("Mesaj brut de la server: ", body.get_string_from_utf8())

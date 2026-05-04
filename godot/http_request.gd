extends HTTPRequest

# URL-ul unde rulează serverul tău FastAPI (schimbă portul dacă e diferit de 8000)
var server_url = "http://127.0.0.1:8000/api/v1/upload_race"

func send_telemetry_data(user_id: int, track_id: int, final_time: float, telemetry_array: Array):
	# 1. Împachetăm datele conform modelului Pydantic din Python
	var data = {
		"user_id": user_id,
		"track_id": track_id,
		"final_time": final_time,
		"telemetry": telemetry_array
	}
	# 2. Convertim dicționarul în string JSON
	var json_query = JSON.stringify(data)
	
	# 3. Setăm headerele HTTP (esențial pentru ca FastAPI să știe că primește JSON)
	var headers = ["Content-Type: application/json"]
	
	# 4. Trimitem cererea POST (non-blocking)
	request(server_url, headers, HTTPClient.METHOD_POST, json_query)

# Callback care rulează când serverul răspunde
func _on_request_completed(result, response_code, headers, body):
	var response = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		print("Serverul a confirmat: ", response["message"])
	else:
		print("Eroare comunicare: ", response_code)

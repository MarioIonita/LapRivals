extends Control

# --- UI References ---
@onready var username_input = %UsernameInput
@onready var password_input = %PasswordInput
@onready var status_label = %StatusLabel
@onready var login_http = %LoginRequest
@onready var register_http = %RegisterRequest

# Adjust to localhost if 127.0.0.1 causes DNS resolution delays on your OS
const BASE_URL = "http://127.0.0.1:8000/api/v1/users"

func _ready():
	# Connect button signals programmatically
	%LoginBtn.pressed.connect(_on_login_pressed)
	%RegisterBtn.pressed.connect(_on_register_pressed)
	
	# Connect HTTP request callbacks
	login_http.request_completed.connect(_on_login_completed)
	register_http.request_completed.connect(_on_register_completed)
	
	status_label.text = "SYSTEM: Awaiting user input..."

# --- 1. Button Logic ---
func _on_login_pressed():
	if not validate_inputs(): return
	status_label.text = "SYSTEM: Querying server for authentication..."
	
	var body = JSON.stringify({"username": username_input.text, "password": password_input.text})
	var headers = ["Content-Type: application/json"]
	login_http.request(BASE_URL + "/login", headers, HTTPClient.METHOD_POST, body)

func _on_register_pressed():
	if not validate_inputs(): return
	status_label.text = "SYSTEM: Registering new user..."
	
	var body = JSON.stringify({"username": username_input.text, "password": password_input.text})
	var headers = ["Content-Type: application/json"]
	register_http.request(BASE_URL + "/register", headers, HTTPClient.METHOD_POST, body)

# --- 2. Input Validation ---
func validate_inputs() -> bool:
	if username_input.text.is_empty() or password_input.text.is_empty():
		status_label.text = "ERROR: Both fields are required."
		return false
	if password_input.text.length() < 6:
		status_label.text = "ERROR: Password must be at least 6 characters."
		return false
	return true

# --- 3. Callbacks (Server Response) ---
func _on_login_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		
		# Inseram datele direct in cheile dictionarului
		GameManager.session["token"] = json["access_token"]
		GameManager.session["user_id"] = int(json["user_id"])
		
		print("Login successful.")
		
		get_tree().change_scene_to_file("res://main_menu.tscn")
	else:
		_handle_error(body, response_code)

func _on_register_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		status_label.text = "SUCCESS: Account created. You may now log in."
		# Clear password field for UX security
		password_input.text = "" 
		print("LOG [Auth]: New user registered successfully.")
	else:
		_handle_error(body, response_code)

# --- 4. Error Handling ---
func _handle_error(body: PackedByteArray, response_code: int):
	if response_code == 0:
		status_label.text = "FATAL ERROR: FastAPI server is unreachable."
		print("ERROR [Network]: Connection refused (Code 0). Is the local server running?")
		return
		
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and json.has("detail"):
		var error_msg = str(json["detail"])
		status_label.text = "ERROR (" + str(response_code) + "): " + error_msg
		print("ERROR [Auth]: Server rejected request. Code " + str(response_code) + " -> " + error_msg)
	else:
		status_label.text = "UNKNOWN ERROR: Code " + str(response_code)
		print("ERROR [Auth]: Unhandled exception with HTTP code " + str(response_code))

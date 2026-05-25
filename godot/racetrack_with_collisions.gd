extends Node3D

@export var ghost_car_scene: PackedScene 

var swarm_http_client: HTTPRequest

func _ready():
	print("Circuit Log: The race was loaded in: ", GameManager.current_mode)
	
	match GameManager.current_mode:
		GameManager.GameMode.TIME_TRIAL:
			setup_time_trial()
		GameManager.GameMode.SINGLE_PLAYER:
			setup_single_player_race()
		GameManager.GameMode.MULTIPLAYER:
			setup_multiplayer_race()

func setup_time_trial():
	get_tree().call_group("Opponents", "queue_free")
	print("Circuit Log:  Time Trial. Player vs Ghost.")

func setup_single_player_race():
	print("Circuit Log: Single Player")
	
	swarm_http_client = HTTPRequest.new()
	add_child(swarm_http_client)
	swarm_http_client.request_completed.connect(_on_swarm_data_received)
	
	# 2. Trimitem cererea către noul endpoint din FastAPI pentru a lua grupul de boți
	var url = "http://127.0.0.1:8000/api/v1/get_swarm_data/" + str(GameManager.current_track_id)
	var headers = GameManager.get_auth_headers()
	swarm_http_client.request(url, headers, HTTPClient.METHOD_GET)

func setup_multiplayer_race():
	get_tree().call_group("Opponents", "queue_free")
	print("Circuit Log: Multiplayer")


func _on_swarm_data_received(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	get_tree().call_group("Opponents", "queue_free")
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("swarm"):
			var bots_array = json["swarm"]
			
			if bots_array.size() == 0:
				print("Circuit Log: No bot data in DB.")
				return
				
			# Culorile pentru cei doi boți
			var bot_colors = [Color.RED, Color.GOLD]
			var bot_speeds = [1.0, 0.8] 
			
			for i in range(2):
				var bot_info = bots_array[i if i < bots_array.size() else 0]
				
				var bot_node = ghost_car_scene.instantiate()
				
				bot_node.telemetry_data = bot_info["telemetry"]
				bot_node.is_download_complete = true  
				
				bot_node.speed_multiplier = bot_speeds[i] 
				
				add_child(bot_node)
				
				bot_node.set_car_color(bot_colors[i])
				
				if bot_node.telemetry_data.size() > 0:
					bot_node._apply_frame(bot_node.telemetry_data[0])
					
	else:
		print("Circuit Log ERROR: Response Code: ", response_code)

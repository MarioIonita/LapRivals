extends Node3D

@export var network_car_scene: PackedScene 

var active_opponents: Dictionary = {}

func _ready() -> void:
	if GameManager.current_mode == GameManager.GameMode.MULTIPLAYER:
		WSClient.data_received.connect(_on_network_payload_received)
		print("[MultiplayerManager] Sync node active. Waiting for telemetry...")

func _on_network_payload_received(payload: Dictionary) -> void:
	var cid = payload["client_id"]
	
	if payload.has("type") and payload["type"] == "disconnect":
		if active_opponents.has(cid):
			if is_instance_valid(active_opponents[cid]):
				active_opponents[cid].queue_free()
			active_opponents.erase(cid)
			print("[MultiplayerManager] Player ", cid, " has left. The car has been deleted.")
		return
		
	if active_opponents.has(cid) and not is_instance_valid(active_opponents[cid]):
		active_opponents.erase(cid)
		print("[MultiplayerManager]  Zombie ID: ", cid)
		
	if not active_opponents.has(cid):
		var new_enemy = network_car_scene.instantiate()
		add_child(new_enemy)
		active_opponents[cid] = new_enemy
		print("[MultiplayerManager] New competitor spawned! Spawned car for Client ID: ", cid)
		
		if "is_download_complete" in new_enemy:
			new_enemy.is_download_complete = true 
			new_enemy.is_playing = false
			new_enemy.set_process(false) 
			new_enemy.set_physics_process(false)
			
		new_enemy.visible = true
		if new_enemy.has_method("show"):
			new_enemy.show()
			
	var enemy_car = active_opponents[cid]
	if not is_instance_valid(enemy_car) or not enemy_car.is_inside_tree():
		return
		
	var target_pos = Vector3(payload["px"], payload["py"], payload["pz"])
	var target_rot = Quaternion(payload["rx"], payload["ry"], payload["rz"], payload["rw"])
	
	if Engine.get_frames_drawn() % 100 == 0:
		print("Updating the enemy ", cid, " at location: ", target_pos)
	
	enemy_car.global_position = target_pos
	enemy_car.quaternion = target_rot

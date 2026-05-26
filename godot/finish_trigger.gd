extends Area3D

@export var hud: CanvasLayer 
@onready var telemetry_client = %TelemetryClient

func _on_body_entered(body: Node3D) -> void:
	if body.name == "PlayerCar1" or body.get_parent().name == "PlayerCar1":
		var masina = body if body.name == "PlayerCar1" else body.get_parent()
		
		if not hud.is_racing:
			hud.start_race()
			masina.start_recording() 
			GameManager.race_started.emit() 
			print("[FinishLine] START! Timer and telemetry started.")
		else:
			var final_time = hud.stop_race()
			var raw_telemetry = masina.stop_recording().duplicate()
			
			print("[FinishLine] FINISH! Final time: ", final_time)
			
			if GameManager.current_mode != GameManager.GameMode.MULTIPLAYER:
				if telemetry_client and final_time > 12.0:
					print("[FinishLine] TRIGGER LOG: Sending telemetry to server...")
					await telemetry_client.send_telemetry_data(GameManager.current_track_id, final_time, raw_telemetry)
			
			if hud.has_method("show_results"):
				hud.show_results(final_time)

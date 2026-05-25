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
			print("START! Cronometrul și telemetria au pornit.")
			
		else:
			var final_time = hud.stop_race()
			var raw_telemetry = masina.stop_recording()
			
			print("FINISH! Timp realizat: ", final_time)
			
			if telemetry_client:
				if final_time > 12:
					telemetry_client.send_telemetry_data(101, final_time, raw_telemetry)
					hud.show_results(final_time)
			
			hud.start_race()
			masina.start_recording()
			
			GameManager.race_started.emit() 

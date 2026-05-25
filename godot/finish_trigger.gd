extends Area3D

@export var hud: CanvasLayer 
@onready var telemetry_client = %TelemetryClient

func _on_body_entered(body: Node3D) -> void:
	if body.name == "PlayerCar1" or body.get_parent().name == "PlayerCar1":
		var masina = body if body.name == "PlayerCar1" else body.get_parent()
		
		# --- LOGICA DE START ---
		if not hud.is_racing:
			hud.start_race()
			masina.start_recording() 
			
			GameManager.race_started.emit() 
			print("START! Cronometrul și telemetria au pornit.")
			
		# --- LOGICA DE FINISH ---
		else:
			var final_time = hud.stop_race()
			# CRITIC: Folosim .duplicate() pentru a clona array-ul în memorie. 
			# Astfel, dacă mașina își dă reset, datele trimise la rețea rămân intacte!
			var raw_telemetry = masina.stop_recording().duplicate()
			
			print("FINISH! Timp realizat: ", final_time)
			
			if telemetry_client and final_time > 12.0:
				print("TRIGGER LOG: Tritem datele catre server...")
				await telemetry_client.send_telemetry_data(GameManager.current_track_id, final_time, raw_telemetry)
			
			# Verificăm în ce mod de joc ne aflăm pentru a ști cum reacționăm la final
			if GameManager.current_mode == GameManager.GameMode.TIME_TRIAL or GameManager.current_mode == GameManager.GameMode.SINGLE_PLAYER:
				# Afișăm caseta cu rezultate peste gameplay și punem PAUZĂ (așa cum ai cerut)
				# Jucătorul va da manual click pe Replay sau Meniu, deci NU mai repornim cursa automat dedesubt!
				if hud.has_method("show_results"):
					hud.show_results(final_time)
			else:
				# Doar dacă ai fi pe un mod gen Arcade/Endless reporneai cursa instant la trecerea liniei
				hud.start_race()
				masina.start_recording()
				GameManager.race_started.emit()

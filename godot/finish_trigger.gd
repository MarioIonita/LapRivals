extends Area3D

@export var hud: CanvasLayer 

func _on_body_entered(body: Node3D) -> void:
	# Verificăm dacă obiectul care a intrat este mașina jucătorului
	if body.name == "PlayerCar1" or body.get_parent().name == "PlayerCar1":
		
		# 1. Identificăm instanța corectă a mașinii
		var masina = body if body.name == "PlayerCar1" else body.get_parent()
		
		# Referință către TelemetryClient (conform ierarhiei tale din imagini)
		# Folosim get_node pentru a evita eroarea "null instance"
		var telemetry_client = hud.get_node("TelemetryClient")
		
		if not hud.is_racing:
			# --- CAZ DE UTILIZARE: Start Cursă ---[cite: 1]
			hud.start_race()
			masina.start_recording() # Pornește colectarea datelor în player_car_1.gd[cite: 1]
			print("START! Cronometrul și telemetria au pornit.")
			
		else:
			# --- CAZ DE UTILIZARE: Finalizare Cursă ---[cite: 1]
			# 2. Oprim cronometrul și colectăm datele[cite: 1]
			var final_time = hud.stop_race()
			
			# Folosim funcția de stop a mașinii care returnează array-ul complet[cite: 1]
			var raw_telemetry = masina.stop_recording()
			
			print("FINISH! Timp realizat: ", final_time)
			
			# 3. Trimitem datele către backend-ul Python (Postgres)[cite: 1]
			if telemetry_client:
				# user_id 1 și track_id 101 sunt temporare până la implementarea Login-ului[cite: 1]
				telemetry_client.send_telemetry_data(1, 101, final_time, raw_telemetry)
			else:
				print("EROARE: Nu am găsit nodul TelemetryClient sub HUD!")
			
			# 4. Resetăm pentru un tur nou (Continuous Lap)[cite: 1]
			hud.start_race()
			masina.start_recording()

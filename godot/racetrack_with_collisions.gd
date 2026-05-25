extends Node3D

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
	

func setup_multiplayer_race():
	get_tree().call_group("Opponents", "queue_free")
	print("Circuit Log: Multiplayer")

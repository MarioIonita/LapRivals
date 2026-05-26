extends Control

const TRACK_SCENE_PATH = "res://racetrack_with_collisions.scn"

func _on_time_trial_pressed():
	GameManager.current_mode = GameManager.GameMode.TIME_TRIAL
	get_tree().change_scene_to_file(TRACK_SCENE_PATH)

func _on_single_player_pressed():
	GameManager.current_mode = GameManager.GameMode.SINGLE_PLAYER
	get_tree().change_scene_to_file(TRACK_SCENE_PATH)

func _on_multi_player_pressed():
	print("It works")
	GameManager.current_mode = GameManager.GameMode.MULTIPLAYER
	get_tree().change_scene_to_file(TRACK_SCENE_PATH)

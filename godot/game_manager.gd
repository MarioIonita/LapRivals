extends Node

signal race_started
enum GameMode { TIME_TRIAL, SINGLE_PLAYER, MULTIPLAYER }

var current_mode: GameMode = GameMode.TIME_TRIAL
var current_track_id: int = 101

var session: Dictionary = {
	"token": "",
	"user_id": 0
}

func get_auth_headers() -> PackedStringArray:
	if session["token"] == "":
		return PackedStringArray(["Content-Type: application/json"])
	
	return PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + session["token"]
	])

func get_mode_string() -> String:
	match current_mode:
		GameMode.TIME_TRIAL: return "TIME_TRIAL"
		GameMode.SINGLE_PLAYER: return "SINGLE_PLAYER"
		GameMode.MULTIPLAYER: return "MULTIPLAYER"
	return "UNKNOWN"

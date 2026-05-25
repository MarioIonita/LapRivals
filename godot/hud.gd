extends CanvasLayer

@onready var timer_label: Label = $TimerLabel 

var time_elapsed: float = 0.0
var is_racing: bool = false

func _process(delta: float) -> void:
	if is_racing:
		time_elapsed += delta
		_update_ui()

func _update_ui() -> void:
	var minutes: int = int(time_elapsed / 60.0)
	var seconds: int = int(time_elapsed) % 60
	var milliseconds: int = int(fmod(time_elapsed, 1.0) * 100)
	timer_label.text = "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

func start_race() -> void:
	time_elapsed = 0.0
	is_racing = true

func stop_race() -> float:
	is_racing = false
	return time_elapsed

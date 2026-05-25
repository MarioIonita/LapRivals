extends CanvasLayer

@onready var timer_label: Label = $TimerLabel 

# --- NOILE REFERINȚE PENTRU MODAL POPUP ---
@onready var dim_overlay: ColorRect = $DimOverlay
@onready var results_popup: PanelContainer = $ResultsPopup
@onready var final_time_label: Label = %FinalTimeLabel

var time_elapsed: float = 0.0
var is_racing: bool = false

func _ready() -> void:
	# Ne asigurăm că panoul este ascuns când pornește scena
	if dim_overlay: dim_overlay.hide()
	if results_popup: results_popup.hide()
	
	# Conectăm semnalele butoanelor (folosind Unique Names cu %)
	%ReplayBtn.pressed.connect(_on_replay_pressed)
	%MenuBtn.pressed.connect(_on_menu_pressed)

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

# --- NOUA FUNCȚIE CARE AFIȘEAZĂ REZULTATELE ȘI PUNE PAUZĂ ---
func show_results(final_time: float) -> void:
	# Formatăm timpul final exact în același stil ca pe ecran
	var minutes: int = int(final_time / 60.0)
	var seconds: int = int(final_time) % 60
	var milliseconds: int = int(fmod(final_time, 1.0) * 100)
	final_time_label.text = "Final Time: %02d:%02d:%02d" % [minutes, seconds, milliseconds]
	
	# Afișăm elementele vizuale
	dim_overlay.show()
	results_popup.show()
	
	# Înghețăm engine-ul (fizica, physics_process, etc.) și eliberăm mouse-ul
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --- CALLBACKS PENTRU BUTOANE ---
func _on_replay_pressed() -> void:
	get_tree().paused = false # IMPORTANT: Scoatem pauza înainte de reîncărcare!
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

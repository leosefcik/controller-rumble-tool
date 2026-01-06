extends TabBar

@export var PATTERN_MAKER : HBoxContainer

# Idk why i called them rows. They're columns
const ROWS := 4

# [row node 0-3][0: Duration, 1: Pause, 2: Indicator]
var PATTERN_NODES := []

var current_tact := 0
var time_elapsed := 0.0
var playing := false

@onready var MAIN := get_node("/root/Main")


func _ready() -> void:
	_setup_row_nodes()


func _setup_row_nodes() -> void:
	for i in range(ROWS):
		var current_node := PATTERN_MAKER.get_node(str("Row", i+1))
		PATTERN_NODES.append({
			"Duration": current_node.get_node("Duration"),
			"Pause": current_node.get_node("Pause"),
			"Indicator": current_node.get_node("Indicator"),
		})


func _process(delta: float) -> void:
	if not visible: return # Only if on tab
	
	if playing:
		#Input.start_joy_vibration(MAIN.controller_id, 0.2, 0.2, 0.0)
		pass

func _on_preset_button_pressed() -> void:
	PATTERN_NODES[0]["Duration"].value = 1.0
	PATTERN_NODES[0]["Pause"].value = 1.0
	PATTERN_NODES[1]["Duration"].value = 0.5
	PATTERN_NODES[1]["Pause"].value = 0.5


func _on_play_pause_toggled(toggled_on: bool) -> void:
	playing = toggled_on

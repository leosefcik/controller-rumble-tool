extends TabBar

@export var PATTERN_MAKER : HBoxContainer
@export var UI: Control

# Idk why i called them rows. They're columns
# hardcoded max, if i ever wanted to expand it i could go ahead
# (and add more corresponding spinboxes too)
const ROWS := 4

var PATTERN_NODES := [] # [row node 0-3][0: Duration, 1: Pause, 2: Indicator]
var tact_amount := 1
var durations := [0.0, 0.0, 0.0, 0.0]
var pauses := [0.0, 0.0, 0.0, 0.0]

var current_tact := 0
var time_elapsed := 0.0 # used to time tacts
var playing := false # play button
var duration_phase := true # if in first (duration) or second (pause) phase of the tact

# Unused
var complex_tacts := true # option to switch between progress/dot tacts

# Desired - where the controls point to
var weak_desired := 0.0
var strong_desired := 0.0
# Power - current power of controller motors
var weak_power := 0.0
var strong_power := 0.0

var speed_slider := 1.0 # Updated externally by ProgramMouseControl

func _setup_row_nodes_array() -> void:
	for i in range(ROWS):
		var current_node := PATTERN_MAKER.get_node(str("Row", i+1))
		PATTERN_NODES.append({
			"Duration": current_node.get_node("Duration"),
			"Pause": current_node.get_node("Pause"),
			"Indicator": current_node.get_node("Indicator"),
			"DurationProgress": current_node.get_node("Indicators/DurationProgress"),
			"PauseProgress": current_node.get_node("Indicators/PauseProgress"),
		})
		PATTERN_NODES[i]["Duration"].value_changed.connect(_on_any_spinbox_value_changed)
		PATTERN_NODES[i]["Pause"].value_changed.connect(_on_any_spinbox_value_changed)


func _ready() -> void:
	_setup_row_nodes_array()
	_update_pattern_box_editability()
	_reset_tact_indicators()


### PLAYING

func _process(delta: float) -> void:
	if not visible: return # Only if on tab
	
	_process_controls(delta)
	
	if playing:
		time_elapsed += delta
		_play_program()
	
	_process_rumble()


func _play_program() -> void:
	_update_current_tact_indicator()
	
	if duration_phase and time_elapsed > durations[current_tact]:
		time_elapsed = 0.0
		if pauses[current_tact] != 0.0:
			duration_phase = false
		else:
			duration_phase = true
			current_tact += 1
	
	elif not duration_phase and time_elapsed > pauses[current_tact]:
		duration_phase = true
		time_elapsed = 0.0
		current_tact += 1
	
	if current_tact >= tact_amount:
		current_tact = 0
		_reset_tact_indicators()
	
	if duration_phase:
		%RumbleIndicator.modulate = Color.WHITE
	else:
		%RumbleIndicator.modulate = Color.DIM_GRAY


func _process_rumble() -> void:
	if Settings.weak_locked:
		pass
	elif not playing or not duration_phase:
		weak_power = 0.0
	else:
		weak_power = weak_desired
	
	if Settings.strong_locked:
		pass
	elif not playing or not duration_phase:
		strong_power = 0.0
	else:
		strong_power = strong_desired
	
	if Settings.incremented:
		weak_power = snappedf(weak_power, 0.1)
		strong_power = snappedf(strong_power, 0.1)
	
	Settings.rumble(weak_power, strong_power)
	UI.update_power_gauges(weak_power, strong_power)


func _reset_progress() -> void:
	time_elapsed = 0.0
	current_tact = 0
	duration_phase = true
	_reset_tact_indicators()


func _flip_desired_values() -> void:
	var m := weak_desired
	weak_desired = strong_desired
	strong_desired = m
	UI.update_desired_gauges(weak_desired, strong_desired)


### PATTERN LOGIC

# Stored Tact amount --> SpinBox editability
func _update_pattern_box_editability() -> void:
	for i in range(ROWS):
		PATTERN_NODES[i]["Duration"].editable = false
		PATTERN_NODES[i]["Pause"].editable = false
	
	for i in range(tact_amount):
		PATTERN_NODES[i]["Duration"].editable = true
		PATTERN_NODES[i]["Pause"].editable = true

# Stored dur/pause values --> SpinBox values
func _update_pattern_box_values() -> void:
	for i in range(ROWS):
		PATTERN_NODES[i]["Duration"].set_value_no_signal(durations[i])
		PATTERN_NODES[i]["Pause"].set_value_no_signal(pauses[i])

# SpinBox values --> Stored dur/pause values
func _update_pattern_stored_values() -> void:
	for i in range(ROWS):
		durations[i] = PATTERN_NODES[i]["Duration"].value
		pauses[i] = PATTERN_NODES[i]["Pause"].value

# Resets the little indicators below the tacts to a clean slate
func _reset_tact_indicators() -> void:
	if complex_tacts: # complex, progress tacts
		for i in PATTERN_NODES:
			i["DurationProgress"].value = 0.0
			i["PauseProgress"].value = 0.0
	
	else:
		pass

func _update_current_tact_indicator() -> void:
	if complex_tacts: # complex, progress tacts
		if duration_phase:
			var progress: float = time_elapsed / durations[current_tact]
			PATTERN_NODES[current_tact]["DurationProgress"].value = progress
		else:
			var progress: float = time_elapsed / pauses[current_tact]
			PATTERN_NODES[current_tact]["PauseProgress"].value = progress


### Controls

func _process_controls(delta: float) -> void:
	var left_axis := 0.0
	var right_axis := 0.0
	var weak_axis := 0.0
	var strong_axis := 0.0
	var speed_mod := 1.0
	
	if Settings.trigger_enabled: # Speed modifier triggers for fun
		if Input.is_action_pressed("increase_rumble_trigger_left"):
			speed_mod *= (1.0/3.0)
		if Input.is_action_pressed("increase_rumble_trigger_right"):
			speed_mod *= 3.0
	
	if Settings.joystick_enabled:
		left_axis = Input.get_axis("decrease_rumble_left", "increase_rumble_left")
		right_axis = Input.get_axis("decrease_rumble_right", "increase_rumble_right")
		left_axis = clampf(left_axis / Settings.control_sensitivty, -1.0, 1.0)
		right_axis = clampf(right_axis / Settings.control_sensitivty, -1.0, 1.0)
	
	# Mapping the controls
	if Settings.coupled:
		var combined_desired := clampf(left_axis + right_axis, -1.0, 1.0)
		weak_axis = combined_desired
		strong_axis = combined_desired
	elif not Settings.flipped:
		weak_axis = left_axis
		strong_axis = right_axis
	else:
		weak_axis = right_axis
		strong_axis = left_axis
	
	weak_axis = clampf(weak_axis + %WeakSliderProgram.value, -1.0, 1.0)
	strong_axis = clampf(strong_axis + %StrongSliderProgram.value, -1.0, 1.0)
	
	weak_desired = clampf(weak_desired + (weak_axis * delta * speed_mod * speed_slider), 0.0, 1.0)
	strong_desired = clampf(strong_desired + (strong_axis * delta * speed_mod * speed_slider), 0.0, 1.0)
	UI.update_desired_gauges(weak_desired, strong_desired)


### INPUT

func _input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("pause_resume_rumble"):
			%PlayPause.button_pressed = !%PlayPause.button_pressed
		elif event.is_action_pressed("flip_desired_values"):
			_flip_desired_values()
			%FlipControls.button_pressed = !%FlipControls.button_pressed
		elif event.is_action_pressed("couple_motors"):
			var big := maxf(weak_desired, strong_desired)
			weak_desired = big
			strong_desired = big


### UI

func _on_play_pause_toggled(toggled_on: bool) -> void:
	playing = toggled_on
	if toggled_on:
		%RumbleIndicator.modulate = Color.WHITE
	else:
		%RumbleIndicator.modulate = Color.DARK_RED


func _on_half_all_tacts_pressed() -> void:
	for i in range(ROWS):
		durations[i] *= 0.5
		pauses[i] *= 0.5
	_update_pattern_box_values()

func _on_double_all_tacts_pressed() -> void:
	for i in range(ROWS):
		durations[i] *= 2
		pauses[i] *= 2
	_update_pattern_box_values()


func _on_tact_amount_value_changed(value: float) -> void:
	tact_amount = int(value)
	_update_pattern_box_editability()


func _on_any_spinbox_value_changed(_value: float) -> void:
	_update_pattern_stored_values()


"""
func _on_simple_tact_toggle_pressed() -> void:
	if %SimpleTactToggle.text == "C": # From complex to simple
		complex_tacts = false
		%SimpleTactToggle.text = "S"
		for i in PATTERN_NODES:
			i["DurationProgress"].hide()
			i["PauseProgress"].hide()
			i["Indicator"].show()
	
	else: # From simple to complex
		complex_tacts = true
		%SimpleTactToggle.text = "C"
		for i in PATTERN_NODES:
			i["DurationProgress"].show()
			i["PauseProgress"].show()
			i["Indicator"].hide()
"""


### OTHER UI

func _on_preset_button_pressed() -> void:
	durations = [1.0, 0.5, 0.0, 0.0]
	pauses = [1.0, 0.5, 0.0, 0.0]
	%TactAmount.value = 2
	_update_pattern_box_values()
	_reset_progress()

func _on_preset_2_button_pressed() -> void:
	durations = [0.4, 0.4, 0.8, 0.8]
	pauses = [0.8, 0.8, 0.4, 0.4]
	#durations = [1,1,2,2]
	#pauses = [2,2,1,1]
	%TactAmount.value = 4
	_update_pattern_box_values()
	_reset_progress()

func _on_clear_button_pressed() -> void:
	durations = [0.0, 0.0, 0.0, 0.0]
	pauses = [0.0, 0.0, 0.0, 0.0]
	%TactAmount.value = 1
	_update_pattern_box_values()
	_reset_progress()

extends TabBar

@export var PATTERN_MAKER : HBoxContainer
@export var UI: Control

# Idk why i called them rows. They're columns
# hardcoded max, if i ever wanted to expand it i could go ahead
# (and add more corresponding spinboxes too)
const ROWS := 4
const MAX_LENGTH := 900000.0

var PATTERN_NODES := [] # [row node 0-3][0: Duration, 1: Pause, 2: Indicator]
var tact_amount := 1
var durations := [0.0, 0.0, 0.0, 0.0]
var pauses := [0.0, 0.0, 0.0, 0.0]
var flips := [false, false, false, false]

var current_tact := 0
var time_elapsed := 0.0 # used to time tacts
var playing := false # play button
var looping := true
var duration_phase := true # if in first (duration) or second (pause) phase of the tact
var timescale := 1.0

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
			"Indicator": current_node.get_node("Indicator"), # old unused indicator
			"DurationProgress": current_node.get_node("Indicators/DurationProgress"),
			"PauseProgress": current_node.get_node("Indicators/PauseProgress"),
			"Flip": PATTERN_MAKER.get_node(str("Flip", i+1))
		})
		PATTERN_NODES[i]["Duration"].value_changed.connect(_on_any_spinbox_value_changed)
		PATTERN_NODES[i]["Pause"].value_changed.connect(_on_any_spinbox_value_changed)
		PATTERN_NODES[i]["Flip"].toggled.connect(_on_any_flip_value_changed)


func _ready() -> void:
	_setup_row_nodes_array()
	_update_pattern_box_editability()
	_reset_tact_indicators()


### PLAYING

func _process(delta: float) -> void:
	if not visible: return # Only if on tab
	
	_process_controls(delta)
	
	if playing:
		time_elapsed += delta*timescale*1000 # second to millisecond
		_play_program()
	
	_process_rumble()


func _play_program() -> void:
	_update_current_tact_indicator()
	
	if duration_phase and time_elapsed > durations[current_tact]:
		time_elapsed = minf(time_elapsed - durations[current_tact], 1000.0) #capped to prevent it from taking too long in case of a large overflow
		if pauses[current_tact] != 0.0:
			duration_phase = false
		else:
			duration_phase = true
			_increment_tact()
	
	elif not duration_phase and time_elapsed > pauses[current_tact]:
		duration_phase = true
		time_elapsed = minf(time_elapsed - pauses[current_tact], 1000.0)
		_increment_tact()
	
	if duration_phase:
		%RumbleIndicator.modulate = Color.WHITE
	else:
		%RumbleIndicator.modulate = Color.DIM_GRAY


func _increment_tact() -> void:
	current_tact += 1
	
	if current_tact >= tact_amount:
		current_tact = 0
		_reset_tact_indicators()
		if not looping:
			_stop_playing()
	
	if flips[current_tact]:
		_flip_controls_and_desired_values()

func _stop_playing() -> void:
	%PlayPause.button_pressed = false


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

func _flip_controls_and_desired_values() -> void:
	UI.flip_controls()
	_flip_desired_values()


### Controls

func _process_controls(delta: float) -> void:
	var left_axis := 0.0
	var right_axis := 0.0
	var weak_axis := 0.0
	var strong_axis := 0.0
	
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
	
	if Settings.trigger_enabled: # Hold trigger to change timescale instead
		if (Input.is_action_pressed("increase_rumble_trigger_left")
		or Input.is_action_pressed("increase_rumble_trigger_right")):
			var adder := clampf(weak_axis + strong_axis, -1.0, 1.0) * delta
			timescale = clampf(timescale + adder, 0.1, 10.0)
			_update_ui_timescale()
			return
	
	weak_axis = clampf(weak_axis + %WeakSliderProgram.value, -1.0, 1.0)
	strong_axis = clampf(strong_axis + %StrongSliderProgram.value, -1.0, 1.0)
	
	weak_desired = clampf(weak_desired + (weak_axis * delta  * speed_slider), 0.0, 1.0)
	strong_desired = clampf(strong_desired + (strong_axis * delta * speed_slider), 0.0, 1.0)
	UI.update_desired_gauges(weak_desired, strong_desired)







### PATTERN LOGIC

# Stored Tact amount --> SpinBox editability
func _update_pattern_box_editability() -> void:
	for i in range(ROWS):
		PATTERN_NODES[i]["Duration"].editable = false
		PATTERN_NODES[i]["Pause"].editable = false
		PATTERN_NODES[i]["Flip"].disabled = true
	
	for i in range(tact_amount):
		PATTERN_NODES[i]["Duration"].editable = true
		PATTERN_NODES[i]["Pause"].editable = true
		PATTERN_NODES[i]["Flip"].disabled = false

# Stored dur/pause values --> SpinBox values
func _update_ui_time_values() -> void:
	for i in range(ROWS):
		PATTERN_NODES[i]["Duration"].set_value_no_signal(durations[i])
		PATTERN_NODES[i]["Pause"].set_value_no_signal(pauses[i])

# SpinBox values --> Stored dur/pause values
func _update_stored_time_values() -> void:
	for i in range(ROWS):
		durations[i] = PATTERN_NODES[i]["Duration"].value
		pauses[i] = PATTERN_NODES[i]["Pause"].value

# Resets the little indicators below the tacts to a clean slate
func _reset_tact_indicators() -> void:
	for i in PATTERN_NODES:
		i["DurationProgress"].value = 0.0
		i["PauseProgress"].value = 0.0

func _update_current_tact_indicator() -> void:
	if duration_phase:
		var progress: float = time_elapsed / durations[current_tact]
		PATTERN_NODES[current_tact]["DurationProgress"].value = progress
	else:
		var progress: float = time_elapsed / pauses[current_tact]
		PATTERN_NODES[current_tact]["PauseProgress"].value = progress


### PATTERN LOGIC - FLIP

# Stored flip values --> Flip button values
func _update_ui_flip_values() -> void:
	for i in range(ROWS):
		PATTERN_NODES[i]["Flip"].set_pressed_no_signal(flips[i])

# Flip button values --> Stored flip values
func _update_stored_flip_values() -> void:
	for i in range(ROWS):
		flips[i] = PATTERN_NODES[i]["Flip"].button_pressed

# Only for the preset buttons
func import_flips(new_flips: Array) -> void:
	for i in range(ROWS):
		flips[i] = new_flips[i]
		_update_ui_flip_values()




### Timescale

func _on_timescale_slider_value_changed(value: float) -> void:
	timescale = value
	%TimescaleLabel.text = str(value)
	_check_timescale_reset_editability()

func _update_ui_timescale() -> void:
	%TimescaleSlider.set_value_no_signal(timescale)
	%TimescaleLabel.text = str(%TimescaleSlider.value)
	_check_timescale_reset_editability()

func _on_timescale_reset_pressed() -> void:
	timescale = 1.0
	_update_ui_timescale()
	%TimescaleReset.disabled = true

func _check_timescale_reset_editability() -> void:
	if timescale != 1.0:
		%TimescaleReset.disabled = false




### INPUT

func _input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("pause_resume_rumble"):
			%PlayPause.button_pressed = !%PlayPause.button_pressed
		elif event.is_action_pressed("flip_desired_values"):
			flip_intensities()

# Called by UI when Couple Motors switches
func couple_motors_sync() -> void:
	if visible:
		var big := maxf(weak_desired, strong_desired)
		weak_desired = big
		strong_desired = big

# Called by PresetPlaza or the control
func flip_intensities() -> void:
	_flip_controls_and_desired_values()


### UI

func _on_play_pause_toggled(toggled_on: bool) -> void:
	playing = toggled_on
	if toggled_on:
		%RumbleIndicator.modulate = Color.WHITE
	else:
		%RumbleIndicator.modulate = Color.DARK_RED


func _on_loop_program_toggled(toggled_on: bool) -> void:
	looping = toggled_on


func _on_half_all_tacts_pressed() -> void:
	for i in range(ROWS):
		durations[i] *= 0.5
		pauses[i] *= 0.5
	_update_ui_time_values()

func _on_double_all_tacts_pressed() -> void:
	for i in range(ROWS):
		durations[i] *= 2
		pauses[i] *= 2
	_update_ui_time_values()


func _on_tact_amount_value_changed(value: float) -> void:
	tact_amount = int(value)
	_update_pattern_box_editability()


func _on_any_spinbox_value_changed(_value: float) -> void:
	_update_stored_time_values()
	_spinboxes_suffix_fix()

func _on_any_flip_value_changed(_toggled: float) -> void:
	_update_stored_flip_values()


# a function to fix the value being clipped when it's too big
func _spinboxes_suffix_fix() -> void:
	for i in PATTERN_NODES:
		for j in ["Duration", "Pause"]:
			if i[j].value >= 10000:
				i[j].suffix = ""
			else:
				i[j].suffix = "ms"




### IMPORTER

func _on_preset_button_pressed() -> void:
	durations = [1.0, 0.5, 0.0, 0.0]
	pauses = [1.0, 0.5, 0.0, 0.0]
	_update_ui_time_values()
	%TactAmount.value = 2
	_reset_progress()

func _on_preset_2_button_pressed() -> void:
	durations = [0.4, 0.4, 0.8, 0.8]
	pauses = [0.8, 0.8, 0.4, 0.4]
	_update_ui_time_values()
	%TactAmount.value = 4
	_reset_progress()

func _on_clear_button_pressed() -> void:
	durations = [0.0, 0.0, 0.0, 0.0]
	pauses = [0.0, 0.0, 0.0, 0.0]
	_update_ui_time_values()
	flips = [false, false, false, false]
	_update_ui_flip_values()
	%TactAmount.value = 1
	_reset_progress()


# Examples:
# "200,100,100,50" = 2 tacts, keep flips
# "200,100,100" = 2 tacts, keep flips, set second tact's pause to 0
# "200,100,100,50|tf" = 2 tacts, force flips to true, false, false, false

func import_pattern(pattern: String) -> String:
	print("Pattern: ", pattern)
	var final_length := 1
	var final_durations := []
	var final_pauses := []
	var final_flips := []
	
	# Flips stage (if exists)
	var m_main := pattern.split("|")
	if len(m_main) == 2:
		var m_flips := m_main[1]
		if len(m_flips) > ROWS:
			return "Incorrect format! Too many flips"
		for i in m_flips:
			if i != "f" and i != "t":
				return "Incorrect format! Flip part can only have \"t\" or \"f\""
		
		final_length = len(m_flips)
		for i in range(final_length):
			if m_flips[i] == "t":
				final_flips.append(true)
			else:
				final_flips.append(false)
		while len(final_flips) < ROWS:
			final_flips.append(false)
	
	# Timings stage
	var m_times := m_main[0].split(",")
	if len(m_times) > ROWS*2:
		return "Incorrect format! Too many timings"
	
	var in_dur_part := true
	for i in m_times:
		if not i.is_valid_int():
			return "Incorrect format! Invalid/non-integer timings"
		var m_timing := float(i)
		if m_timing > MAX_LENGTH or m_timing < 0.0:
			return "Incorrect format! One of the timings is too large/below zero"
		
		if in_dur_part:
			final_durations.append(m_timing)
		else:
			final_pauses.append(m_timing)
		in_dur_part = !in_dur_part
	
	final_length = maxi(final_length, len(final_durations))
	final_length = maxi(final_length, len(final_pauses))
	
	while len(final_durations) < ROWS:
		final_durations.append(0.0)
	while len(final_pauses) < ROWS:
		final_pauses.append(0.0)
	
	print(final_durations)
	print(final_pauses)
	print(final_flips)
	print(final_length)
	
	%TactAmount.value = final_length
	durations = final_durations
	pauses = final_pauses
	_update_ui_time_values()
	
	if not final_flips.is_empty():
		flips = final_flips
		_update_ui_flip_values()
	
	return "Imported!"

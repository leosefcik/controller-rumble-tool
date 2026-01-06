extends Node

@export var MOUSE_STICKY_GLYPH: CompressedTexture2D
@export var MOUSE_SNAP_GLPYH: CompressedTexture2D

@export var UI: Control

# Current program mode, controlled via the 2 tabs
#enum Modes {ANALOG, PROGAM}
#var mode := Modes.ANALOG
# Unused ever since I moved their logic to their tab nodes


func _ready() -> void:
	UI.update_glyphs()


### INPUT

# Processing of button inputs
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("couple_motors"):
		%CoupleMotors.button_pressed = !%CoupleMotors.button_pressed
	elif event.is_action_pressed("flip_controls"):
		%FlipControls.button_pressed = !%FlipControls.button_pressed
	
	elif event.is_action_pressed("lock_rumble_left"):
		if not Settings.shoulder_enabled: return
		
		if Settings.coupled: toggle_locks(1,1)
		elif not Settings.flipped: toggle_locks(1,0)
		else: toggle_locks(0,1)
	
	elif event.is_action_pressed("lock_rumble_right"):
		if not Settings.shoulder_enabled: return
		
		if Settings.coupled: toggle_locks(1,1)
		elif not Settings.flipped: toggle_locks(0,1)
		else: toggle_locks(1,0)
	
	elif event.is_action_pressed("lock_both_rumbles"):
		toggle_locks(1,1)


### Lock functionality

func toggle_locks(toggle_weak: bool, toggle_strong: bool) -> void:
	if toggle_weak:
		Settings.weak_locked = !Settings.weak_locked
	if toggle_strong:
		Settings.strong_locked = !Settings.strong_locked
	UI.update_glyphs()


### CONTROLLER

# Checks for controller name every 0.5 seconds
func _on_controller_check_timer_timeout() -> void:
	if not Settings.control_all_ids:
		var current_controller_name := Input.get_joy_name(Settings.controller_id)
		if current_controller_name != Settings.controller_name:
			Settings.controller_name = current_controller_name
			
			if not Settings.controller_name:
				%NameLabel.text = "No device detected on ID #" + str(Settings.controller_id)
				if Settings.controller_id != 0: %NameLabel.text += " (try #0)"
				%ControllerStatusIcon.modulate = Color.DIM_GRAY
			else:
				%NameLabel.text = Settings.controller_name
				%ControllerStatusIcon.modulate = Color.WHITE
	
	else: # "All" checked
		var connected_count := 0
		for i in range(Settings.CONTROLLER_ID_RANGE):
			if Input.get_joy_name(i) != "":
				connected_count += 1
		%NameLabel.text = str("Controlling ", connected_count, " devices from #0 to #31")
		%ControllerStatusIcon.modulate = Color.WHITE if connected_count > 0 else Color.DIM_GRAY


func reset_rumble() -> void:
	for i in range(Settings.CONTROLLER_ID_RANGE):
		Input.stop_joy_vibration(i)
	UI.update_desired_gauges(0.0, 0.0)
	UI.update_power_gauges(0.0, 0.0)
	Settings.weak_locked = false
	Settings.strong_locked = false
	UI.update_glyphs()

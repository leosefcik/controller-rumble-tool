extends Node

# This is an autoload

# These settings are stored here as reference for other functions globally to use.
# Some of the settings that require to be dynamically changed (like Flipped and Coupled)
# are controlled via changing the .enabled value on their respective buttons, as this keeps the
# UI elements synced and also changes the changes the value here.
# It's a bit simple and inelegant, but I feel like it's whatever for a project like this
# Moving all of these from 1 big Main.gd script was a mess anyway

var controller_id := 0
var controller_name := "Empty" # checked every 0.5 seconds, triggers an update of the label if different
var control_all_ids := false
const CONTROLLER_ID_RANGE = 32 # an arbitrarily hardcoded amount of max controllers

var trigger_enabled := true
var joystick_enabled := true
var shoulder_enabled := true
var control_sensitivty := 1.0

var weak_locked := false # Call UI.update_glyphs() after changing
var strong_locked := false # Call UI.update_glyphs() after changing

var rumble_multiplier := 1.0
var flipped := false # %FlipControls
var coupled := false # %CoupleMotors
var incremented := false




# These are used to apply a "fix frame" every ~2 seconds
# Every "fix frame", rumble functions should run a 0.99x multiplier,
# and then return to normal. This variation will allow the controller
# to rumble continuously, because usually, hardware prevents the controller
# from rumbling too long with the same intensity.
var fix_delta_counter := 0.0
var apply_fix_frame := false

func _process(delta: float) -> void:
	# Fix Frame counter - every 2 seconds ish
	_increment_fix_frame(delta)

# Every 2 seconds of _process, make the current frame a fix frame
func _increment_fix_frame(delta: float) -> void:
	fix_delta_counter += delta
	if fix_delta_counter > 2.0:
		apply_fix_frame = true
		fix_delta_counter = 0.0

# When in a fix frame, return a 0.99 multiplier for rumble functions to use
# (and reset fix frame status)
func get_fix_multiplier() -> float:
	var fix := 1.0
	if apply_fix_frame:
		fix = 0.99
		apply_fix_frame = false
	return fix


# Stop vibrations so controllers dont vibrate when ID changed
func stop_vibrations() -> void:
	for i in range(CONTROLLER_ID_RANGE):
		Input.stop_joy_vibration(i)


# Rumble function called from other nodes
func rumble(weak_power: float, strong_power: float) -> void:
	# Applying 0.99x fix every frame after 2 seconds, otherwise it's 1.00x
	var fix := get_fix_multiplier()
	
	# Regular vs. "All" mode
	if not control_all_ids: _continuous_vibration(weak_power, strong_power, controller_id, fix)
	else:
		for i in range(CONTROLLER_ID_RANGE):
			_continuous_vibration(weak_power, strong_power, i, fix)
	

func _continuous_vibration(weak_power: float, strong_power: float, id: int, fix: float) -> void:
	Input.start_joy_vibration(
		id,
		weak_power * rumble_multiplier * fix,
		strong_power * rumble_multiplier * fix,
		0.0)

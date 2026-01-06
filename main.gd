extends Node

@export var MOUSE_STICKY_GLYPH: CompressedTexture2D
@export var MOUSE_SNAP_GLPYH: CompressedTexture2D

@export var UI: Control

# Current program mode, controlled via the 2 tabs
enum Modes {ANALOG, PROGAM}
var mode := Modes.ANALOG

# Desired - where the controls point to
var weak_desired := 0.0
var strong_desired := 0.0
# Power - current power of controller motors
var weak_power := 0.0
var strong_power := 0.0

# Analog settings
var alternating_mode := false
var hit_zero := true
var velocity_mode := false
var velocity_mode_speed := 1.0


# These are used to apply a "fix frame" every ~2 seconds
# Every "fix frame", rumble functions should run a 0.99x multiplier,
# and then return to normal. This variation will allow the controller
# to rumble continuously, because usually, hardware prevents the controller
# from rumbling too long with the same intensity.
var fix_delta_counter := 0.0
var apply_fix_frame := false


func _ready() -> void:
	UI.update_glyphs()


func _process(delta: float) -> void:
	# Fix Frame counter - every 2 seconds ish
	_increment_fix_frame(delta)
	
	# Analog mode processing
	if mode == Modes.ANALOG:
		_process_desired_analog() # sets desired values
		_process_power_analog(delta) # sets final values
		_rumble_analog() # processes final values into real rumble
		UI.update_desired_gauges(weak_desired, strong_desired)
		
		# Alternating mode check - flips controls exactly once, resets hit_zero check
		if alternating_mode:
			if (
				(weak_power == 0.0 and strong_power == 0.0)
				and
				not hit_zero
			):
				hit_zero = true
				%FlipControls.button_pressed = !%FlipControls.button_pressed


func _process_desired_analog() -> void:
	# We take the max of either the triggers/joyUP/joyDOWN for control variety
	# first checking if they're enabled
	var left_joy_mag := 0.0
	var left_trigger_mag := 0.0
	var right_joy_mag := 0.0
	var right_trigger_mag := 0.0
	
	if Settings.joystick_enabled:
		left_joy_mag = maxf(
		Input.get_action_strength("increase_rumble_left"),
		Input.get_action_strength("decrease_rumble_left")
		)
		right_joy_mag = maxf(
		Input.get_action_strength("increase_rumble_right"),
		Input.get_action_strength("decrease_rumble_right")
		)
	
	if Settings.trigger_enabled:
		left_trigger_mag = Input.get_action_strength("increase_rumble_trigger_left")
		right_trigger_mag = Input.get_action_strength("increase_rumble_trigger_right")
	
	# Gets bigger of either joy/trigger, divs by sensitivity and caps it to 1.0
	var left_magnitude := minf(maxf(left_joy_mag, left_trigger_mag) / Settings.control_sensitivty, 1.0)
	var right_magnitude := minf(maxf(right_joy_mag, right_trigger_mag) / Settings.control_sensitivty, 1.0)
	
	# Mapping the controls
	if Settings.coupled:
		var combined_desired := maxf(left_magnitude, right_magnitude)
		weak_desired = combined_desired
		strong_desired = combined_desired
	elif not Settings.flipped:
		weak_desired = left_magnitude
		strong_desired = right_magnitude
	else:
		weak_desired = right_magnitude
		strong_desired = left_magnitude
	
	weak_desired = maxf(weak_desired, %WeakSlider.value)
	strong_desired = maxf(strong_desired, %StrongSlider.value)
	
	if Settings.incremented:
		strong_desired = snappedf(strong_desired, 0.1)
		weak_desired = snappedf(weak_desired, 0.1)


func _process_power_analog(delta: float) -> void:
	if not Settings.weak_locked:
		if not velocity_mode:
			weak_power = weak_desired
		else:
			weak_power = move_toward(weak_power, weak_desired, delta*velocity_mode_speed)
	
	if not Settings.strong_locked:
		if not velocity_mode:
			strong_power = strong_desired
		else:
			strong_power = move_toward(strong_power, strong_desired, delta*velocity_mode_speed)


func _rumble_analog() -> void:
	# Applying 0.99x fix every frame after 2 seconds, otherwise it's 1.00x
	var fix := _get_fix_multiplier()
	
	# Regular vs. "All" mode
	if not Settings.control_all_ids: _continuous_vibration(Settings.controller_id, fix)
	else:
		for i in range(Settings.CONTROLLER_ID_RANGE):
			_continuous_vibration(i, fix)
	
	# Alternating mode check - readies hit_zero check if motors in use
	if alternating_mode:
		if hit_zero and (weak_power > 0.0 or strong_power > 0.0):
			hit_zero = false
	
	UI.update_power_gauges(weak_power, strong_power)


func _continuous_vibration(id: int, fix: float) -> void:
	Input.start_joy_vibration(
		id,
		weak_power * Settings.rumble_multiplier * fix,
		strong_power * Settings.rumble_multiplier * fix,
		0.0)


# Every 2 seconds of _process, make the current frame a fix frame
func _increment_fix_frame(delta: float) -> void:
	fix_delta_counter += delta
	if fix_delta_counter > 2.0:
		apply_fix_frame = true
		fix_delta_counter = 0.0


# When in a fix frame, return a 0.99 multiplier for rumble functions to use
# (and reset fix frame status)
func _get_fix_multiplier() -> float:
	var fix := 1.0
	if apply_fix_frame:
		fix = 0.99
		apply_fix_frame = false
	return fix



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
	weak_desired = 0.0
	strong_desired = 0.0
	UI.update_desired_gauges(0.0, 0.0)
	UI.update_power_gauges(0.0, 0.0)
	Settings.weak_locked = false
	Settings.strong_locked = false
	UI.update_glyphs()







## Analog Mode settings

func _on_analog_alt_mode_toggled(toggled_on: bool) -> void:
	alternating_mode = toggled_on

func _on_analog_vel_mode_toggled(toggled_on: bool) -> void:
	velocity_mode = toggled_on
	if toggled_on: %VelocityModeSpeedContainer.show()
	else: %VelocityModeSpeedContainer.hide()

func _on_velocity_mode_speed_value_changed(value: float) -> void:
	velocity_mode_speed = value
	%VelocityModeSpeedLabel.text = str("Speed: ", value, "x")

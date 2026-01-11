extends TabBar

@export var UI: Control

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


func _process(delta: float) -> void:
	if not visible: return # Only if on tab
	
	_process_desired() # sets desired values
	_process_power(delta) # sets final values
	Settings.rumble(weak_power, strong_power) # processes final values into real rumble
	UI.update_power_gauges(weak_power, strong_power)
	UI.update_desired_gauges(weak_desired, strong_desired)
	
	if alternating_mode:
		if hit_zero and (weak_power > 0.0 or strong_power > 0.0):
			hit_zero = false
		
		elif (
			(weak_power == 0.0 and strong_power == 0.0)
			and
			not hit_zero
		):
			hit_zero = true
			UI.flip_controls()

func _process_desired() -> void:
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
	
	weak_desired = maxf(weak_desired, %WeakSliderAnalog.value)
	strong_desired = maxf(strong_desired, %StrongSliderAnalog.value)


func _process_power(delta: float) -> void:
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
		
	if Settings.incremented:
		weak_power = snappedf(weak_power, 0.1)
		strong_power = snappedf(strong_power, 0.1)



### Settings

func _on_analog_alt_mode_toggled(toggled_on: bool) -> void:
	alternating_mode = toggled_on

func _on_analog_vel_mode_toggled(toggled_on: bool) -> void:
	velocity_mode = toggled_on
	if toggled_on: %VelocityModeSpeedContainer.show()
	else: %VelocityModeSpeedContainer.hide()

func _on_velocity_mode_speed_value_changed(value: float) -> void:
	velocity_mode_speed = value
	%VelocityModeSpeedLabel.text = str("Speed: ", value, "x")

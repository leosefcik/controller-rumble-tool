extends Node

var controller_id := 0
var controller_name := "Empty"

var rumble_multiplier := 1.0
var flipped := false
var coupled := false
var incremented := false

enum Modes {ANALOG, CONTROL}
var mode := Modes.ANALOG

var weak_desired := 0.0
var strong_desired := 0.0

# These are used to apply a "fix frame" every ~2 seconds
# Every "fix frame", rumble functions should run a 0.99x multiplier,
# and then return to normal. This variation will allow the controller
# to rumble continuously, because usually, hardware prevents the controller
# from rumbling too long with the same intensity.
var fix_delta_counter := 0.0
var apply_fix_frame := false


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# Fix Frame counter
	_increment_fix_frame(delta)
	
	# Analog mode processing
	if mode == Modes.ANALOG:
		
		# We take the max of either the triggers/joyUP or joyDOWN for control variety
		var left_magnitude := maxf(
			Input.get_action_strength("increase_rumble_left"),
			Input.get_action_strength("decrease_rumble_left")
			)
		var right_magnitude := maxf(
			Input.get_action_strength("increase_rumble_right"),
			Input.get_action_strength("decrease_rumble_right")
			)
		
		# Mapping the controls
		if coupled:
			var combined_desired := maxf(left_magnitude, right_magnitude)
			weak_desired = combined_desired
			strong_desired = combined_desired
		elif not flipped:
			weak_desired = left_magnitude
			strong_desired = right_magnitude
		else:
			weak_desired = right_magnitude
			strong_desired = left_magnitude
		
		if incremented:
			strong_desired = snappedf(strong_desired, 0.1)
			weak_desired = snappedf(weak_desired, 0.1)
		
		_rumble_analog()
		
		%WeakDesired.value = weak_desired
		%StrongDesired.value = strong_desired


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("special_right"):
		%CoupleMotors.button_pressed = !%CoupleMotors.button_pressed
	elif event.is_action_pressed("special_left"):
		%FlipControls.button_pressed = !%FlipControls.button_pressed


func _rumble_analog() -> void:
	# Applying fix
	var fix := _get_fix_multiplier()
	
	Input.start_joy_vibration(
		controller_id,
		weak_desired * rumble_multiplier * fix,
		strong_desired * rumble_multiplier * fix,
		0.0)
	
	%StrongPower.value = strong_desired
	%WeakPower.value = weak_desired

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


### CONTROLLER

func _on_controller_check_timer_timeout() -> void:
	var current_controller_name := Input.get_joy_name(controller_id)
	if current_controller_name != controller_name:
		controller_name = current_controller_name
		
		if not controller_name:
			%NameLabel.text = "No device detected on ID #" + str(controller_id) + " (try #0)"
		else:
			%NameLabel.text = controller_name


func _on_controller_id_box_value_changed(value: float) -> void:
	controller_name = "this is changed so the label update in _on_controller_check_timer_timeout() triggers"
	controller_id = int(value)




### SETTINGS

func _on_multiplier_box_value_changed(value: float) -> void:
	rumble_multiplier = value

func _on_flip_controls_toggled(toggled_on: bool) -> void:
	flipped = toggled_on

func _on_couple_motors_toggled(toggled_on: bool) -> void:
	coupled = toggled_on

func _on_snap_controls_toggled(toggled_on: bool) -> void:
	incremented = toggled_on



### OTHER

func _on_info_button_pressed() -> void:
	%BlurRect.show()
	%InfoPopup.popup()

func _on_info_popup_popup_hide() -> void:
	%BlurRect.hide()

# For the URLs to work in the Credits Popup
func _on_info_credits_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))

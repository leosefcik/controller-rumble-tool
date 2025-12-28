extends Node

var controller_id := 0
var controller_name := "Empty"

var rumble_multiplier := 1.0
var flipped := false
var coupled := false
var snapped := false

enum Modes {ANALOG, CONTROL}
var mode := Modes.ANALOG

var weak_desired := 0.0
var strong_desired := 0.0


func _ready() -> void:
	pass

func _process(delta: float) -> void:
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
		
		if snapped:
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
	Input.start_joy_vibration(
		controller_id,
		weak_desired * rumble_multiplier,
		strong_desired * rumble_multiplier,
		0.0)
	
	%StrongPower.value = strong_desired
	%WeakPower.value = weak_desired


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
	snapped = toggled_on



### OTHER

func _on_info_button_pressed() -> void:
	%BlurRect.show()
	%InfoPopup.popup()

func _on_info_popup_popup_hide() -> void:
	%BlurRect.hide()

# For the URLs to work in the Credits Popup
func _on_info_credits_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))

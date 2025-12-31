extends Node

@export var LOCK_ICON: CompressedTexture2D
@export var UNLOCK_ICON: CompressedTexture2D

@export var LB_OFF_GLYPH: CompressedTexture2D
@export var LB_ON_GLYPH: CompressedTexture2D
@export var RB_OFF_GLYPH: CompressedTexture2D
@export var RB_ON_GLYPH: CompressedTexture2D

@export var SELECT_OFF_GLYPH: CompressedTexture2D
@export var SELECT_ON_GLYPH: CompressedTexture2D
@export var START_OFF_GLYPH: CompressedTexture2D
@export var START_ON_GLYPH: CompressedTexture2D

@export var MOUSE_STICKY_GLYPH: CompressedTexture2D
@export var MOUSE_SNAP_GLPYH: CompressedTexture2D

var controller_id := 0
var controller_name := "Empty"

var rumble_multiplier := 1.0
var flipped := false
var coupled := false
var incremented := false

var trigger_enabled := true
var joystick_enabled := true
var mouse_sticky_enabled := false

enum Modes {ANALOG, PROGAM}
var mode := Modes.ANALOG

var weak_desired := 0.0
var strong_desired := 0.0
var weak_locked := false
var strong_locked := false
var weak_desired_lock := 0.0
var strong_desired_lock := 0.0

var weak_slider_in_use := false
var strong_slider_in_use := false

# These are used to apply a "fix frame" every ~2 seconds
# Every "fix frame", rumble functions should run a 0.99x multiplier,
# and then return to normal. This variation will allow the controller
# to rumble continuously, because usually, hardware prevents the controller
# from rumbling too long with the same intensity.
var fix_delta_counter := 0.0
var apply_fix_frame := false


func _ready() -> void:
	_update_glyphs()

func _process(delta: float) -> void:
	# Fix Frame counter
	_increment_fix_frame(delta)
	
	# Analog mode processing
	if mode == Modes.ANALOG:
		
		# We take the max of either the triggers/joyUP/joyDOWN for control variety
		# first checking if they're enabled
		var left_joy_mag := 0.0
		var left_trigger_mag := 0.0
		var right_joy_mag := 0.0
		var right_trigger_mag := 0.0
		
		if joystick_enabled:
			left_joy_mag = maxf(
			Input.get_action_strength("increase_rumble_left"),
			Input.get_action_strength("decrease_rumble_left")
			)
			right_joy_mag = maxf(
			Input.get_action_strength("increase_rumble_right"),
			Input.get_action_strength("decrease_rumble_right")
			)
		
		if trigger_enabled:
			left_trigger_mag = Input.get_action_strength("increase_rumble_trigger_left")
			right_trigger_mag = Input.get_action_strength("increase_rumble_trigger_right")
		
		var left_magnitude := maxf(left_joy_mag, left_trigger_mag)
		var right_magnitude := maxf(right_joy_mag, right_trigger_mag)
		
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
		
		weak_desired = maxf(weak_desired, %WeakSlider.value)
		strong_desired = maxf(strong_desired, %StrongSlider.value)
		
		if incremented:
			strong_desired = snappedf(strong_desired, 0.1)
			weak_desired = snappedf(weak_desired, 0.1)
		
		_rumble_analog()
		_update_desired_gauges(weak_desired, strong_desired)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("special_right"):
		%CoupleMotors.button_pressed = !%CoupleMotors.button_pressed
	elif event.is_action_pressed("special_left"):
		%FlipControls.button_pressed = !%FlipControls.button_pressed
	
	elif event.is_action_pressed("lock_rumble_left"):
		if coupled: _toggle_locks(1,1)
		elif not flipped: _toggle_locks(1,0)
		else: _toggle_locks(0,1)
	
	elif event.is_action_pressed("lock_rumble_right"):
		if coupled: _toggle_locks(1,1)
		elif not flipped: _toggle_locks(0,1)
		else: _toggle_locks(1,0)
	
	elif event.is_action_pressed("lock_both_rumbles"):
		_toggle_locks(1,1)


func _toggle_locks(toggle_weak: bool, toggle_strong: bool) -> void:
	if toggle_weak:
		weak_locked = !weak_locked
		weak_desired_lock = weak_desired
	if toggle_strong:
		strong_locked = !strong_locked
		strong_desired_lock = strong_desired
	_update_glyphs()


func _rumble_analog() -> void:
	# Applying fix
	var fix := _get_fix_multiplier()
	
	var weak_final := weak_desired if not weak_locked else weak_desired_lock
	var strong_final := strong_desired if not strong_locked else strong_desired_lock
	
	Input.start_joy_vibration(
		controller_id,
		weak_final * rumble_multiplier * fix,
		strong_final * rumble_multiplier * fix,
		0.0)
	
	_update_power_gauges(weak_final, strong_final)

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

func _update_glyphs() -> void:
	%WeakLock.texture = LOCK_ICON if weak_locked else UNLOCK_ICON
	%StrongLock.texture = LOCK_ICON if strong_locked else UNLOCK_ICON
	
	if not weak_locked:
		%WeakLockGlyph.texture = LB_OFF_GLYPH if not flipped else RB_OFF_GLYPH
	else:
		%WeakLockGlyph.texture = LB_ON_GLYPH if not flipped else RB_ON_GLYPH
	
	if not strong_locked:
		%StrongLockGlyph.texture = RB_OFF_GLYPH if not flipped else LB_OFF_GLYPH
	else:
		%StrongLockGlyph.texture = RB_ON_GLYPH if not flipped else LB_ON_GLYPH
	
	%FlipControlsGlyph.texture = SELECT_OFF_GLYPH if not flipped else SELECT_ON_GLYPH
	%CoupleMotorsGlyph.texture = START_OFF_GLYPH if not coupled else START_ON_GLYPH


func _update_desired_gauges(weak: float, strong: float) -> void:
	%WeakDesired.value = weak
	%StrongDesired.value = strong

func _update_power_gauges(weak: float, strong: float) -> void:
	%WeakPower.value = weak
	%StrongPower.value = strong

### CONTROLLER

func _on_controller_check_timer_timeout() -> void:
	var current_controller_name := Input.get_joy_name(controller_id)
	if current_controller_name != controller_name:
		controller_name = current_controller_name
		
		if not controller_name:
			%NameLabel.text = "No device detected on ID #" + str(controller_id)
			if controller_id != 0: %NameLabel.text += " (try #0)"
			%ControllerStatusIcon.modulate = Color.DIM_GRAY
		else:
			%NameLabel.text = controller_name
			%ControllerStatusIcon.modulate = Color.WHITE


func _on_controller_id_box_value_changed(value: float) -> void:
	controller_name = "this is changed so the label update in _on_controller_check_timer_timeout() triggers"
	controller_id = int(value)


### TAB NAVIGATION

func _on_mode_tabs_tab_changed(tab: int) -> void:
	mode = tab as Modes
	_reset_rumble()


func _reset_rumble() -> void:
	Input.stop_joy_vibration(controller_id)
	weak_desired = 0.0
	strong_desired = 0.0
	_update_desired_gauges(0.0, 0.0)
	_update_power_gauges(0.0, 0.0)
	weak_locked = false
	strong_locked = false
	_update_glyphs()

### LOCK BUTTON UI

func _on_weak_lock_button_pressed() -> void:
	_toggle_locks(1,0)
	if coupled: _toggle_locks(0,1)

func _on_strong_lock_button_pressed() -> void:
	_toggle_locks(0,1)
	if coupled: _toggle_locks(1,0)

## TOGLGES

func _on_trigger_toggle_pressed() -> void:
	trigger_enabled = !trigger_enabled
	if trigger_enabled: %TriggerToggleX.hide() 
	else: %TriggerToggleX.show()

func _on_joystick_toggle_pressed() -> void:
	joystick_enabled = !joystick_enabled
	if joystick_enabled: %JoystickToggleX.hide() 
	else: %JoystickToggleX.show()

### SETTINGS

func _on_multiplier_box_value_changed(value: float) -> void:
	rumble_multiplier = value

func _on_flip_controls_toggled(toggled_on: bool) -> void:
	flipped = toggled_on
	_update_glyphs() # to update LB/RB glyphs

func _on_couple_motors_toggled(toggled_on: bool) -> void:
	coupled = toggled_on
	weak_locked = false
	strong_locked = false
	_update_glyphs() # to update LB/RB glyphs

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


# Mouse control slider logic

func _on_mouse_sticky_mode_pressed() -> void:
	mouse_sticky_enabled = !mouse_sticky_enabled
	if not mouse_sticky_enabled:
		%MouseStickyMode.icon = MOUSE_SNAP_GLPYH
		%WeakSlider.value = 0.0
		%StrongSlider.value = 0.0
	else:
		%MouseStickyMode.icon = MOUSE_STICKY_GLYPH

func _on_weak_slider_drag_started() -> void:
	weak_slider_in_use = true

func _on_strong_slider_drag_started() -> void:
	strong_slider_in_use = true

func _on_weak_slider_value_changed(value: float) -> void:
	if coupled and not strong_slider_in_use:
		%StrongSlider.value = value

func _on_strong_slider_value_changed(value: float) -> void:
	if coupled and not weak_slider_in_use:
		%WeakSlider.value = value

func _on_weak_slider_drag_ended(_value_changed: bool) -> void:
	weak_slider_in_use = false
	if not mouse_sticky_enabled:
		%WeakSlider.value = 0.0

func _on_strong_slider_drag_ended(_value_changed: bool) -> void:
	strong_slider_in_use = false
	if not mouse_sticky_enabled:
		%StrongSlider.value = 0.0

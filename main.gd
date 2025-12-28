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
var weak_locked := false
var strong_locked := false
var weak_desired_lock := 0.0
var strong_desired_lock := 0.0

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
	
	%StrongPower.value = strong_final
	%WeakPower.value = weak_final

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


### CONTROLLER

func _on_controller_check_timer_timeout() -> void:
	var current_controller_name := Input.get_joy_name(controller_id)
	if current_controller_name != controller_name:
		controller_name = current_controller_name
		
		if not controller_name:
			%NameLabel.text = "No device detected on ID #" + str(controller_id) + " (try #0)"
			%ControllerStatusIcon.modulate = Color.DIM_GRAY
		else:
			%NameLabel.text = controller_name
			%ControllerStatusIcon.modulate = Color.WHITE


func _on_controller_id_box_value_changed(value: float) -> void:
	controller_name = "this is changed so the label update in _on_controller_check_timer_timeout() triggers"
	controller_id = int(value)




### LOCK BUTTON UI

func _on_weak_lock_button_pressed() -> void:
	_toggle_locks(1,0)

func _on_strong_lock_button_pressed() -> void:
	_toggle_locks(0,1)

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

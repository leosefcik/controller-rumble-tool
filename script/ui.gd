extends Control

@export_group("Icons")

@export var LOCK_ICON: CompressedTexture2D
@export var UNLOCK_ICON: CompressedTexture2D

@export var LB_OFF_GLYPH: CompressedTexture2D
@export var LB_ON_GLYPH: CompressedTexture2D
@export var RB_OFF_GLYPH: CompressedTexture2D
@export var RB_ON_GLYPH: CompressedTexture2D

@export_group("Nodes")

@export var Main: Node

# Ideally, I should get rid of the unique names
# used all over this project
# and just like make a bunch of references to the nodes in this script
# so i can @export them and do so only once which would be better
# but eh


func _ready() -> void:
	_mouse_control_visibility_update(%ModeTabs.current_tab)


# Hides/unhides corresponding UI elements according to current mode
# Called on ready, and when tab changed
func _mouse_control_visibility_update(tab: int) -> void:
	if tab == 0:
		%AnalogMouseControl.show()
		%ProgramMouseControl.hide()
	else:
		%AnalogMouseControl.hide()
		%ProgramMouseControl.show()


# Updates Lock glyphs
func update_glyphs() -> void:
	%WeakLock.texture = LOCK_ICON if Settings.weak_locked else UNLOCK_ICON
	%StrongLock.texture = LOCK_ICON if Settings.strong_locked else UNLOCK_ICON
	
	if not Settings.weak_locked:
		%WeakLockGlyph.texture = LB_OFF_GLYPH if not Settings.flipped else RB_OFF_GLYPH
	else:
		%WeakLockGlyph.texture = LB_ON_GLYPH if not Settings.flipped else RB_ON_GLYPH
	
	if not Settings.strong_locked:
		%StrongLockGlyph.texture = RB_OFF_GLYPH if not Settings.flipped else LB_OFF_GLYPH
	else:
		%StrongLockGlyph.texture = RB_ON_GLYPH if not Settings.flipped else LB_ON_GLYPH
	
	# Disabled after changing the controls
	#%FlipControlsGlyph.texture = SELECT_OFF_GLYPH if not flipped else SELECT_ON_GLYPH
	#%CoupleMotorsGlyph.texture = START_OFF_GLYPH if not coupled else START_ON_GLYPH


func update_desired_gauges(weak: float, strong: float) -> void:
	%WeakDesired.value = weak
	%StrongDesired.value = strong

func update_power_gauges(weak: float, strong: float) -> void:
	%WeakPower.value = weak
	%StrongPower.value = strong

# A flip controls function. Seemed prettier than putting
# %FlipControls.button_pressed = !%FlipControls.button_pressed
# everywhere.
func flip_controls() -> void:
	%FlipControls.button_pressed = !%FlipControls.button_pressed


# TITLE BAR

func _on_controller_id_box_value_changed(value: float) -> void:
	# this is changed so the label update in Main's _on_controller_check_timer_timeout() triggers
	Settings.controller_name = "asdfasf"
	Settings.controller_id = int(value)
	Main.reset_rumble()

func _on_all_ids_box_toggled(toggled_on: bool) -> void:
	Settings.control_all_ids = toggled_on
	if toggled_on: %ControllerIdBox.editable = false
	else: %ControllerIdBox.editable = true
	Settings.stop_vibrations()
	
	# this is changed so the label update in _on_controller_check_timer_timeout() triggers
	Settings.controller_name = "asdfasf"



### CONTROLS PANEL

func _on_trigger_toggle_pressed() -> void:
	Settings.trigger_enabled = !Settings.trigger_enabled
	if Settings.trigger_enabled: %TriggerToggleX.hide()
	else: %TriggerToggleX.show()

func _on_joystick_toggle_pressed() -> void:
	Settings.joystick_enabled = !Settings.joystick_enabled
	if Settings.joystick_enabled: %JoystickToggleX.hide()
	else: %JoystickToggleX.show()

func _on_shoulder_toggle_pressed() -> void:
	Settings.shoulder_enabled = !Settings.shoulder_enabled
	if Settings.shoulder_enabled: %ShoulderToggleX.hide()
	else: %ShoulderToggleX.show()

func _on_control_sensitivity_slider_value_changed(value: float) -> void:
	Settings.control_sensitivty = value
	%ControlSensitivityLabel.text = str("Sensitivity: ", value)



### LOCKS PANEL

func _on_weak_lock_button_pressed() -> void:
	Main.toggle_locks(1,0)
	if Settings.coupled: Main.toggle_locks(0,1)

func _on_strong_lock_button_pressed() -> void:
	Main.toggle_locks(0,1)
	if Settings.coupled: Main.toggle_locks(1,0)



### MODE TABS

func _on_mode_tabs_tab_changed(tab: int) -> void:
	Main.reset_rumble()
	_mouse_control_visibility_update(tab)


### SETTINGS

func _on_flip_controls_toggled(toggled_on: bool) -> void:
	Settings.flipped = toggled_on
	
	# Flip mouse slides too. A bit ugly but eh
	if toggled_on:
		%WeakSliderAnalog.get_parent().move_child(%WeakSliderAnalog, 1)
	else:
		%WeakSliderAnalog.get_parent().move_child(%WeakSliderAnalog, 2)
	update_glyphs() # to update LB/RB glyphs

func _on_couple_motors_toggled(toggled_on: bool) -> void:
	Settings.coupled = toggled_on
	Settings.weak_locked = false
	Settings.strong_locked = false
	update_glyphs() # to update LB/RB glyphs

func _on_multiplier_box_value_changed(value: float) -> void:
	Settings.rumble_multiplier = value

func _on_snap_controls_toggled(toggled_on: bool) -> void:
	Settings.incremented = toggled_on



### DROPDOWNS

func _on_hide_mode_tabs_toggled(toggled_on: bool) -> void:
	if toggled_on: %ModeTabs.hide()
	else: %ModeTabs.show()

func _on_hide_bottom_row_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%SettingsBox.hide()
	else:
		%SettingsBox.show()



### OTHER

func _on_info_button_pressed() -> void:
	%BlurRect.show()
	%InfoPopup.popup()

func _on_info_popup_popup_hide() -> void:
	%BlurRect.hide()

# For the URLs to work in the Credits Popup
func _on_info_credits_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))

func _on_controls_button_pressed() -> void:
	%BlurRect.show()
	%ControlsPopup.show()

func _on_controls_popup_popup_hide() -> void:
	%BlurRect.hide()

func _on_theme_button_pressed() -> void:
	Main.cycle_theme()

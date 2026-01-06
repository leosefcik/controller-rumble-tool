extends Node

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

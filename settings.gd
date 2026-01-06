extends Node

var controller_id := 0
var controller_name := "Empty"
var control_all_ids := false
const CONTROLLER_ID_RANGE = 32 # an arbitrarily hardcoded amount of max controllers

var trigger_enabled := true
var joystick_enabled := true
var shoulder_enabled := true
var control_sensitivty := 1.0

var weak_locked := false
var strong_locked := false

var rumble_multiplier := 1.0
var flipped := false
var coupled := false
var incremented := false

extends Control

@export var MOUSE_STICKY_GLYPH: CompressedTexture2D
@export var MOUSE_SNAP_GLPYH: CompressedTexture2D

var mouse_sticky_enabled := false

# Used to sync the sliders from one to the other if Setting.coupled is on
var weak_slider_in_use := false
var strong_slider_in_use := false



### Mouse control slider logic

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
	if Settings.coupled and not strong_slider_in_use:
		%StrongSlider.value = value

func _on_strong_slider_value_changed(value: float) -> void:
	if Settings.coupled and not weak_slider_in_use:
		%WeakSlider.value = value

func _on_weak_slider_drag_ended(_value_changed: bool) -> void:
	weak_slider_in_use = false
	if not mouse_sticky_enabled:
		%WeakSlider.value = 0.0

func _on_strong_slider_drag_ended(_value_changed: bool) -> void:
	strong_slider_in_use = false
	if not mouse_sticky_enabled:
		%StrongSlider.value = 0.0

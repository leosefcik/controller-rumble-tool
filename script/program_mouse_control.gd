extends Control

@export var ProgramMode: TabBar


func _on_weak_slider_program_drag_ended(value_changed: bool) -> void:
	%WeakSliderProgram.value = 0.0


func _on_strong_slider_program_drag_ended(value_changed: bool) -> void:
	%StrongSliderProgram.value = 0.0


func _on_program_mode_speed_slider_value_changed(value: float) -> void:
	%ProgramModeSpeedLabel.text = str("Speed: ", value, "x")
	ProgramMode.speed_slider = value

extends Control


func _on_weak_slider_program_drag_ended(value_changed: bool) -> void:
	%WeakSliderProgram.value = 0.0


func _on_strong_slider_program_drag_ended(value_changed: bool) -> void:
	%StrongSliderProgram.value = 0.0

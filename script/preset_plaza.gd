extends HBoxContainer

@export var ProgramMode : TabBar


### Motors

func _on_strong_100_pressed() -> void:
	ProgramMode.strong_desired = 1.0

func _on_weak_100_pressed() -> void:
	ProgramMode.weak_desired = 1.0

func _on_strong_50_pressed() -> void:
	ProgramMode.strong_desired = 0.5

func _on_weak_50_pressed() -> void:
	ProgramMode.weak_desired = 0.5

func _on_strong_0_pressed() -> void:
	ProgramMode.strong_desired = 0.0

func _on_weak_0_pressed() -> void:
	ProgramMode.weak_desired = 0.0

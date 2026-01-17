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



### Flips

func _on_f_clear_pressed() -> void:
	ProgramMode.import_flips([false, false, false, false])

func _on_f_cycle_pressed() -> void:
	ProgramMode.import_flips([true, false, false, false])

func _on_f_every_pressed() -> void:
	ProgramMode.import_flips([true, true, true, true])



### Controls
func _on_flip_intensities_pressed() -> void:
	ProgramMode.flip_intensities()

func _on_random_preset_pressed() -> void:
	pass # Replace with function body.

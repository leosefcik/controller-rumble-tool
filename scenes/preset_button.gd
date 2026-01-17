extends Button

signal preset_clicked(preset: String)
var stored_code := ""


func _on_pressed() -> void:
	preset_clicked.emit(stored_code)

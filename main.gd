extends Control

var controller_id := -1


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	print(Input.get_joy_info(0))


func change_rumble(left_increment: float, right_increment: float) -> void:
	pass

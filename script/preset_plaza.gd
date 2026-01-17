extends HBoxContainer

@export var ProgramMode : TabBar
@export var PresetsGrid : GridContainer
@export var PresetButton : PackedScene

var PRESETS := {
	"Clear" = "0",
	"Simple" = "1000,1000",
	"4321" = "400,300,200,100",
	"CWaltz" = "300,100,100,200,100,200",
	"7/8" = "100,50,100,50,100,50,100",
	"wip" = "100,500,400,400,400,400",
}


func _ready() -> void:
	for i in PresetsGrid.get_children():
		i.queue_free()
	for i in PRESETS:
		var newbutton := PresetButton.instantiate()
		newbutton.text = i
		newbutton.stored_code = PRESETS[i]
		newbutton.connect("preset_clicked", _preset_clicked)
		PresetsGrid.add_child(newbutton)

func _preset_clicked(code: String) -> void:
	var imp_output = ProgramMode.import_pattern(code)


func _input(event: InputEvent) -> void:
	if ProgramMode.visible:
		if event.is_action_pressed("pick_random"):
			_on_random_preset_pressed()


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
	var code = PRESETS[PRESETS.keys().pick_random()]
	ProgramMode.import_pattern(code)

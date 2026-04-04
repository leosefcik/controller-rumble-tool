extends HBoxContainer

@export var ProgramMode : TabBar
@export var PresetsGrid : GridContainer
@export var PresetButton : PackedScene

var PRESETS := {
	"Default" = "1000",
	"Long" = "500,200",
	"Short" = "250,200",
	"Dotted" = "100,200",
	"Simple" = "1000,1000",
	"2Step" = "400,200,200,100",
	"Waltz" = "300,100,150,250,150,250",
	"7/8" = "400,100,200,100,200,100",
	"Beat 1" = "250,150,100,300,100,100,100,500",
	"Beat 2" = "100,100,100,100,300,100,100,300",
	"Beat 3" = "400,200,100,100,100,300,100,300",
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

func _on_strong_66_pressed() -> void:
	ProgramMode.strong_desired = 0.6666
func _on_weak_66_pressed() -> void:
	ProgramMode.weak_desired = 0.6666

func _on_strong_33_pressed() -> void:
	ProgramMode.strong_desired = 0.3333
func _on_weak_33_pressed() -> void:
	ProgramMode.weak_desired = 0.3333

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
	
	var flip_random = randi_range(0,1)
	if flip_random == 0:
		ProgramMode.flip_intensities()

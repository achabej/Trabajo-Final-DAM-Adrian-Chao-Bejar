extends Control

@onready var unlocks_for_phase := {
	1: [$BtnBuildExtractor, $BtnBuildConveyLine,$BtnBuildFurnace, $BtnBuildSteelRefinery, $BtnBuildPlatesFactory, $BtnBuildChipsFactory],
}

func _ready():
	GameManager.connect("initialized", Callable(self, "_on_game_manager_initialized"))

func _process(_delta):
	$MouseArea.global_position = get_global_mouse_position()

func _on_game_manager_initialized():
	GameManager.connect("phase_changed", Callable(self, "_on_phase_changed"))
	_on_phase_changed(GameManager.current_phase)
	
func _on_phase_changed(new_phase: int) -> void:
	for fase in unlocks_for_phase.keys():
		var visible : bool = fase <= new_phase
		for btn in unlocks_for_phase[fase]:
			btn.visible = visible

func _on_btn_build_extractor_button_down() -> void:
	BuildManager.SpawnExtractor()

func _on_btn_build_convey_merger_button_down() -> void:
	BuildManager.SpawnConveyMerger()

func _on_btn_build_furnace_button_down() -> void:
	BuildManager.SpawnFurnace()

func _on_btn_build_storage_button_down() -> void:
	BuildManager.SpawnStorage()

func _on_btn_build_steel_refinery_button_down() -> void:
	BuildManager.SpawnSteelRefinery()

func _on_btn_build_cristal_refinery_button_down() -> void:
	BuildManager.SpawnCristalRefinery()

func _on_btn_build_chips_factory_button_down() -> void:
	BuildManager.SpawnChipsFactory()

func _on_btn_build_plates_factory_button_down() -> void:
	BuildManager.SpawnPlatesFactory()

#func _on_btn_build_text_machine_button_down() -> void:
	#BuildManager.SpawnTestCubeGenerator()

func _on_area_2d_area_entered(area: Area2D) -> void:
	BuildManager.OnGrid = false

func _on_area_2d_area_exited(area: Area2D) -> void:
	BuildManager.OnGrid = true

func _on_btn_build_convey_line_mouse_entered() -> void:
	$Building_Info.text = "[center]Mueve materiales entre fabricas[center]"

func _on_btn_build_extractor_mouse_entered() -> void:
	$Building_Info.text = "[center]Extrae materiales de depositos[center]"

func _on_btn_build_furnace_mouse_entered() -> void:
	$Building_Info.text = "[center]Funde los metales en lingotes[center]"

func _on_btn_build_steel_refinery_mouse_entered() -> void:
	$Building_Info.text = "[center]Funde lingotes de hierro y cobre para hacer acero[center]"

func _on_btn_build_plates_factory_mouse_entered() -> void:
	$Building_Info.text = "[center]Convierte los lingotes en placas[center]"

func _on_btn_build_chips_factory_mouse_entered() -> void:
	$Building_Info.text = "[center]Crea chips a partir de placas de acero, placas de cobre y cristal[center]"

func _on_btn_line_mouse_exited() -> void:
	$Building_Info.text = ""

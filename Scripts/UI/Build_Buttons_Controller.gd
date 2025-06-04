extends Node

@onready var unlocks_for_phase := {
	1: [$BtnBuildExtractor, $BtnBuildConveyLine,$BtnBuildFurnace, $BtnBuildSteelRefinery, $BtnBuildPlatesFactory, $BtnBuildChipsFactory],
}

func _ready():
	GameManager.connect("initialized", Callable(self, "_on_game_manager_initialized"))

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
	print("Raton dentro")
	BuildManager.OnGrid = false

func _on_area_2d_area_exited(area: Area2D) -> void:
	print("Raton fuera")
	BuildManager.OnGrid = true

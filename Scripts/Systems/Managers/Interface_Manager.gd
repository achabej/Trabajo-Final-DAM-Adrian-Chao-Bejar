extends Node

func _on_btn_build_extractor_button_down() -> void:
	BuildManager.SpawnExtractor()

func _on_btn_build_text_machine_button_down() -> void:
	BuildManager.SpawnTestCubeGenerator()

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


# Evita que se construya en la parte superior del menu
func _on_area_2d_area_entered(area: Area2D) -> void:
	BuildManager.OnGrid = false

func _on_area_2d_area_exited(area: Area2D) -> void:
	BuildManager.OnGrid = true

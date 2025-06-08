extends Node

var volume: float = 80
var screen: String = "Ventana"
var resolution: String = "1280x720"

const CONFIG_PATH := "user://settings.cfg"

func _ready():
	load_settings()

func set_volume(new_volume: float) -> void:
	volume = new_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume / 100.0))

func set_screen_mode(new_mode: String) -> void:
	screen = new_mode

	match new_mode:
		"Ventana":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"Pantalla completa":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"Sin bordes":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func set_resolution(res_string: String) -> void:
	resolution = res_string

	var parts = res_string.split("x")
	if parts.size() == 2:
		var width = int(parts[0])
		var height = int(parts[1])
		DisplayServer.window_set_size(Vector2i(width, height))

func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "volume", volume)
	file.set_value("video", "screen", screen)
	file.set_value("video", "resolution", resolution)

	var err := file.save(CONFIG_PATH)
	print("Guardando configuración en:", ProjectSettings.globalize_path(CONFIG_PATH))
	if err != OK:
		push_error("Error al guardar configuración: %s" % err)

func load_settings() -> void:
	print("Cargando configuración desde:", ProjectSettings.globalize_path(CONFIG_PATH))
	var file := ConfigFile.new()
	var err := file.load(CONFIG_PATH)

	if err == OK:
		if file.has_section_key("audio", "volume"):
			set_volume(file.get_value("audio", "volume"))
		if file.has_section_key("video", "screen"):
			set_screen_mode(file.get_value("video", "screen"))
		if file.has_section_key("video", "resolution"):
			set_resolution(file.get_value("video", "resolution"))
	else:
		print("No se encontró configuración guardada. Creando archivo nuevo.")
		save_settings()

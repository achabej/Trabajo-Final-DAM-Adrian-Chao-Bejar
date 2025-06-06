extends Node

var volume: float = 80
var screen: String = "Ventana"
var resolution: String = "1280x720"

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

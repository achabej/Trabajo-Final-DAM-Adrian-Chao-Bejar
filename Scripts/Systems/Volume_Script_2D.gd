extends AudioStreamPlayer2D

func _ready() -> void:
	# Verifica que el nodo al que está adjunto tiene 'volume_db'
	if has_method("set_volume_db"):
		update_volume()
		ConfigurationManager.connect("volume_changed", Callable(self, "on_volume_changed"))
	else:
		push_warning("Este nodo no tiene volumen ajustable con 'volume_db'.")

func on_volume_changed(new_volume: float) -> void:
	update_volume()

func update_volume() -> void:
	volume_db = linear_to_db(ConfigurationManager.volume / 100.0)

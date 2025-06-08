extends VisibleOnScreenEnabler3D

func _on_screen_entered() -> void:
	queue_free()

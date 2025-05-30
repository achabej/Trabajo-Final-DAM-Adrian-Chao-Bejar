extends VisibleOnScreenEnabler3D

func _on_screen_entered() -> void:
	set_process(false)

func _on_screen_exited() -> void:
	set_process(false)

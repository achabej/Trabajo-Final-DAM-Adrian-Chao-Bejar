extends VisibleOnScreenEnabler3D

func _on_screen_entered() -> void:
	$"../Mesh".visible = true

func _on_screen_exited() -> void:
	$"../Mesh".visible = false

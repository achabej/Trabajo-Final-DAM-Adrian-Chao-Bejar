extends Node

func _process(delta: float) -> void:
	if get_parent().is_in_group("Build"):
		queue_free()

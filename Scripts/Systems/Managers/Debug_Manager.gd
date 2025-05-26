extends Node

var fast_mode := false

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			toggle_time_scale()

func toggle_time_scale():
	fast_mode = not fast_mode
	Engine.time_scale = 2.0 if fast_mode else 1.0
	print("Time scale set to: ", Engine.time_scale)

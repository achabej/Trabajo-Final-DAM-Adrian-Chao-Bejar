extends Node

var fast_mode := false

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			toggle_time_scale()
		elif event.keycode == KEY_F6:
			auto_complete_phase()

func toggle_time_scale():
	fast_mode = not fast_mode
	Engine.time_scale = 2.0 if fast_mode else 1.0
	print("Time scale set to: ", Engine.time_scale)

func auto_complete_phase():
	if not GameManager:
		print("GameManager no está definido como autoload.")
		return

	var current_phase = GameManager.current_phase
	var phases = GameManager.phases
	var phase_key = "Phase%d" % current_phase

	if not phases.has(phase_key):
		print("Fase actual no válida o ya completada.")
		return

	var required_resources = phases[phase_key]["Resources"]
	for mat in required_resources.keys():
		var cantidad_requerida = required_resources[mat]
		GameManager.add_mat(mat, cantidad_requerida)

	print("Fase %d completada automáticamente con F6." % current_phase)

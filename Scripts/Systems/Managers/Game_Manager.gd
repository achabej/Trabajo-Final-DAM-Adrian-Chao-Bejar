extends Node
signal phase_changed(new_phase: int)
signal initialized

enum State {
	Play,
	Building,
	Destroying,
	Die,
	Ending
}

var currentState = State.Play
var input_message
var black_overlay

# Reloj para los conveys
@export var tick_interval : float = 1.0 
var tick_timer : float = 0.0 

#Lista de materiales necesarios para cada fase
var phases : Dictionary = {
	"Phase1": {
		"Resources": {
			"Iron_Ingot": 15,
			"Copper_Ingot": 15
		}
	},
	"Phase2": {
		"Resources": {
			"Steel_Ingot": 10,
			"Copper_Ingot": 15,
			"Cristal": 15
		}
	},
	"Phase3": {
		"Resources": {
			"Steel_Plate": 10,
			"Iron_Plate": 15,
			"Copper_Plate": 15,
		}
	},
	
	"Phase4": {
		"Resources": {	
			"Chip": 15,
			"Steel_Plate": 20,
			"Cristal": 30
		}
	},
	"Phase5": {
		"Resources": {
			"Chip": 20,
			"Steel_Plate": 20,
			"Copper_Plate": 15,
			"Cristal": 40
		}
	}
}

var current_phase 
var all_phases_completed = false
var storage = {} #inventario de las fases, aqui se guardan los maeteriales de las fases
var anim_player 

func init():
	tick_timer = tick_interval
	current_phase = 1  
	storage = {}
	
	#Inicializa el elemento del fundido en negro
	init_black_overlay()
	
	#Resetea el inventario del jugador
	BuildManager.materiales = {
		"Wood" : 0,
		"Iron" : 25,
		"Copper" : 0,
		"Cristal" : 0
	}
	
	input_message = get_tree().get_root().get_node("Node3D/Player/CanvasLayer/HUD/Phase_Input_UI")

	anim_player = get_tree().get_root().get_node_or_null("Node3D/Scene_Manager/AnimationPlayer")
	if anim_player:
		anim_player.active = false  
	
	var ship = get_tree().get_root().get_node("Node3D/Terrain/Main_Ship_Constructor/Ship_Controller")
	if ship:
		print("Nave encontrada")
		ship.connect("player_ready_for_next_phase", Callable(self, "_on_player_confirm_phase"))
		ship.connect("play_ending_anim", Callable(self, "_on_play_ending_anim"))
		
	GameManager.connect("phase_changed", Callable(self, "_on_phase_changed"))

	_update_phase_storage()
	_update_ui()
	
	emit_signal("initialized")

	await get_tree().process_frame
	DialogManager.show_dialogues_for_phase(current_phase)

func init_black_overlay():
	black_overlay = get_tree().get_nodes_in_group("Black_overlay")
	if black_overlay != null:
		black_overlay = black_overlay[0]

func add_mat(material_type: String, amount: int = 1) -> void:
	var phase_key = "Phase%d" % current_phase
	if not phases.has(phase_key):
		return
	
	var max_amount = phases[phase_key]["Resources"].get(material_type, 0)
	if max_amount == 0:
		return
	
	if storage.get(material_type, 0) >= max_amount:
		match material_type:
			"Iron_Ingot":
				BuildManager.increase_mat("Iron", 2)
			"Copper_Ingot":
				BuildManager.increase_mat("Copper", 2)
			"Iron_Plate":
				BuildManager.increase_mat("Iron", 3)
			"Copper_Plate":
				BuildManager.increase_mat("Copper", 3)
			"Steel_Plate":
				BuildManager.increase_mat("Iron", 2)
				BuildManager.increase_mat("Copper", 2)
			"Cristal":
				BuildManager.increase_mat("Cristal", 1)
		return
	
	if not storage.has(material_type):
		storage[material_type] = 0
	storage[material_type] += amount
	
	if storage[material_type] > max_amount:
		storage[material_type] = max_amount
		
	_update_ui()
	
	# Esperamos que el jugador confirme la fase acercándose a la nave
	if _check_phase_complete():
		print("✅ Fase completada, esperando confirmación en la nave...")
		_show_advance_instruction()

func _show_advance_instruction():
	var player = get_tree().get_root().get_node("Node3D/Player")
	if not player:
		return

func _on_player_confirm_phase():
	if not _check_phase_complete():
		return  # seguridad
	
	current_phase += 1
	emit_signal("phase_changed", current_phase)

	if current_phase > phases.size():
		storage.clear()
		_update_ui()
		return
	
	storage.clear()
	_update_phase_storage()
	_update_ui()

func _update_phase_storage() -> void:
	# Inicializar el storage para la fase actual, para que tenga todas las claves con 0
	var phase_key = "Phase%d" % current_phase
	if phases.has(phase_key):
		for mat in phases[phase_key]["Resources"].keys():
			if not storage.has(mat):
				storage[mat] = 0

func _check_phase_complete() -> bool:
	var phase_key = "Phase%d" % current_phase
	if not phases.has(phase_key):
		return false
	
	for mat in phases[phase_key]["Resources"].keys():
		var required = phases[phase_key]["Resources"][mat]
		if storage.get(mat, 0) < required:
			return false
	
	return true

func _update_ui() -> void:
	var player = get_tree().get_root().get_node("Node3D/Player")
	if not player:
		return
	
	var phase_controller = player.get_node_or_null("CanvasLayer/HUD/Phase_Controller")
	if not phase_controller:
		return

	# Si ya se completaron todas las fases
	if current_phase > phases.size():
		phase_controller.update_phase_text("[color=green][b]FASES COMPLETADAS[/b][/color]")
		all_phases_completed = true
		return
	
	var phase_key = "Phase%d" % current_phase
	if not phases.has(phase_key):
		return
	
	# Si la fase está completa, mostrar solo el mensaje para ir a la nave
	if _check_phase_complete():
		var header = "[b]Phase %d[/b]" % current_phase
		var message = "[color=green]Ve a la plataforma para construir la siguiente pieza[/color]"
		phase_controller.update_phase_text("%s\n%s" % [header, message])
		return

	# Si no está completa, mostrar materiales normalmente
	var text = "[b]Phase %d[/b]\n" % current_phase
	for mat in phases[phase_key]["Resources"].keys():
		var have = storage.get(mat, 0)
		var need = phases[phase_key]["Resources"][mat]
		if have >= need:
			text += "[color=green]    %s %d/%d[/color]\n" % [mat, have, need]
		else:
			text += "    %s %d/%d\n" % [mat, have, need]
	
	phase_controller.update_phase_text(text)

func _on_phase_changed(new_phase: int):
	DialogManager.show_dialogues_for_phase(new_phase)
	if BuildManager.CurrentSpawnable != null:
		BuildManager.CurrentSpawnable.queue_free()
		BuildManager.CurrentSpawnable = null

func _on_play_ending_anim():
	anim_player.active = true
	anim_player.play("Ending_Anim")	
	currentState = State.Ending
	
	await get_tree().create_timer(3.0).timeout
	fade_black_overlay(false)

	await get_tree().create_timer(3.0).timeout

	get_tree().change_scene_to_file("res://Scenes/Ending_Scene.tscn")

# Animación del fundido en negro
func fade_black_overlay(fade_in: bool, duration := 1.2, wait_before := 0.5, hide_on_finish := true) -> void:
	black_overlay.visible = true

	if wait_before > 0:
		await get_tree().create_timer(wait_before).timeout

	var from: float
	var to: float

	if fade_in:
		from = 1.0
		to = 0.0
	else:
		from = 0.0
		to = 1.0

	black_overlay.modulate.a = from

	var tween := create_tween()
	tween.tween_property(black_overlay, "modulate:a", to, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	if fade_in and hide_on_finish:
		black_overlay.visible = false

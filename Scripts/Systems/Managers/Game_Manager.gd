extends Node
signal phase_changed(new_phase: int)

enum State {
	Play,
	Building,
	Destroying
}

var currentState = State.Play
var input_message

# Reloj para los conveys
@export var tick_interval : float = 1.0 
var tick_timer : float = 0.0 

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

var storage = {}

func init():
	tick_timer = tick_interval
	current_phase = 1  
	storage = {}

	input_message = get_tree().get_root().get_node("Node3D/Player/CanvasLayer/HUD/Phase_Input_UI")

	var ship = get_tree().get_root().get_node("Node3D/NavigationRegion3D/Main_Ship_Constructor/Ship_Controller")
	if ship:
		ship.connect("player_ready_for_next_phase", Callable(self, "_on_player_confirm_phase"))

	GameManager.connect("phase_changed", Callable(self, "_on_phase_changed"))
	emit_signal("initialized")

	_update_phase_storage()
	_update_ui()
	
	await get_tree().process_frame
	DialogManager.show_dialogues_for_phase(current_phase)
	
func add_mat(material_type: String, amount: int = 1) -> void:
	var phase_key = "Phase%d" % current_phase
	if not phases.has(phase_key):
		return
	
	var max_amount = phases[phase_key]["Resources"].get(material_type, 0)
	if max_amount == 0:
		return
	
	if storage.get(material_type, 0) >= max_amount:
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

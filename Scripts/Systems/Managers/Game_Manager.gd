extends Node

enum State {
	Play,
	Building,
	Destroying
}

var currentState = State.Play

# Reloj para los conveys
@export var tick_interval : float = 1.0 
var tick_timer : float = 0.0 

var phases : Dictionary = {
	"Phase1": {
		"Resources": {
			"Iron_Ingot": 20,
			"Copper_Ingot": 2
		}
	},
	"Phase2": {
		"Resources": {
			"Steel_Ingot": 25,
			"Copper_Ingot": 20,
		}
	},
	"Phase3": {
		"Resources": {
			"Steel_Plate": 15,
			"Iron_Plate": 20,
			"Copper_Plate": 20,
		}
	},
	
	"Phase4": {
		"Resources": {
			"Chips": 20,
			"Steel_Plate": 30,
			"Cristal": 15
		}
	},
	"Phase5": {
		"Resources": {
			"Chips": 25,
			"Steel_Plate": 50,
			"Copper_Plate": 50,
			"Cristal": 25
		}
	}
}
var current_phase 

var storage = {}

func _ready() -> void:
	tick_timer = tick_interval
	current_phase = 1  # Mejor usar índice 1-based para coincidir con nombres de fases "Phase1"
	storage = {}
	_update_phase_storage()
	_update_ui()

func add_mat(material_type: String, amount: int = 1) -> void:
	var phase_key = "Phase%d" % current_phase
	if not phases.has(phase_key):
		return
	
	var max_amount = phases[phase_key]["Resources"].get(material_type, 0)
	
	if max_amount == 0:
		# Material no requerido en esta fase
		return
	
	# Si ya se tiene la cantidad necesaria, no sumar más
	if storage.get(material_type, 0) >= max_amount:
		return
	
	if not storage.has(material_type):
		storage[material_type] = 0
	
	storage[material_type] += amount
	
	# Limitar a la cantidad máxima requerida
	if storage[material_type] > max_amount:
		storage[material_type] = max_amount
	
	_update_ui()
	
	if _check_phase_complete():
		current_phase += 1
		if current_phase > phases.size():
			current_phase = phases.size()
		storage.clear()
		_update_phase_storage()

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
	
	var phase_controller = player.get_node_or_null("CanvasLayer/Phase_Controller")
	if not phase_controller:
		return
	
	var phase_key = "Phase%d" % current_phase
	if not phases.has(phase_key):
		return
	
	var text = "[b]Phase %d[/b]\n" % current_phase
	for mat in phases[phase_key]["Resources"].keys():
		var have = storage.get(mat, 0)
		var need = phases[phase_key]["Resources"][mat]
		if have >= need:
			# Línea en verde cuando se cumple el requisito
			text += "[color=green]    %s %d/%d[/color]\n" % [mat, have, need]
		else:
			text += "    %s %d/%d\n" % [mat, have, need]
	
	phase_controller.update_phase_text(text)

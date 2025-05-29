extends Node

var dialogue_text := {
	1: [
		"[0.04]Oh no!!![pause=0.3] Ha explotado la estación!![pause=0.4] Bueno...[pause=0.3] espero que no haya sido mi culpa...[pause=0.5][0.05] Otra vez",
		"[0.04]De todas formas tengo que encontrar una manera de salir de aqui,[pause=0.2] será mejor que construya una nave",
		"[0.04]Debería de empezar por la base"
	],
	2: [
		"[0.04]Con una buena base todo debería saldrá bien...[pause=0.3][0.05] eso espero.",
		"[0.04]Tengo que buscar mas materiales para hacer los motores"
	],
	3: [
		"[0.04]Guay! Parece ser suficiente para salir del planeta... creo que aun le falta algo",
		"[0.04]Ya se, le añadiré unas alas para mayor aerodinamica",
	],
	4: [
		"[0.1]...[0.04] Aun parece incompleto, ¿Qué mas deberia añadirle?",
		"[0.04]¿Una antena de comunicaciones quizas?, me gusta pilotar escuchando un poco de musica",
	],
	5: [
		"[0.04]Esta quedando genial pero, ¿Y si me apetece pararme en Skirm V?, sus playas son geniales!",
		"[0.04]Deberia de mejorar la propulsion... Voy a añadirle un motor de salto",
	],
	6: [
		"[0.04]Siento que aun le faltan cosas... Pero creo que se hace tarde",
		"[0.04]Mejor despego y continuaré en otro planeta",
	],
	7: [
		"[0.1]...",
		"[0.04]Vaya... Creo que me he... Sobrecomplicado un poco... jejeje",
	]
}

var dialogue_node: Control = null
var dialogue_list: Array = []
var dialogue_index: int = 0
var is_showing := false
var is_dialogue_active := false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("left_click"):
		DialogManager.on_click_advance()

func register_dialogue_node(node: Control) -> void:
	dialogue_node = node
	dialogue_node.hide()

func show_dialogues_for_phase(phase: int) -> void:
	if not dialogue_text.has(phase) or dialogue_node == null:
		return

	is_dialogue_active = true
	dialogue_list = dialogue_text[phase]
	dialogue_index = 0
	is_showing = true
	dialogue_node.show()
	_update_text()

func _hide_dialogue():
	if dialogue_node:
		dialogue_node.hide()
	is_showing = false
	is_dialogue_active = false

func _update_text():
	if dialogue_index < dialogue_list.size():
		var msg = dialogue_list[dialogue_index]
		dialogue_node.call("update_message", msg, 24.0, 0.02)  
	else:
		_hide_dialogue()

func on_click_advance():
	if not is_showing:
		return

	# Si está escribiendo, mostrar todo el texto directamente
	if dialogue_node.get("is_typing"):
		dialogue_node.call("skip_typing")
	else:
		dialogue_index += 1
		_update_text()

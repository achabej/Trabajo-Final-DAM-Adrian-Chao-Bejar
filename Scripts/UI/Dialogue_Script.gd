extends Control
class_name Dialogue

@onready var content: RichTextLabel = $Content
@onready var type_timer: Timer = $TypeTimer
@onready var pause_timer: Timer = $PauseTimer

@onready var dialog_sound : AudioStreamPlayer2D = $Dialog_Beeps
@export var beeps_list : Array[AudioStream] = []
var char_beep_interval := 1 

var full_text: String = ""
var current_index: int = 0
var is_typing: bool = false

func _ready() -> void:
	DialogManager.register_dialogue_node(self)
	hide()
	
	type_timer.start()

func _on_pause_timer_timeout() -> void:
	type_timer.start()  # Reanudar la escritura

func update_message(message: String, text_size: float, text_veloc: float) -> void:
	is_typing = true
	full_text = message
	current_index = 0

	var clean_text = ""
	var i = 0
	while i < message.length():		
		if message[i] == "[":
			var end_index = message.find("]", i)
			if end_index == -1:
				clean_text += message[i]
				i += 1
				continue
			i = end_index + 1  # saltar comando
		else:
			clean_text += message[i]
			i += 1

	content.text = clean_text
	content.visible_characters = 0
	content.add_theme_font_size_override("normal_font_size", text_size)
	type_timer.wait_time = text_veloc
	type_timer.start()

func _process_command(command: String) -> void:
	#Si es un numero cambia la velocidad de las letras
	if command.is_valid_float():
		type_timer.wait_time = command.to_float()
	#Si es pause pausa el texto por x segundos
	elif command.begins_with("pause="):
		var duration = command.replace("pause=", "").to_float()
		type_timer.stop()
		pause_timer.start(duration)

#Omite la generación de texto cuando le demos click izquiedo
func skip_typing():
	if not is_typing:
		return

	type_timer.stop()
	pause_timer.stop()

	content.visible_characters = full_text.length()
	current_index = full_text.length()
	is_typing = false

func _on_type_timer_timeout() -> void:
	if current_index >= full_text.length():
		type_timer.stop()
		is_typing = false
		return

	# Detectar comandos del tipo [0.05]
	if full_text[current_index] == "[":
		var end_index = full_text.find("]", current_index)
		if end_index != -1:
			var command = full_text.substr(current_index + 1, end_index - current_index - 1)
			_process_command(command)
			current_index = end_index + 1
			return

	# Si no es un comando, mostrar el carácter
	content.visible_characters += 1
	current_index += 1

	# 🔊 Reproducir sonido aleatorio de escritura
	if (current_index % char_beep_interval == 0) and beeps_list.size() > 0:
		if not dialog_sound.playing:
			var random_sound = beeps_list[randi() % beeps_list.size()]
			dialog_sound.stream = random_sound
			dialog_sound.play()

extends Node3D

@onready var title_text = $CanvasLayer/Title
@onready var subtitle_text = $CanvasLayer/Subtitle
@onready var next_scene_timer = $Next_Scene_Timer
@onready var animation_player = $AnimationPlayer

var total_time := 0.0
var title_anim_time := 0.0
var subtitle_anim_time := 0.0

var title_grow_duration := 1.2
var subtitle_delay := 0.5
var subtitle_grow_duration := 1.2

var is_title_animating := false
var is_subtitle_animating := false

func _ready() -> void:
	# Inicia la animación principal
	animation_player.play("Ending_Cutscene_Anim")
	# Conecta señal de fin de diálogo (si está disponible)
	DialogManager.connect("dialog_finished", Callable(self, "_on_dialog_finished"))


func _process(delta: float) -> void:
	total_time += delta

	# 🎨 Efecto de color dinámico
	var speed = 2.0
	var r = (sin(total_time * speed) + 1.0) * 0.5
	var g = (sin(total_time * speed + TAU / 3) + 1.0) * 0.5
	var b = (sin(total_time * speed + TAU * 2 / 3) + 1.0) * 0.5
	var color = Color(r, g, b, 1.0)

	title_anim_time += delta
	title_text.add_theme_color_override("font_shadow_color", color)

	if title_anim_time <= title_grow_duration:
		var t = title_anim_time / title_grow_duration
		var scale = lerp(0.1, 1.2, ease_out_cubic(t))
		title_text.scale = Vector2(scale, scale)


	subtitle_anim_time += delta
	if subtitle_anim_time >= subtitle_delay:
		var anim_t = (subtitle_anim_time - subtitle_delay) / subtitle_grow_duration
		if anim_t <= 1.0:
			var scale = lerp(0.1, 1.0, ease_out_cubic(anim_t))
			subtitle_text.scale = Vector2(scale, scale)
			subtitle_text.add_theme_color_override("font_shadow_color", color)

# 🎬 Cuando termina el diálogo
func _on_dialog_finished() -> void:
	animation_player.play("Ending_Cutscene_Final")
	_show_title()

# 🎥 Cuando termina una animación
func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Ending_Cutscene_Anim":
		animation_player.get_animation("Ending_Cutscene_Loop").loop = true
		animation_player.play("Ending_Cutscene_Loop")

		$CanvasLayer/Dialogue.visible = true
		DialogManager.show_dialogues_for_phase(7)

# 🧾 Mostrar título y subtítulo
func _show_title() -> void:
	title_text.scale = Vector2(0.01, 0.01)
	subtitle_text.scale = Vector2(0.01, 0.01)

	title_text.visible = true
	subtitle_text.visible = true

	total_time = 0.0
	title_anim_time = 0.0
	subtitle_anim_time = 0.0

	is_title_animating = true
	is_subtitle_animating = false

	# ⏱️ Iniciar temporizador para cambiar escena
	next_scene_timer.start(15.0)

# 🛫 Cambia de escena cuando el temporizador termina
func _on_next_scene_timer_timeout() -> void:	
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")

# 🎚 Función de interpolación para animaciones suaves
func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 4)

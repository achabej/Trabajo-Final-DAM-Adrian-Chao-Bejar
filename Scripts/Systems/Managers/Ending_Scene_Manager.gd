extends Node3D

@onready var title_text = $CanvasLayer/Title
@onready var subtitle_text = $CanvasLayer/Subtitle
@onready var next_scene_timer = $Next_Scene_Timer

var total_time := 0.0
var title_anim_time := 0.0
var subtitle_anim_time := 0.0

var title_grow_duration := 1.2
var subtitle_delay := 0.5
var subtitle_grow_duration := 1.2

var is_title_animating := false
var is_subtitle_animating := false

func _ready() -> void:
	$AnimationPlayer.play("Ending_Cutscene_Anim")

func _process(delta: float) -> void:
	total_time += delta

	# 🎨 Efecto de color dinámico
	var speed = 2.0
	var r = (sin(total_time * speed) + 1.0) * 0.5
	var g = (sin(total_time * speed + TAU / 3) + 1.0) * 0.5
	var b = (sin(total_time * speed + 2.0 * TAU / 3) + 1.0) * 0.5
	var color = Color(r, g, b, 1.0)

	if is_title_animating:
		title_anim_time += delta
		title_text.add_theme_color_override("font_shadow_color", color)

		if title_anim_time <= title_grow_duration:
			var t = title_anim_time / title_grow_duration
			var scale = lerp(0.1, 1.2, ease_out_cubic(t))
			title_text.scale = Vector2(scale, scale)
		else:
			is_title_animating = false
			is_subtitle_animating = true  # Empieza el subtítulo después

	if is_subtitle_animating:
		subtitle_anim_time += delta
		if subtitle_anim_time >= subtitle_delay:
			var anim_t = (subtitle_anim_time - subtitle_delay) / subtitle_grow_duration
			if anim_t <= 1.0:
				var scale = lerp(0.1, 1.0, ease_out_cubic(anim_t))
				subtitle_text.scale = Vector2(scale, scale)
				subtitle_text.add_theme_color_override("font_shadow_color", color)

# 📦 Ease para animaciones
func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 4)

# 🎬 Llamado cuando termina el diálogo
func _on_dialog_finished():
	$AnimationPlayer.play("Ending_Cutscene_Final")  
	_show_title()

# 🎥 Llamado cuando termina la animación
func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Ending_Cutscene_Anim":
		$AnimationPlayer.get_animation("Ending_Cutscene_Loop").loop = true
		$AnimationPlayer.play("Ending_Cutscene_Loop")  
		
		$CanvasLayer/Dialogue.visible = true
		DialogManager.show_dialogues_for_phase(7)

# 🧾 Mostrar título + subtítulo y arrancar Timer
func _show_title():
	title_text.scale = Vector2(0.01, 0.01)
	subtitle_text.scale = Vector2(0.01, 0.01)

	title_text.visible = true
	subtitle_text.visible = true

	total_time = 0.0
	title_anim_time = 0.0
	subtitle_anim_time = 0.0

	is_title_animating = true
	is_subtitle_animating = false

	# ⏱️ Iniciar timer para cambiar de escena
	next_scene_timer.start(5.0)

# 🛫 Cargar Main_Menu.tscn cuando el timer termina
func _on_next_scene_timer_timeout():
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")

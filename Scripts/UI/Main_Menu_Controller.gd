extends Control

@onready var title_text = $RichTextLabel
@onready var menu_panel = $Menu_Panel
@onready var space_station_sprite = $Background/Space_station
@onready var explosion_sprite = $Background/Space_station/Explosion
@onready var flash_overlay = $flash_overlay
@onready var black_overlay = $black_overlay

var total_time := 0.0
var anim_time := 0.0
var speed := 2.0
var delay := 0.5
var title_grow_duration := 1.2
var has_shown_menu := false
var play_pressed := false

func _ready() -> void:
	title_text.scale = Vector2(0.01, 0.01)
	menu_panel.modulate.a = 0.0
	explosion_sprite.visible = false
	
	flash_overlay.modulate.a = 0.0
	flash_overlay.visible = false

	black_overlay.modulate.a = 0.0
	black_overlay.visible = false

func _process(delta: float) -> void:
	total_time += delta
	
	# Animación de la estación
	var y_offset = sin(total_time * 1.2) * 5.0
	space_station_sprite.position.y = 100 + y_offset

	#Animación del título 
	var r = (sin(total_time * speed) + 1.0) * 0.5
	var g = (sin(total_time * speed + TAU / 3) + 1.0) * 0.5
	var b = (sin(total_time * speed + 2.0 * TAU / 3) + 1.0) * 0.5
	title_text.add_theme_color_override("font_shadow_color", Color(r, g, b, 1.0))

	if not play_pressed and total_time >= delay:
		anim_time += delta
		if anim_time <= title_grow_duration:
			var t = anim_time / title_grow_duration
			var scale = lerp(0.1, 1.2, ease_out_cubic(t))
			title_text.scale = Vector2(scale, scale)
		elif not has_shown_menu:
			show_menu_fade_in()
			has_shown_menu = true

func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 4)

func show_menu_fade_in():
	var fade_duration := 1.0
	var tween := create_tween()
	tween.tween_property(menu_panel, "modulate:a", 1.0, fade_duration)

func _on_play_btn_pressed() -> void:
	play_pressed = true
	menu_panel.visible = false
	title_text.visible = false
	start_play_transition()

func start_play_transition():
	flash_overlay.visible = true

	var tween := create_tween()

	# 1. Mostrar flash rápidamente
	tween.tween_property(flash_overlay, "modulate:a", 1.0, 0.1)

	# 2. Después de mostrar el flash, esperar 1 segundo antes de continuar
	tween.tween_callback(func ():
		await get_tree().create_timer(1.0).timeout

		# Mostrar explosión al terminar la espera (puedes activarla aquí si lo deseas)
		explosion_sprite.visible = true

		# Ahora desvanecer el flash lentamente
		var fade_tween := create_tween()
		fade_tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.75)

		# Después de 3 segundos desde el inicio, mostrar fundido negro
		await get_tree().create_timer(2.0).timeout  # 1s + 2s = 3s total

		black_overlay.visible = true
		var black_tween := create_tween()
		black_tween.tween_property(black_overlay, "modulate:a", 1.0, 1.0)
		black_tween.tween_callback(_load_next_scene)
	)

func _load_next_scene():
	var Planet1_scene = preload("res://Scenes/Planet_1.tscn")
	get_tree().change_scene_to_packed(Planet1_scene)

func _on_options_btn_pressed() -> void:
	pass

func _on_exit_btn_pressed() -> void:
	get_tree().quit()

extends Node3D

@onready var title_text = $CanvasLayer/Title
@onready var subtitle_text = $CanvasLayer/Subtitle

var total_time := 0.0
var anim_time := 0.0
var title_grow_duration := 1.2
var show_title_animating := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.init_black_overlay()
	GameManager.fade_black_overlay(true)
	$AnimationPlayer.play("Ending_Cutscene_Anim")
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	
	DialogManager.connect("dialog_finished", Callable(self, "_on_dialog_finished"))

func _process(delta: float) -> void:
	if show_title_animating:
		total_time += delta
		anim_time += delta

		# Animación de color arcoiris
		var speed = 1.0
		var r = (sin(total_time * speed) + 1.0) * 0.5
		var g = (sin(total_time * speed + TAU / 3) + 1.0) * 0.5
		var b = (sin(total_time * speed + 2.0 * TAU / 3) + 1.0) * 0.5
		title_text.add_theme_color_override("font_shadow_color", Color(r, g, b, 1.0))

		# Escalado con easing
		if anim_time <= title_grow_duration:
			var t = anim_time / title_grow_duration
			var scale = lerp(0.1, 1.2, ease_out_cubic(t))
			title_text.scale = Vector2(scale, scale)

func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 4)

func _on_dialog_finished():
	$AnimationPlayer.play("Ending_Cutscene_Final")  
	_show_title()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Ending_Cutscene_Anim":
		$AnimationPlayer.get_animation("Ending_Cutscene_Loop").loop = true
		$AnimationPlayer.play("Ending_Cutscene_Loop")  
		
		$CanvasLayer/Dialogue.visible = true
		DialogManager.show_dialogues_for_phase(7)

func _show_title():
	title_text.scale = Vector2(0.01, 0.01)
	title_text.visible = true
	total_time = 0.0
	anim_time = 0.0
	show_title_animating = true

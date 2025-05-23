extends Node

@export var popup_scene: PackedScene
@export var popup_spawn_point: Node2D

var popup_queue: Array = []
var processing_queue := false

func show_material_popup(text: String, color: Color = Color.WHITE) -> void:
	popup_queue.append({"text": text, "color": color})
	if not processing_queue:
		_process_queue()

# Corrutina para procesar la cola con retardo
func _process_queue() -> void:
	processing_queue = true
	while popup_queue.size() > 0:
		var entry = popup_queue.pop_front()
		var popup = popup_scene.instantiate() as Label
		popup.text = entry.text
		popup.add_theme_color_override("font_color", entry.color)
		popup.position = Vector2.ZERO  # En el origen local de popup_spawn_point
		popup_spawn_point.add_child(popup)  # Se instancia como hijo directamente

		var anim = popup.get_node("AnimationPlayer")
		anim.play("float_up")

		await get_tree().create_timer(0.2).timeout
	processing_queue = false

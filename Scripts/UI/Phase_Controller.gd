extends Control

var base_text := ""

func update_phase_text(text: String) -> void:
	base_text = text
	$RichTextLabel.text = base_text

func append_instruction(instruction: String) -> void:
	$RichTextLabel.text = base_text + "\n\n" + instruction

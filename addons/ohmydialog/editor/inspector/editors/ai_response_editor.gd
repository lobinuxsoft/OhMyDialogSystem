@tool
class_name AIResponseEditor
extends BaseNodeEditor
## Inspector editor for AI_RESPONSE nodes.
##
## Shows character, prompt template, emotion hint, and max tokens fields.


const EMOTIONS: Array[String] = ["", "neutral", "happy", "sad", "angry", "surprised", "confused", "scared"]


func _setup_ui() -> void:
	_add_header("AI Response")
	_add_separator()
	_add_line_edit("Character ID", "character_id", "res://path/to/character.tres")
	_add_text_edit("Prompt Template", "prompt_template", 80)
	_add_option_button("Emotion Hint", "emotion_hint", EMOTIONS)
	_add_spin_box("Max Tokens", "max_tokens", 32, 2048, 32)

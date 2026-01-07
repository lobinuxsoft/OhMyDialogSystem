@tool
class_name StaticResponseEditor
extends BaseNodeEditor
## Inspector editor for STATIC_RESPONSE nodes.
##
## Shows speaker, text, and emotion fields.


const EMOTIONS: Array[String] = ["", "neutral", "happy", "sad", "angry", "surprised", "confused", "scared"]


func _setup_ui() -> void:
	_add_header("Static Response")
	_add_separator()
	_add_line_edit("Speaker", "speaker", "Character name")
	_add_text_edit("Text", "text", 100)
	_add_option_button("Emotion", "emotion", EMOTIONS)

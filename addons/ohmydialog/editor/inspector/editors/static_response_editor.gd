@tool
class_name StaticResponseEditor
extends BaseNodeEditor
## Inspector editor for STATIC_RESPONSE nodes.
##
## Shows speaker, text, and emotion fields.


const EMOTIONS: Array[String] = ["", "neutral", "happy", "sad", "angry", "surprised", "confused", "scared"]


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super(node_data, graph)
	ACCENT_COLOR = Color("#6b7280")  # Static response gray


func _setup_ui() -> void:
	_create_main_header("Static Response", "💬")

	var content_section := _create_section("Content")
	_add_line_edit("Speaker", "speaker", "Character name", content_section)
	_add_text_edit("Text", "text", 100, content_section)
	_add_option_button("Emotion", "emotion", EMOTIONS, 0, content_section)

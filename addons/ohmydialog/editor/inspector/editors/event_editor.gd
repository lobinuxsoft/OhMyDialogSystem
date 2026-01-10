@tool
class_name EventEditor
extends BaseNodeEditor
## Inspector editor for EVENT nodes.
##
## Shows event name field. Event data is edited via metadata.


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super(node_data, graph)
	ACCENT_COLOR = Color("#a855f7")  # Event node purple


func _setup_ui() -> void:
	_create_main_header("Event Node", "⚡")

	var event_section := _create_section("Event Configuration")
	_add_line_edit("Event Name", "event_name", "signal_name", event_section)

	# Note about event_data
	var note := Label.new()
	note.text = "Event data can be added via metadata below."
	note.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	note.add_theme_font_size_override("font_size", 11)
	event_section.add_child(note)

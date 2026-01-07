@tool
class_name EventEditor
extends BaseNodeEditor
## Inspector editor for EVENT nodes.
##
## Shows event name field. Event data is edited via metadata.


func _setup_ui() -> void:
	_add_header("Event Node")
	_add_separator()
	_add_line_edit("Event Name", "event_name", "signal_name")

	# Note about event_data
	var note := Label.new()
	note.text = "Event data can be added via metadata below."
	note.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	note.add_theme_font_size_override("font_size", 11)
	add_child(note)

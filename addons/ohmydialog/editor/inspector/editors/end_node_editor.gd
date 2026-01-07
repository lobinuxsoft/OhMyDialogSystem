@tool
class_name EndNodeEditor
extends BaseNodeEditor
## Inspector editor for END nodes.
##
## Shows the reason field for analytics/debugging.


func _setup_ui() -> void:
	_add_header("End Node")
	_add_separator()
	_add_line_edit("Reason", "reason", "Optional reason/tag")

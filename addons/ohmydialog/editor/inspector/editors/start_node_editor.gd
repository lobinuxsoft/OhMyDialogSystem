@tool
class_name StartNodeEditor
extends BaseNodeEditor
## Inspector editor for START nodes.
##
## Shows the trigger field for event-based dialogue starts.


func _setup_ui() -> void:
	_add_header("Start Node")
	_add_separator()
	_add_line_edit("Trigger", "trigger", "Event name (empty = manual)")

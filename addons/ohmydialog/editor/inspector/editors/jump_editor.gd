@tool
class_name JumpEditor
extends BaseNodeEditor
## Inspector editor for JUMP nodes.
##
## Allows selecting a target DialogueGraph and optional node ID.


func _setup_ui() -> void:
	_add_header("Jump Node")
	_add_separator()

	# Target graph resource picker
	_add_resource_picker("Target Graph", "target_graph_id", "DialogueGraph")

	# Optional target node ID within the graph
	_add_line_edit("Target Node", "target_node_id", "Node ID (empty = start)")

	_add_separator()

	# Preserve context checkbox
	_add_check_box("Preserve Context", "preserve_context", false)

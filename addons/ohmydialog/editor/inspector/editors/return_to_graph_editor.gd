@tool
class_name ReturnToGraphEditor
extends BaseNodeEditor
## Inspector editor for RETURN_TO_GRAPH nodes.
##
## Shows the return node ID field.


func _setup_ui() -> void:
	_add_header("Return to Graph")
	_add_separator()
	_add_line_edit("Return Node", "return_node_id", "Node ID (empty = continue)")

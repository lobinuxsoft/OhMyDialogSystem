@tool
class_name ReturnToGraphEditor
extends BaseNodeEditor
## Inspector editor for RETURN_TO_GRAPH nodes.
##
## Shows the return node ID field.


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super(node_data, graph)
	ACCENT_COLOR = Color("#14b8a6")  # Return node teal (matches Jump)


func _setup_ui() -> void:
	_create_main_header("Return to Graph", "↩")

	var config_section := _create_section("Configuration")
	_add_line_edit("Return Node", "return_node_id", "Node ID (empty = continue)", config_section)

@tool
class_name JumpEditor
extends BaseNodeEditor
## Inspector editor for JUMP nodes.
##
## Allows selecting a target DialogueGraph and optional node ID.


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super(node_data, graph)
	ACCENT_COLOR = Color("#14b8a6")  # Jump node teal


func _setup_ui() -> void:
	_create_main_header("Jump Node", "↗")

	var target_section := _create_section("Target Configuration")
	_add_resource_picker("Target Graph", "target_graph_id", "DialogueGraph", target_section)
	_add_line_edit("Target Node", "target_node_id", "Node ID (empty = start)", target_section)

	var options_section := _create_section("Options")
	_add_check_box("Preserve Context", "preserve_context", false, options_section)

@tool
class_name JumpNode
extends BaseDialogueNode
## Visual node for jumping to another graph or node.
##
## Has one input and no outputs (flow continues at the target).
## Preserves AI model in memory when jumping.


func _configure_slots() -> void:
	clear_all_slots()
	# One input, no output (jumps elsewhere)
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)


func _create_content_ui() -> void:
	var target_graph: String = node_data.data.get("target_graph_id", "")
	var target_node: String = node_data.data.get("target_node_id", "")
	var preserve_context: bool = node_data.data.get("preserve_context", false)

	# Show graph name (extract filename from path)
	var graph_display: String = target_graph
	if not target_graph.is_empty():
		graph_display = target_graph.get_file().get_basename()
	_add_info("Graph", graph_display)

	if not target_node.is_empty():
		_add_info("Node", target_node)

	# Show context preservation status
	if preserve_context:
		_add_info("Context", "Preserved", Color("#22c55e"))

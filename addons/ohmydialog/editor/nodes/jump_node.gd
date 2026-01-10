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
	var jump_node := node_data as JumpNodeData
	var target_graph: String = jump_node.target_graph_id if jump_node else ""
	var target_node: String = jump_node.target_node_id if jump_node else ""
	var preserve_context: bool = jump_node.preserve_context if jump_node else false

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

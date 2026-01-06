@tool
class_name JumpNode
extends BaseDialogueNode
## Visual node for jumping to another graph or node.
##
## Has one input and no outputs (flow continues at the target).


func _configure_slots() -> void:
	clear_all_slots()
	# One input, no output (jumps elsewhere)
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)


func _create_content_ui() -> void:
	var target_graph: String = node_data.data.get("target_graph_id", "")
	var target_node: String = node_data.data.get("target_node_id", "")

	if target_graph.is_empty():
		_add_hint_label("→ (No target)")
	else:
		var display := "→ %s" % target_graph
		if not target_node.is_empty():
			display += " : %s" % target_node
		_add_label(display)

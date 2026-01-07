@tool
class_name ReturnToGraphNode
extends BaseDialogueNode
## Visual node for returning from free mode to graph execution.
##
## Exits free conversation and returns to the scripted dialogue flow.


func _configure_slots() -> void:
	clear_all_slots()
	# One input, no output (returns to previous context)
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)


func _create_content_ui() -> void:
	var return_node: String = node_data.data.get("return_node_id", "")
	_add_hint_label("<- Return to graph")
	if not return_node.is_empty():
		_add_info("Node", return_node)

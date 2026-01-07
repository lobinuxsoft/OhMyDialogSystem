@tool
class_name EndNode
extends BaseDialogueNode
## Visual node representing the termination point of a dialogue.
##
## The END node has one input and no outputs. Multiple END nodes
## can exist in a graph for different endings.


func _configure_slots() -> void:
	clear_all_slots()
	# One input, no output
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)


func _create_content_ui() -> void:
	var reason: String = node_data.data.get("reason", "")
	if reason.is_empty():
		_add_hint_label("Dialogue ends here")
	else:
		_add_info("Reason", reason)

@tool
class_name JumpToFreeNode
extends BaseDialogueNode
## Visual node for entering free conversation mode.
##
## Transitions from scripted dialogue to open AI conversation.
## Has one input and one output (for when returning from free mode).


func _configure_slots() -> void:
	clear_all_slots()
	# One input, one output (continues after return)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


func _create_content_ui() -> void:
	_add_hint_label("Enter free conversation")
	var free_node := node_data as JumpToFreeNodeData
	var context_prompt: String = free_node.context_prompt if free_node else ""
	if not context_prompt.is_empty():
		_add_separator()
		_add_text_preview(context_prompt, 2)

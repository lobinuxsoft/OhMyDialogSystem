@tool
class_name StaticResponseNode
extends BaseDialogueNode
## Visual node for pre-written static dialogue text.
##
## Displays fixed text that doesn't use AI generation.
## Useful for scripted dialogue segments.


func _configure_slots() -> void:
	clear_all_slots()
	# One input, one output
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


func _create_content_ui() -> void:
	var static_node := node_data as StaticResponseNodeData
	var speaker: String = static_node.speaker if static_node else ""
	var text: String = static_node.text if static_node else ""

	_add_info("Speaker", speaker)
	_add_separator()
	_add_text_preview(text, 4)

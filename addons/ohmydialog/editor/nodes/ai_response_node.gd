@tool
class_name AIResponseNode
extends BaseDialogueNode
## Visual node for AI-generated dialogue responses.
##
## This node uses the LLM to generate dynamic responses based on
## the character identity, world context, and conversation history.


func _configure_slots() -> void:
	clear_all_slots()
	# One input, one output
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


func _create_content_ui() -> void:
	var prompt_hint: String = node_data.data.get("prompt_hint", "")

	_add_hint_label("AI generates response")
	if not prompt_hint.is_empty():
		_add_separator()
		_add_text_preview(prompt_hint, 2)

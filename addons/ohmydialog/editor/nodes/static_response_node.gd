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
	var text: String = node_data.data.get("text", "")
	if text.is_empty():
		_add_hint_label("(No text defined)")
	else:
		# Truncate long text for display
		var display_text := text.substr(0, 50)
		if text.length() > 50:
			display_text += "..."
		var label := _add_label(display_text)
		label.custom_minimum_size.x = 180

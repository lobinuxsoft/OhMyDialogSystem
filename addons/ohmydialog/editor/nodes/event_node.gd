@tool
class_name EventNode
extends BaseDialogueNode
## Visual node for emitting game events/signals.
##
## Triggers an event with optional data, then continues to the next node.


func _configure_slots() -> void:
	clear_all_slots()
	# One input, one output
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


func _create_content_ui() -> void:
	var event_name: String = node_data.data.get("event_name", "")
	_add_info("Event", event_name)

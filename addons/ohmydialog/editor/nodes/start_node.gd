@tool
class_name StartNode
extends BaseDialogueNode
## Visual node representing the entry point of a dialogue graph.
##
## The START node has no inputs and one output. There should only
## be one START node per graph.


func _configure_slots() -> void:
	clear_all_slots()
	# No input, one output
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)


func _create_content_ui() -> void:
	_add_hint_label("Entry Point")

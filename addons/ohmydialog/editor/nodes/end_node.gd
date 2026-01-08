@tool
class_name EndNode
extends BaseDialogueNode
## Visual node representing the termination point of a dialogue.
##
## The END node has one input and no outputs. Multiple END nodes
## can exist in a graph for different endings.
##
## When reached, the dialogue ends and any loaded AI model is automatically
## unloaded to free memory resources.


func _configure_slots() -> void:
	clear_all_slots()
	# One input, no output
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)


func _create_content_ui() -> void:
	_add_hint_label("Dialogue ends here")
	_add_hint_label("(AI model will be unloaded)")

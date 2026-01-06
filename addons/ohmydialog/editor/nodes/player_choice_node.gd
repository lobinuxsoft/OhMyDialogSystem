@tool
class_name PlayerChoiceNode
extends BaseDialogueNode
## Visual node for presenting choices to the player.
##
## Has one input and multiple outputs - one per choice option.
## Each output connects to the next node for that choice.


func _configure_slots() -> void:
	clear_all_slots()

	var choices: Array = node_data.data.get("choices", [])
	var output_count := maxi(1, choices.size())

	# First slot has input, all slots have output
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	for i in range(1, output_count):
		set_slot(i, false, 0, Color.WHITE, true, 0, Color.WHITE)


func _create_content_ui() -> void:
	var choices: Array = node_data.data.get("choices", [])

	if choices.is_empty():
		_add_hint_label("(No choices defined)")
	else:
		for i in choices.size():
			var choice: Dictionary = choices[i]
			var text: String = choice.get("text", "Choice %d" % (i + 1))
			_add_label("%d. %s" % [i + 1, text])

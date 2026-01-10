@tool
class_name PlayerChoiceNodeExecutor
extends BaseNodeExecutor
## Executor for PLAYER_CHOICE nodes.
##
## Presents choices to the player and waits for selection.
## Returns the selected choice index as output_slot.


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var choice_node := node_data as PlayerChoiceNodeData
	var choices: PackedStringArray = choice_node.choices if choice_node else PackedStringArray()

	if choices.is_empty():
		return error("PlayerChoiceExecutor: No choices defined")

	# Build available choices array for UI
	var available_choices: Array[Dictionary] = []

	for i in choices.size():
		available_choices.append({
			"index": i,
			"text": choices[i]
		})

	# Return choices for UI to display
	# The GraphRunner will wait for player selection
	return {
		RESULT_NEXT_NODE: "",
		RESULT_CHOICES: available_choices,
		"requires_input": true  # Signal that player input is needed
	}

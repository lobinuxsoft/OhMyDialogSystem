@tool
class_name PlayerChoiceNodeExecutor
extends BaseNodeExecutor
## Executor for PLAYER_CHOICE nodes.
##
## Presents choices to the player and waits for selection.
## Returns the selected choice index as output_slot.


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var choices: Array = node_data.data.get("choices", [])

	if choices.is_empty():
		return error("PlayerChoiceExecutor: No choices defined")

	# Filter choices by conditions if specified
	var available_choices: Array[Dictionary] = []
	var choice_indices: Array[int] = []

	for i in choices.size():
		var choice: Dictionary = choices[i] if choices[i] is Dictionary else {"text": str(choices[i])}
		var condition: String = choice.get("condition", "")

		# Check if condition is met (empty condition = always available)
		if condition.is_empty() or _evaluate_condition(condition, context):
			available_choices.append({
				"index": i,
				"text": choice.get("text", "Choice %d" % (i + 1)),
				"metadata": choice.get("metadata", {})
			})
			choice_indices.append(i)

	if available_choices.is_empty():
		return error("PlayerChoiceExecutor: No available choices (all conditions failed)")

	# Return choices for UI to display
	# The GraphRunner will wait for player selection
	return {
		RESULT_NEXT_NODE: "",
		RESULT_CHOICES: available_choices,
		"choice_indices": choice_indices,
		"requires_input": true  # Signal that player input is needed
	}


## Evaluates a condition expression against the context.
func _evaluate_condition(condition: String, context: Object) -> bool:
	if not context or not context.has_method("evaluate_condition"):
		# If no evaluator, assume true
		return true

	return context.evaluate_condition(condition)

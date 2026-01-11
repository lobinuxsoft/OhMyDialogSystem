@tool
class_name EventNodeExecutor
extends BaseNodeExecutor
## Executor for EVENT nodes.
##
## Emits a custom event that the game can react to.
## Continues to next node after event is processed.


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var event_node := node_data as EventNodeData
	var event_name: String = event_node.event_name if event_node else ""
	var event_data: Dictionary = event_node.event_data if event_node else {}
	var wait_for_completion: bool = false  # Not currently in EventNodeData

	if event_name.is_empty():
		return error("EventExecutor: No event name specified")

	# Process event data - substitute variables if needed
	var processed_data := _process_event_data(event_data, context)

	return {
		RESULT_NEXT_NODE: "",
		RESULT_OUTPUT_SLOT: 0,
		RESULT_EVENT: event_name,
		"event_data": processed_data,
		"wait_for_completion": wait_for_completion
	}


## Processes event data, substituting variable references.
func _process_event_data(data: Dictionary, context: Object) -> Dictionary:
	var result := {}

	for key in data:
		var value: Variant = data[key]

		# Check for variable reference syntax: $variable_name
		if value is String and (value as String).begins_with("$"):
			var var_name: String = (value as String).substr(1)
			if context and context.has_method("get_variable"):
				result[key] = context.get_variable(var_name)
			else:
				result[key] = value
		else:
			result[key] = value

	return result

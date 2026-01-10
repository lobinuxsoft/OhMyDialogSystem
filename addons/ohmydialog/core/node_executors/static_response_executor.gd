@tool
class_name StaticResponseNodeExecutor
extends BaseNodeExecutor
## Executor for STATIC_RESPONSE nodes.
##
## Returns pre-written dialogue text without AI generation.


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var static_node := node_data as StaticResponseNodeData
	var text: String = static_node.text if static_node else ""
	var speaker: String = static_node.speaker if static_node else ""

	# Support for simple variable substitution {var_name}
	if context and context.has_method("get_variable"):
		text = _substitute_variables(text, context)

	return {
		RESULT_NEXT_NODE: "",
		RESULT_OUTPUT_SLOT: 0,
		RESULT_TEXT: text,
		"speaker": speaker,
		RESULT_WAIT_CONFIRM: true  # Wait for user to click Continue
	}


## Substitutes {variable} placeholders with actual values from context.
func _substitute_variables(text: String, context: Object) -> String:
	var result := text
	var regex := RegEx.new()
	regex.compile("\\{(\\w+)\\}")

	for match_result in regex.search_all(text):
		var var_name: String = match_result.get_string(1)
		var value: Variant = context.get_variable(var_name) if context.has_method("get_variable") else null
		if value != null:
			result = result.replace("{%s}" % var_name, str(value))

	return result

@tool
class_name SetVariableNodeExecutor
extends BaseNodeExecutor
## Executor for SET_VARIABLE nodes.
##
## Sets a variable in the dialogue context and continues.


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var variable_name: String = node_data.data.get("variable", "")
	var value: Variant = node_data.data.get("value", null)
	var operation: String = node_data.data.get("operation", "set")

	if variable_name.is_empty():
		return error("SetVariableExecutor: No variable name specified")

	# Calculate final value based on operation
	var final_value: Variant = _calculate_value(variable_name, value, operation, context)

	# Set the variable in context
	if context and context.has_method("set_variable"):
		context.set_variable(variable_name, final_value)

	return {
		RESULT_NEXT_NODE: "",
		RESULT_OUTPUT_SLOT: 0,
		RESULT_VARIABLE: variable_name,
		RESULT_VALUE: final_value,
		"operation": operation
	}


## Calculates the final value based on operation type.
func _calculate_value(variable: String, value: Variant, operation: String, context: Object) -> Variant:
	var current_value: Variant = null
	if context and context.has_method("get_variable"):
		current_value = context.get_variable(variable)

	match operation:
		"set":
			return value

		"add", "+":
			if current_value == null:
				return value
			if current_value is int and value is int:
				return current_value + value
			if current_value is float or value is float:
				return float(current_value) + float(value)
			if current_value is String:
				return current_value + str(value)
			if current_value is Array:
				var arr: Array = current_value.duplicate()
				arr.append(value)
				return arr

		"subtract", "-":
			if current_value == null:
				return -value if value is int or value is float else value
			if current_value is int and value is int:
				return current_value - value
			if current_value is float or value is float:
				return float(current_value) - float(value)

		"multiply", "*":
			if current_value == null:
				return 0
			if current_value is int and value is int:
				return current_value * value
			if current_value is float or value is float:
				return float(current_value) * float(value)

		"divide", "/":
			if current_value == null or value == 0:
				return 0
			return float(current_value) / float(value)

		"toggle":
			if current_value is bool:
				return not current_value
			return not bool(current_value)

		"append":
			if current_value is Array:
				var arr: Array = current_value.duplicate()
				arr.append(value)
				return arr
			elif current_value is String:
				return current_value + str(value)

		"remove":
			if current_value is Array:
				var arr: Array = current_value.duplicate()
				arr.erase(value)
				return arr

	return value

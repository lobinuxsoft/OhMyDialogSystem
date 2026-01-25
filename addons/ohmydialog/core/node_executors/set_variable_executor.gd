@tool
class_name SetVariableNodeExecutor
extends BaseNodeExecutor
## Executor for SET_VARIABLE nodes.
##
## Sets a variable in the dialogue context and continues.


## Operation names matching DialogueNodeData.VariableOperation enum order.
const OPERATION_NAMES := ["set", "add", "subtract", "multiply", "divide", "toggle"]

## Scope names matching SetVariableNodeData.VariableScope enum order.
const SCOPE_NAMES := ["local", "session", "global"]


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var setvar_node := node_data as SetVariableNodeData
	var variable_name: String = setvar_node.variable if setvar_node else ""
	var value: Variant = setvar_node.value if setvar_node else null
	var operation: String = _normalize_operation(setvar_node.operation if setvar_node else 0)
	var scope: String = _scope_to_string(setvar_node.scope if setvar_node else 0)

	if variable_name.is_empty():
		return error("SetVariableExecutor: No variable name specified")

	# Calculate final value based on operation
	var final_value: Variant = _calculate_value(variable_name, value, operation, context)

	# Set the variable in context with scope
	if context and context.has_method("set_variable"):
		context.set_variable(variable_name, final_value, scope)

	return {
		RESULT_NEXT_NODE: "",
		RESULT_OUTPUT_SLOT: 0,
		RESULT_VARIABLE: variable_name,
		RESULT_VALUE: final_value,
		"operation": operation,
		"scope": scope
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


## Normalizes operation from int (enum) or String to lowercase String.
func _normalize_operation(op: Variant) -> String:
	if op is int:
		if op >= 0 and op < OPERATION_NAMES.size():
			return OPERATION_NAMES[op]
		return "set"
	elif op is String:
		return op.to_lower()
	return "set"


## Converts scope enum to string.
func _scope_to_string(scope: Variant) -> String:
	if scope is int:
		if scope >= 0 and scope < SCOPE_NAMES.size():
			return SCOPE_NAMES[scope]
		return "local"
	elif scope is String:
		return scope.to_lower()
	return "local"

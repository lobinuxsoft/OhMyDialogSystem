@tool
class_name ConditionNodeExecutor
extends BaseNodeExecutor
## Executor for CONDITION nodes.
##
## Evaluates a condition and returns output_slot 0 (true) or 1 (false).


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var condition: String = node_data.data.get("condition", "")
	var variable_name: String = node_data.data.get("variable", "")
	var operator: String = node_data.data.get("operator", "==")
	var compare_value: Variant = node_data.data.get("value", null)

	var result: bool = false

	# Method 1: Expression-based condition
	if not condition.is_empty():
		result = _evaluate_expression(condition, context)

	# Method 2: Variable comparison
	elif not variable_name.is_empty():
		result = _evaluate_comparison(variable_name, operator, compare_value, context)

	# Output slot 0 = TRUE path, slot 1 = FALSE path
	var output_slot := 0 if result else 1

	return {
		RESULT_NEXT_NODE: "",
		RESULT_OUTPUT_SLOT: output_slot,
		"condition_result": result
	}


## Evaluates an expression string.
func _evaluate_expression(expression: String, context: Object) -> bool:
	if context and context.has_method("evaluate_condition"):
		return context.evaluate_condition(expression)

	# Simple built-in evaluation for basic cases
	# This is a fallback - proper evaluation should be in context
	return false


## Evaluates a variable comparison.
func _evaluate_comparison(variable: String, operator: String, compare_value: Variant, context: Object) -> bool:
	var current_value: Variant = null

	if context and context.has_method("get_variable"):
		current_value = context.get_variable(variable)

	if current_value == null:
		return false

	match operator:
		"==", "eq":
			return current_value == compare_value
		"!=", "ne":
			return current_value != compare_value
		">", "gt":
			return current_value > compare_value
		"<", "lt":
			return current_value < compare_value
		">=", "gte":
			return current_value >= compare_value
		"<=", "lte":
			return current_value <= compare_value
		"contains":
			if current_value is String and compare_value is String:
				return current_value.contains(compare_value)
			elif current_value is Array:
				return compare_value in current_value
		"is_empty":
			if current_value is String:
				return current_value.is_empty()
			elif current_value is Array:
				return current_value.is_empty()
		"is_not_empty":
			if current_value is String:
				return not current_value.is_empty()
			elif current_value is Array:
				return not current_value.is_empty()

	return false

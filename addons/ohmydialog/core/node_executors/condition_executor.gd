@tool
class_name ConditionNodeExecutor
extends BaseNodeExecutor
## Executor for CONDITION nodes.
##
## Evaluates a condition and returns output_slot 0 (true) or 1 (false).


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var cond_node := node_data as ConditionNodeData
	var variable_name: String = cond_node.variable if cond_node else ""
	var operator_raw: Variant = cond_node.operator if cond_node else DialogueNodeData.ComparisonOperator.EQUAL
	var compare_value: Variant = cond_node.value if cond_node else null

	var result: bool = false

	# Evaluate variable comparison
	if not variable_name.is_empty():
		var operator := _normalize_operator(operator_raw)
		result = _evaluate_comparison(variable_name, operator, compare_value, context)

	# Output slot 0 = TRUE path, slot 1 = FALSE path
	var output_slot := 0 if result else 1

	return {
		RESULT_NEXT_NODE: "",
		RESULT_OUTPUT_SLOT: output_slot,
		"condition_result": result
	}


## Normalizes operator to enum (handles both int and String).
func _normalize_operator(operator_raw: Variant) -> DialogueNodeData.ComparisonOperator:
	if operator_raw is int:
		return operator_raw as DialogueNodeData.ComparisonOperator

	# String to enum mapping
	var str_op := str(operator_raw).to_lower().strip_edges()
	match str_op:
		"==", "eq", "equal":
			return DialogueNodeData.ComparisonOperator.EQUAL
		"!=", "ne", "not_equal":
			return DialogueNodeData.ComparisonOperator.NOT_EQUAL
		">", "gt", "greater":
			return DialogueNodeData.ComparisonOperator.GREATER
		">=", "gte", "greater_equal":
			return DialogueNodeData.ComparisonOperator.GREATER_EQUAL
		"<", "lt", "less":
			return DialogueNodeData.ComparisonOperator.LESS
		"<=", "lte", "less_equal":
			return DialogueNodeData.ComparisonOperator.LESS_EQUAL
		"contains":
			return DialogueNodeData.ComparisonOperator.CONTAINS
		"is_empty", "empty":
			return DialogueNodeData.ComparisonOperator.IS_EMPTY
		"is_true", "true":
			return DialogueNodeData.ComparisonOperator.IS_TRUE
		"is_false", "false":
			return DialogueNodeData.ComparisonOperator.IS_FALSE

	return DialogueNodeData.ComparisonOperator.EQUAL


## Evaluates a variable comparison using the enum operator.
func _evaluate_comparison(
	variable: String,
	operator: DialogueNodeData.ComparisonOperator,
	compare_value: Variant,
	context: Object
) -> bool:
	var current_value: Variant = null

	if context and context.has_method("get_variable"):
		current_value = context.get_variable(variable)

	if current_value == null:
		return false

	# Convert compare_value to match current_value's type for numeric comparisons
	compare_value = _convert_to_type(compare_value, typeof(current_value))

	match operator:
		DialogueNodeData.ComparisonOperator.EQUAL:
			return current_value == compare_value
		DialogueNodeData.ComparisonOperator.NOT_EQUAL:
			return current_value != compare_value
		DialogueNodeData.ComparisonOperator.GREATER:
			return current_value > compare_value
		DialogueNodeData.ComparisonOperator.GREATER_EQUAL:
			return current_value >= compare_value
		DialogueNodeData.ComparisonOperator.LESS:
			return current_value < compare_value
		DialogueNodeData.ComparisonOperator.LESS_EQUAL:
			return current_value <= compare_value
		DialogueNodeData.ComparisonOperator.CONTAINS:
			if current_value is String and compare_value is String:
				return current_value.contains(compare_value)
			elif current_value is Array:
				return compare_value in current_value
		DialogueNodeData.ComparisonOperator.IS_EMPTY:
			if current_value is String:
				return current_value.is_empty()
			elif current_value is Array:
				return current_value.is_empty()
			return not bool(current_value)
		DialogueNodeData.ComparisonOperator.IS_TRUE:
			return bool(current_value) == true
		DialogueNodeData.ComparisonOperator.IS_FALSE:
			return bool(current_value) == false

	return false


## Converts a value to the specified Variant type.
func _convert_to_type(value: Variant, target_type: int) -> Variant:
	if typeof(value) == target_type:
		return value

	var str_value := str(value)

	match target_type:
		TYPE_INT:
			if str_value.is_valid_int():
				return str_value.to_int()
			elif str_value.is_valid_float():
				return int(str_value.to_float())
		TYPE_FLOAT:
			if str_value.is_valid_float():
				return str_value.to_float()
			elif str_value.is_valid_int():
				return float(str_value.to_int())
		TYPE_BOOL:
			return str_value.to_lower() in ["true", "1", "yes", "on"]
		TYPE_STRING:
			return str_value

	return value

@tool
class_name ConditionNode
extends BaseDialogueNode
## Visual node for branching based on conditions.
##
## Has one input and two outputs: TRUE and FALSE branches.
## Evaluates a variable or expression to determine the path.


func _configure_slots() -> void:
	clear_all_slots()
	# One input, two outputs (TRUE = slot 0, FALSE = slot 1)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.RED)


func _create_content_ui() -> void:
	var variable: String = node_data.data.get("variable", "")
	var op: int = node_data.data.get("operator", DialogueNodeData.ComparisonOperator.EQUAL)
	var value: Variant = node_data.data.get("value", "")

	# Build condition string
	var op_str := _get_operator_string(op)
	var condition_text := "if %s %s %s" % [variable, op_str, str(value)]

	if variable.is_empty():
		condition_text = "if ??? == ???"

	_add_label(condition_text)

	# TRUE/FALSE labels
	_add_label("✓ TRUE", Color.GREEN)
	_add_label("✗ FALSE", Color.RED)


func _get_operator_string(op: int) -> String:
	match op:
		DialogueNodeData.ComparisonOperator.EQUAL: return "=="
		DialogueNodeData.ComparisonOperator.NOT_EQUAL: return "!="
		DialogueNodeData.ComparisonOperator.GREATER: return ">"
		DialogueNodeData.ComparisonOperator.LESS: return "<"
		DialogueNodeData.ComparisonOperator.GREATER_EQUAL: return ">="
		DialogueNodeData.ComparisonOperator.LESS_EQUAL: return "<="
		DialogueNodeData.ComparisonOperator.CONTAINS: return "contains"
		DialogueNodeData.ComparisonOperator.IS_EMPTY: return "is_empty"
		DialogueNodeData.ComparisonOperator.IS_TRUE: return "is_true"
		DialogueNodeData.ComparisonOperator.IS_FALSE: return "is_false"
		_: return "?"

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
	var op_raw: Variant = node_data.data.get("operator", DialogueNodeData.ComparisonOperator.EQUAL)
	var value: Variant = node_data.data.get("value", "")

	# Handle operator as either enum int or string
	var op_str: String
	if op_raw is String:
		op_str = op_raw
	else:
		op_str = _get_operator_string(int(op_raw))

	var condition_text := "%s %s %s" % [variable, op_str, str(value)]

	if variable.is_empty():
		# Check for expression-based condition
		var expression: String = node_data.data.get("condition", "")
		if not expression.is_empty():
			condition_text = expression
		else:
			condition_text = "??? == ???"

	_add_label(condition_text, Color(0.9, 0.9, 0.7))

	# TRUE/FALSE output labels
	var true_label := Label.new()
	true_label.text = "TRUE →"
	true_label.add_theme_color_override("font_color", Color.GREEN)
	true_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_content_container.add_child(true_label)

	var false_label := Label.new()
	false_label.text = "FALSE →"
	false_label.add_theme_color_override("font_color", Color.RED)
	false_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_content_container.add_child(false_label)


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

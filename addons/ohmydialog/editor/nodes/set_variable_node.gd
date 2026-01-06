@tool
class_name SetVariableNode
extends BaseDialogueNode
## Visual node for modifying dialogue variables.
##
## Can set, add, subtract, multiply, divide, or toggle a variable.


func _configure_slots() -> void:
	clear_all_slots()
	# One input, one output
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


func _create_content_ui() -> void:
	var variable: String = node_data.data.get("variable", "")
	var op_raw: Variant = node_data.data.get("operation", DialogueNodeData.VariableOperation.SET)
	var value: Variant = node_data.data.get("value", "")

	# Handle operation as either enum int or string
	var op_str: String
	if op_raw is String:
		op_str = _string_to_op_symbol(op_raw)
	else:
		op_str = _get_operation_string(int(op_raw))

	if variable.is_empty():
		_add_hint_label("??? = ???")
	else:
		var value_str := str(value)
		if value is bool:
			value_str = "true" if value else "false"
		_add_label("%s %s %s" % [variable, op_str, value_str], Color(0.7, 0.9, 0.9))


func _string_to_op_symbol(op: String) -> String:
	match op.to_lower():
		"set": return "="
		"add", "+": return "+="
		"subtract", "-": return "-="
		"multiply", "*": return "*="
		"divide", "/": return "/="
		"toggle": return "= !"
		_: return "="


func _get_operation_string(op: int) -> String:
	match op:
		DialogueNodeData.VariableOperation.SET: return "="
		DialogueNodeData.VariableOperation.ADD: return "+="
		DialogueNodeData.VariableOperation.SUBTRACT: return "-="
		DialogueNodeData.VariableOperation.MULTIPLY: return "*="
		DialogueNodeData.VariableOperation.DIVIDE: return "/="
		DialogueNodeData.VariableOperation.TOGGLE: return "= toggle"
		_: return "?"

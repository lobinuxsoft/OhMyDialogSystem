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
	var op: int = node_data.data.get("operation", DialogueNodeData.VariableOperation.SET)
	var value: Variant = node_data.data.get("value", "")

	var op_str := _get_operation_string(op)

	if variable.is_empty():
		_add_hint_label("??? = ???")
	else:
		_add_label("%s %s %s" % [variable, op_str, str(value)])


func _get_operation_string(op: int) -> String:
	match op:
		DialogueNodeData.VariableOperation.SET: return "="
		DialogueNodeData.VariableOperation.ADD: return "+="
		DialogueNodeData.VariableOperation.SUBTRACT: return "-="
		DialogueNodeData.VariableOperation.MULTIPLY: return "*="
		DialogueNodeData.VariableOperation.DIVIDE: return "/="
		DialogueNodeData.VariableOperation.TOGGLE: return "= toggle"
		_: return "?"

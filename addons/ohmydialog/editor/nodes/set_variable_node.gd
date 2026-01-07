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
	var operation_int: int = node_data.data.get("operation", 0) if node_data.data.get("operation", 0) is int else 0
	var value: Variant = node_data.data.get("value", "")

	_add_info("Variable", variable)
	_add_info("Op", BaseDialogueNode.operation_to_string(operation_int), Color("#06b6d4"))
	_add_info("Value", str(value))

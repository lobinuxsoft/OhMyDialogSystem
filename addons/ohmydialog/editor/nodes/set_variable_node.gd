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
	var setvar_node := node_data as SetVariableNodeData
	var variable: String = setvar_node.variable if setvar_node else ""
	var operation_int: int = setvar_node.operation if setvar_node else 0
	var value: Variant = setvar_node.value if setvar_node else ""

	_add_info("Variable", variable)
	_add_info("Op", BaseDialogueNode.operation_to_string(operation_int), Color("#06b6d4"))
	_add_info("Value", str(value))

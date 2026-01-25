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
	var scope_val: int = setvar_node.scope if setvar_node else 0

	_add_info("Variable", variable)
	_add_info("Op", BaseDialogueNode.operation_to_string(operation_int), Color("#06b6d4"))
	_add_info("Value", str(value))

	var scope_name := SetVariableNodeData.VariableScope.keys()[scope_val]
	var scope_color := _get_scope_color(scope_val)
	_add_info("Scope", scope_name, scope_color)


func _get_scope_color(scope: int) -> Color:
	match scope:
		SetVariableNodeData.VariableScope.GLOBAL:
			return Color("#f59e0b")  # Orange (ai-orange)
		SetVariableNodeData.VariableScope.SESSION:
			return Color("#06b6d4")  # Cyan (ai-cyan)
		_:
			return Color("#22c55e")  # Green (ai-green) for LOCAL

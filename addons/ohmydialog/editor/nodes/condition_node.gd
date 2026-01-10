@tool
class_name ConditionNode
extends BaseDialogueNode
## Visual node for branching based on conditions.
##
## Has one input and two outputs: TRUE and FALSE branches.


func _configure_slots() -> void:
	# Will be configured in _create_content_ui after children are added
	pass


func _create_content_ui() -> void:
	var cond_node := node_data as ConditionNodeData
	var variable: String = cond_node.variable if cond_node else ""
	var operator_raw: Variant = cond_node.operator if cond_node else 0
	var operator_str: String = BaseDialogueNode.operator_to_string(operator_raw) if operator_raw is int else str(operator_raw)
	var value: Variant = cond_node.value if cond_node else ""

	# Show condition summary
	var condition_str := "%s %s %s" % [variable, operator_str, str(value)]
	if variable.is_empty():
		condition_str = "(no condition)"
	_add_label(condition_str, Color("#f97316"))

	# TRUE output label
	_add_output_label("TRUE >", Color.GREEN)

	# FALSE row as direct child for slot 1
	var false_row := HBoxContainer.new()
	false_row.custom_minimum_size = Vector2(180, 20)
	var false_label := Label.new()
	false_label.text = "FALSE >"
	false_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	false_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	false_label.add_theme_color_override("font_color", Color.RED)
	false_row.add_child(false_label)
	add_child(false_row)

	# Configure slots AFTER adding all children
	# Slot 0: _content_container - input left, TRUE output right
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	# Slot 1: false_row - no input, FALSE output right
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.RED)

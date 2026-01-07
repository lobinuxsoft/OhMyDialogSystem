@tool
class_name ConditionEditor
extends BaseNodeEditor
## Inspector editor for CONDITION nodes.
##
## Shows variable, operator, value, or raw expression fields.


const OPERATOR_NAMES: Array[String] = [
	"== (Equal)",
	"!= (Not Equal)",
	"> (Greater)",
	">= (Greater/Equal)",
	"< (Less)",
	"<= (Less/Equal)",
	"Contains",
	"Is Empty",
	"Is True",
	"Is False"
]


func _setup_ui() -> void:
	_add_header("Condition Node")
	_add_separator()

	# Simple condition mode
	_add_header("Simple Mode")
	_add_variable_selector("Variable", "variable")
	_add_operator_selector()
	_add_line_edit("Value", "value", "compare value")

	_add_separator()

	# Expression mode
	_add_header("Expression Mode")
	_add_text_edit("Expression", "expression", 60)

	var note := Label.new()
	note.text = "Use either simple mode OR expression, not both."
	note.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	note.add_theme_font_size_override("font_size", 11)
	add_child(note)


func _add_operator_selector() -> OptionButton:
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = "Operator:"
	label.custom_minimum_size.x = 100
	hbox.add_child(label)

	var option := OptionButton.new()
	for name in OPERATOR_NAMES:
		option.add_item(name)

	# Get current value (it's an enum int)
	var current_value: Variant = _node_data.data.get("operator", 0)
	if current_value is int:
		option.select(mini(current_value, OPERATOR_NAMES.size() - 1))

	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.item_selected.connect(func(index: int):
		_node_data.data["operator"] = index  # Store as enum int
		_emit_changed()
	)
	hbox.add_child(option)

	add_child(hbox)
	return option

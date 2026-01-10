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


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super(node_data, graph)
	ACCENT_COLOR = Color("#f97316")  # Condition node orange


func _setup_ui() -> void:
	_create_main_header("Condition Node", "⚖")

	# Simple condition mode
	var simple_section := _create_section("Simple Mode")
	_add_variable_selector("Variable", "variable", simple_section)
	_add_operator_selector(simple_section)
	_add_line_edit("Value", "value", "compare value", simple_section)

	# Expression mode
	var expr_section := _create_section("Expression Mode")
	_add_text_edit("Expression", "expression", 60, expr_section)

	var note := Label.new()
	note.text = "Use either simple mode OR expression, not both."
	note.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	note.add_theme_font_size_override("font_size", 11)
	expr_section.add_child(note)


func _add_operator_selector(parent: Control = null) -> OptionButton:
	var target := _get_target(parent)
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = "Operator:"
	label.custom_minimum_size.x = 100
	label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
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

	target.add_child(hbox)
	return option

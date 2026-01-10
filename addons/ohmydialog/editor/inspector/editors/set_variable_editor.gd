@tool
class_name SetVariableEditor
extends BaseNodeEditor
## Inspector editor for SET_VARIABLE nodes.
##
## Shows variable name, operation, and value fields.


const OPERATION_NAMES: Array[String] = ["Set", "Add", "Subtract", "Multiply", "Divide", "Toggle"]


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super(node_data, graph)
	ACCENT_COLOR = Color("#06b6d4")  # Variable node cyan


func _setup_ui() -> void:
	_create_main_header("Set Variable", "📝")

	var var_section := _create_section("Variable Configuration")
	_add_variable_selector("Variable", "variable", var_section)
	_add_operation_selector(var_section)
	_add_line_edit("Value", "value", "new value", var_section)


func _add_operation_selector(parent: Control = null) -> OptionButton:
	var target := _get_target(parent)
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = "Operation:"
	label.custom_minimum_size.x = 100
	label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	hbox.add_child(label)

	var option := OptionButton.new()
	for name in OPERATION_NAMES:
		option.add_item(name)

	# Get current value (it's an enum int)
	var current_value: Variant = _node_data.data.get("operation", 0)
	if current_value is int:
		option.select(mini(current_value, OPERATION_NAMES.size() - 1))

	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.item_selected.connect(func(index: int):
		_node_data.data["operation"] = index  # Store as enum int
		_emit_changed()
	)
	hbox.add_child(option)

	target.add_child(hbox)
	return option

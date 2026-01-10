@tool
class_name SetVariableEditor
extends BaseNodeEditor
## Wiki-style info panel for Set Variable nodes.
##
## Shows variable operation summary.


const OPERATION_SYMBOLS: Array[String] = ["=", "+=", "-=", "*=", "/=", "toggle"]

var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#06b6d4")
	ICON = "📝"
	TITLE = "SET VARIABLE"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var var_node := _node_data as SetVariableNodeData
	if not var_node:
		return

	var text := ""

	# Variable name
	if var_node.variable.is_empty():
		text += "[color=#ef4444]✗ Sin variable definida[/color]"
	else:
		# Show readable operation
		var op_idx: int = var_node.operation
		var op_symbol: String = OPERATION_SYMBOLS[op_idx] if op_idx < OPERATION_SYMBOLS.size() else "?"

		text += "[b]Operación:[/b]\n"
		if op_symbol == "toggle":
			text += "[color=#06b6d4]%s = !%s[/color]" % [var_node.variable, var_node.variable]
		else:
			var display_value: String = str(var_node.value) if var_node.value != null else "null"
			text += "[color=#06b6d4]%s %s %s[/color]" % [var_node.variable, op_symbol, display_value]

	_info_label.text = text

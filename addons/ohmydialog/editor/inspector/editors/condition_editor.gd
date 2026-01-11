@tool
class_name ConditionEditor
extends BaseNodeEditor
## Wiki-style info panel for Condition nodes.
##
## Shows condition summary and validation.


const OPERATOR_SYMBOLS: Array[String] = [
	"==", "!=", ">", ">=", "<", "<=",
	"contains", "is_empty", "is_true", "is_false"
]

var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#f97316")
	ICON = "⚖"
	TITLE = "CONDITION"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var cond_node := _node_data as ConditionNodeData
	if not cond_node:
		return

	var text := ""

	if cond_node.variable.is_empty():
		text += "[color=#ef4444]✗ Sin variable definida[/color]"
	else:
		# Show readable condition
		var op_idx: int = cond_node.operator
		var op_symbol: String = OPERATOR_SYMBOLS[op_idx] if op_idx < OPERATOR_SYMBOLS.size() else "?"
		text += "[b]Condición:[/b]\n"
		var display_value: String = str(cond_node.value) if cond_node.value != null else "null"
		text += "[color=#06b6d4]%s %s %s[/color]" % [cond_node.variable, op_symbol, display_value]

	# Branches info
	text += "\n\n[color=#484f58]Salida 0: TRUE\nSalida 1: FALSE[/color]"

	_info_label.text = text

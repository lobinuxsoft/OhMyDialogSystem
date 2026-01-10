@tool
class_name JumpToFreeEditor
extends BaseNodeEditor
## Wiki-style info panel for Jump to Free Mode nodes.
##
## Shows free mode configuration summary.


var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#8b5cf6")
	ICON = "🔄"
	TITLE = "FREE MODE"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var free_node := _node_data as JumpToFreeNodeData
	if not free_node:
		return

	var text := ""

	# Context prompt
	if free_node.context_prompt.is_empty():
		text += "[color=#f97316]⚠ Sin contexto adicional[/color]"
	else:
		var prompt_len := free_node.context_prompt.length()
		text += "[color=#10b981]✓ Contexto: %d caracteres[/color]" % prompt_len

	# Return keywords
	var keywords: PackedStringArray = free_node.return_keywords
	if keywords.size() > 0:
		text += "\n[b]Keywords retorno:[/b] %d" % keywords.size()
	else:
		text += "\n[color=#484f58]Sin keywords de retorno[/color]"

	# Return condition
	if not free_node.return_condition.is_empty():
		text += "\n[b]Condición:[/b] %s" % free_node.return_condition

	# Max exchanges
	if free_node.max_exchanges > 0:
		text += "\n[color=#484f58]Límite: %d intercambios[/color]" % free_node.max_exchanges
	else:
		text += "\n[color=#484f58]Sin límite de intercambios[/color]"

	_info_label.text = text

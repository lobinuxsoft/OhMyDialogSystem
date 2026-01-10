@tool
class_name PlayerChoiceEditor
extends BaseNodeEditor
## Wiki-style info panel for Player Choice nodes.
##
## Shows choice count, validation, and conditions summary.


var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#eab308")
	ICON = "❓"
	TITLE = "PLAYER CHOICE"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var choice_node := _node_data as PlayerChoiceNodeData
	if not choice_node:
		return

	var text := ""
	var choices: PackedStringArray = choice_node.choices

	# Choice count
	var choice_count := choices.size()
	if choice_count == 0:
		text += "[color=#ef4444]✗ Sin opciones definidas[/color]"
	else:
		text += "[b]%d opción(es)[/b]" % choice_count

		# Check for empty choices
		var empty_count := 0
		for choice in choices:
			if choice.is_empty():
				empty_count += 1

		if empty_count > 0:
			text += "\n[color=#f97316]⚠ %d opción(es) sin texto[/color]" % empty_count
		else:
			text += "\n[color=#10b981]✓ Todas las opciones tienen texto[/color]"

	# Output ports
	text += "\n[color=#484f58]Salidas: %d puertos[/color]" % choice_node.output_count

	_info_label.text = text
